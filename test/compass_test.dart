import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/core/theme/noor_theme.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/compass.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:noor/features/prayer/qibla_screen.dart';
import 'package:noor/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Noop implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

class _FakeCompass implements CompassSource {
  _FakeCompass(this.controller);
  final StreamController<CompassReading>? controller;
  @override
  Stream<CompassReading>? get readings => controller?.stream;
}

Future<void> _pump(WidgetTester tester, CompassSource source) async {
  SharedPreferences.setMockInitialValues({'settings.locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  // Tall enough that the lazy list builds the whole screen.
  tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_Noop()),
      compassSourceProvider.overrideWithValue(source),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: NoorTheme.light(const Locale('en')),
      home: const QiblaScreen(),
    ),
  ));
}

void main() {
  group('angle maths', () {
    test('normalizeDegrees wraps both ways', () {
      expect(normalizeDegrees(-10), 350);
      expect(normalizeDegrees(370), 10);
      expect(normalizeDegrees(0), 0);
    });

    test('angleDelta takes the short way round north', () {
      expect(angleDelta(350, 10), 20);
      expect(angleDelta(10, 350), -20);
      expect(angleDelta(0, 180).abs(), 180);
    });

    test('smoothAngle never swings through 180° at the wrap', () {
      final s = smoothAngle(359, 1, alpha: .5);
      expect(s, closeTo(0, 1e-9));
      expect(smoothAngle(100, 100), 100);
    });
  });

  testWidgets('live readings drive the status and flag alignment with the Qibla', (tester) async {
    final c = StreamController<CompassReading>();
    addTearDown(c.close);
    await _pump(tester, _FakeCompass(c));
    final container = ProviderScope.containerOf(tester.element(find.byType(QiblaScreen)));
    final bearing = container.read(prayerDayProvider).qiblaBearing; // ≈ 244° from Dammam

    c.add(CompassReading(bearing + 30));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Turn left'), findsOneWidget);

    c.add(CompassReading(bearing - 30));
    for (var i = 0; i < 40; i++) {
      c.add(CompassReading(bearing - 30)); // let the smoothing converge
    }
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Turn right'), findsOneWidget);

    for (var i = 0; i < 80; i++) {
      c.add(CompassReading(bearing));
    }
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('facing the Qibla'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('no sensor: the preview slider appears and works', (tester) async {
    await _pump(tester, _FakeCompass(null));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pump();
    expect(find.textContaining('°'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('poor accuracy shows the calibration warning', (tester) async {
    final c = StreamController<CompassReading>();
    addTearDown(c.close);
    await _pump(tester, _FakeCompass(c));
    c.add(const CompassReading(100, accuracy: 40));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('figure-eight'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
