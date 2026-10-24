import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/privacy/crash_reporter.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Noop implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

class FakeCrashReporter implements CrashReporter {
  FakeCrashReporter({this.available = true});
  @override
  final bool available;
  final enabledCalls = <bool>[];
  final recorded = <Object>[];
  @override
  Future<void> setEnabled(bool enabled) async => enabledCalls.add(enabled);
  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) => recorded.add(error);
}

Future<ProviderContainer> _open(WidgetTester tester, CrashReporter reporter, {Map<String, Object> prefsValues = const {}, String route = '/'}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_Noop()),
      crashReporterProvider.overrideWithValue(reporter),
      nowProvider.overrideWithValue(DateTime(2026, 10, 23, 10, 42, 18)),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
    ],
    child: const NoorApp(),
  ));
  await tester.pumpAndSettle();
  if (route != '/') {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
    await tester.pumpAndSettle();
  }
  return ProviderScope.containerOf(tester.element(find.byType(NoorApp)));
}

void main() {
  group('crash consent', () {
    test('starts undecided, persists the choice and tells the reporter', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reporter = FakeCrashReporter();
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), crashReporterProvider.overrideWithValue(reporter)]);
      addTearDown(c.dispose);

      expect(c.read(crashConsentProvider), isNull);
      await c.read(crashConsentProvider.notifier).set(true);
      expect(c.read(crashConsentProvider), isTrue);
      expect(prefs.getBool(CrashConsent.prefsKey), isTrue);
      await c.read(crashConsentProvider.notifier).set(false);
      expect(prefs.getBool(CrashConsent.prefsKey), isFalse);
      expect(reporter.enabledCalls, [true, false]);
    });

    test('a saved choice is restored on the next launch', () async {
      SharedPreferences.setMockInitialValues({CrashConsent.prefsKey: true});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      expect(c.read(crashConsentProvider), isTrue);
    });

    test('uncaught errors are forwarded to the reporter and the old handlers come back', () {
      final reporter = FakeCrashReporter();
      final originalFlutter = FlutterError.onError;
      final originalPlatform = PlatformDispatcher.instance.onError;
      // Keep the test runner from treating the deliberately reported error as a failure.
      FlutterError.onError = (_) {};
      final restore = installErrorHooks(reporter);

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('boom'), stack: StackTrace.current));
      final handled = PlatformDispatcher.instance.onError!(ArgumentError('async boom'), StackTrace.current);
      restore();

      expect(handled, isTrue);
      expect(reporter.recorded, [isA<StateError>(), isA<ArgumentError>()]);
      expect(PlatformDispatcher.instance.onError, originalPlatform);
      FlutterError.onError = originalFlutter;
    });
  });

  group('consent card on the home screen', () {
    testWidgets('asks once; agreeing turns collection on and removes the card', (tester) async {
      final reporter = FakeCrashReporter();
      final c = await _open(tester, reporter);
      expect(find.text('ساعدنا على تحسين نور'), findsOneWidget);
      await tester.tap(find.text('أوافق'));
      await tester.pumpAndSettle();
      expect(find.text('ساعدنا على تحسين نور'), findsNothing);
      expect(c.read(crashConsentProvider), isTrue);
      expect(reporter.enabledCalls, [true]);
    });

    testWidgets('declining keeps collection off and removes the card', (tester) async {
      final reporter = FakeCrashReporter();
      final c = await _open(tester, reporter);
      await tester.tap(find.text('لا، شكرًا'));
      await tester.pumpAndSettle();
      expect(find.text('ساعدنا على تحسين نور'), findsNothing);
      expect(c.read(crashConsentProvider), isFalse);
      expect(reporter.enabledCalls, [false]);
    });

    testWidgets('is not shown when the choice was already made', (tester) async {
      await _open(tester, FakeCrashReporter(), prefsValues: {CrashConsent.prefsKey: false});
      expect(find.text('ساعدنا على تحسين نور'), findsNothing);
    });

    testWidgets('is not shown when this build has no crash reporting', (tester) async {
      await _open(tester, FakeCrashReporter(available: false));
      expect(find.text('ساعدنا على تحسين نور'), findsNothing);
    });
  });

  group('privacy screen', () {
    testWidgets('shows the policy from the bundled data and the crash-report switch', (tester) async {
      final reporter = FakeCrashReporter();
      final c = await _open(tester, reporter, route: '/privacy');
      expect(find.text('ملخص'), findsOneWidget);
      expect(find.text('الحساب (اختياري)'), findsOneWidget);
      final toggle = find.byType(Switch);
      expect(toggle, findsOneWidget);
      expect(tester.widget<Switch>(toggle).value, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(c.read(crashConsentProvider), isTrue);
      expect(reporter.enabledCalls, [true]);
    });

    testWidgets('has no switch when crash reporting is unavailable but still shows the policy', (tester) async {
      await _open(tester, FakeCrashReporter(available: false), route: '/privacy');
      expect(find.byType(Switch), findsNothing);
      expect(find.text('ملخص'), findsOneWidget);
    });
  });

  group('privacy policy data', () {
    test('every section is written in both languages with matching paragraph counts', () {
      final data = jsonDecode(File('assets/data/privacy.json').readAsStringSync()) as Map<String, dynamic>;
      final sections = (data['sections'] as List).cast<Map<String, dynamic>>();
      expect(sections.map((s) => s['id']), containsAll(['summary', 'device', 'location', 'account', 'crash', 'network', 'rights', 'children']));
      for (final s in sections) {
        expect((s['titleAr'] as String).trim(), isNotEmpty, reason: s['id'] as String);
        expect((s['titleEn'] as String).trim(), isNotEmpty, reason: s['id'] as String);
        expect((s['ar'] as List).length, (s['en'] as List).length, reason: 'same number of paragraphs in ${s['id']}');
      }
    });

    test('the public page is generated from the same data', () {
      final html = File('site/privacy/index.html').readAsStringSync();
      expect(html, contains('id="ar"'));
      expect(html, contains('id="en"'));
      expect(html, contains('Privacy Policy'));
    });
  });
}
