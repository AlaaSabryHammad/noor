import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_models.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _Scheduler implements NotificationScheduler {
  final plans = <List<PlannedAlert>>[];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async => plans.add(alerts);
}

class FakeDiagnostics implements AlertDiagnostics {
  FakeDiagnostics(this.state);
  AlertHealth state;
  final tests = <AdhanSound>[];
  final opened = <AlertSettingsPage>[];
  @override
  Future<AlertHealth> health() async => state;
  @override
  Future<bool> scheduleTest({required AdhanSound sound, required String title, required String body, Duration after = const Duration(seconds: 10)}) async {
    tests.add(sound);
    return true;
  }

  @override
  Future<void> openSettings(AlertSettingsPage page) async => opened.add(page);
}

Future<ProviderContainer> _open(WidgetTester tester, {AlertDiagnostics? diagnostics, _Scheduler? scheduler}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(scheduler ?? _Scheduler()),
      if (diagnostics != null) alertDiagnosticsProvider.overrideWithValue(diagnostics),
      nowProvider.overrideWithValue(fridayMorning),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
    ],
    child: const NoorApp(),
  ));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/prayer');
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(NoorApp)));
}

void main() {
  const title = 'صوت تنبيه الأذان';

  testWidgets('the card is hidden where alerts are not supported', (tester) async {
    await _open(tester);
    expect(find.text(title), findsNothing);
  });

  testWidgets('choosing a sound is saved and re-plans the alerts with it', (tester) async {
    final scheduler = _Scheduler();
    final c = await _open(tester, diagnostics: FakeDiagnostics(const AlertHealth(pending: 35)), scheduler: scheduler);
    expect(find.text(title), findsOneWidget);
    expect(c.read(alertSoundProvider), AdhanSound.adhan, reason: 'the adhan is the default');
    expect(scheduler.plans.last.every((a) => a.sound == AdhanSound.adhan), isTrue);

    await tester.tap(find.text('نغمة'));
    await tester.pumpAndSettle();
    expect(c.read(alertSoundProvider), AdhanSound.tone);
    expect(c.read(sharedPreferencesProvider).getString('prayer.alertSound'), 'tone');
    expect(scheduler.plans.last.every((a) => a.sound == AdhanSound.tone), isTrue);

    await tester.tap(find.text('صامت'));
    await tester.pumpAndSettle();
    expect(scheduler.plans.last.every((a) => a.sound == AdhanSound.silent), isTrue);
  });

  testWidgets('the adhan rings on the alarm volume by default; the switch lets it follow silent mode', (tester) async {
    final scheduler = _Scheduler();
    final c = await _open(tester, diagnostics: FakeDiagnostics(const AlertHealth(pending: 35)), scheduler: scheduler);
    expect(c.read(alertSoundProvider), AdhanSound.adhan);
    final loud = find.text('يُسمَع حتى والهاتف على الصامت');
    expect(loud, findsOneWidget);

    await tester.tap(loud);
    await tester.pumpAndSettle();
    expect(c.read(alertSoundProvider), AdhanSound.adhanSoft);
    expect(scheduler.plans.last.every((a) => a.sound == AdhanSound.adhanSoft), isTrue);

    // "Adhan" is still the highlighted choice, and tapping it again keeps the quieter setting.
    await tester.tap(find.text('الأذان'));
    await tester.pumpAndSettle();
    expect(c.read(alertSoundProvider), AdhanSound.adhanSoft);

    await tester.tap(find.text('نغمة'));
    await tester.pumpAndSettle();
    expect(find.text('يُسمَع حتى والهاتف على الصامت'), findsNothing, reason: 'only the adhan has this option');
  });

  testWidgets('the test button schedules an alert with the chosen sound', (tester) async {
    final diag = FakeDiagnostics(const AlertHealth(pending: 35));
    await _open(tester, diagnostics: diag);
    await tester.tap(find.text('صامت'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جرّب التنبيه بعد ١٠ ثوانٍ'));
    await tester.pumpAndSettle();
    expect(diag.tests, [AdhanSound.silent]);
    expect(find.textContaining('سيصلك تنبيه تجريبي'), findsOneWidget);
  });

  testWidgets('blocked notifications and exact alarms are reported with a way to fix them', (tester) async {
    final diag = FakeDiagnostics(const AlertHealth(notificationsAllowed: false, exactAlarmsAllowed: false, pending: 35));
    await _open(tester, diagnostics: diag);
    expect(find.textContaining('الإشعارات متوقفة'), findsOneWidget);
    expect(find.textContaining('قد يتأخر الأذان'), findsOneWidget);

    await tester.ensureVisible(find.text('فتح الإعدادات'));
    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('السماح'));
    await tester.tap(find.text('السماح'));
    await tester.pumpAndSettle();
    expect(diag.opened, [AlertSettingsPage.notifications, AlertSettingsPage.exactAlarms]);
  });

  testWidgets('a healthy phone shows no warning, just how many alerts are scheduled', (tester) async {
    await _open(tester, diagnostics: FakeDiagnostics(const AlertHealth(pending: 35)));
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.textContaining('تنبيهات مجدولة في النظام'), findsOneWidget);
  });

  testWidgets('nothing scheduled while alerts are on is flagged', (tester) async {
    await _open(tester, diagnostics: FakeDiagnostics(const AlertHealth(pending: 0)));
    expect(find.textContaining('لا توجد تنبيهات مجدولة'), findsOneWidget);
  });

  testWidgets('the background help shows the maker’s steps and opens its screen', (tester) async {
    final diag = FakeDiagnostics(const AlertHealth(pending: 35, vendor: BatteryVendor.huawei));
    await _open(tester, diagnostics: diag);
    await tester.ensureVisible(find.text('لا يرنّ والتطبيق مغلق؟'));
    await tester.tap(find.text('لا يرنّ والتطبيق مغلق؟'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تشغيل التطبيقات'), findsOneWidget); // Huawei: Battery → App launch
    await tester.tap(find.text('فتح إعدادات التشغيل في الخلفية'));
    await tester.pumpAndSettle();
    expect(diag.opened, [AlertSettingsPage.battery]);
  });
}
