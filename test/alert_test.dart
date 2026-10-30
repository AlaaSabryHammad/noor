import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/data/prayer_times_repository.dart';
import 'package:noor/features/prayer/domain/alert_models.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:noor/features/settings/settings_controller.dart';
import 'package:noor/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _FakeScheduler implements NotificationScheduler {
  final plans = <List<PlannedAlert>>[];
  var permissionRequests = 0;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async => plans.add(alerts);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // AppLifecycleListener needs the binding
  const repo = AdhanPrayerTimesRepository();
  final l = lookupAppLocalizations(const Locale('ar'));
  final now = fridayMorning;

  test('plans only enabled prayers, in the future, soonest first', () {
    final plan = planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {PrayerKind.dhuhr, PrayerKind.maghrib}, now: now, l: l);
    expect(plan.every((a) => a.time.isAfter(now)), isTrue);
    expect(plan.map((a) => a.kind).toSet(), {PrayerKind.dhuhr, PrayerKind.maghrib});
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].time.isAfter(plan[i - 1].time), isTrue);
    }
    expect(plan.map((a) => a.id), List.generate(plan.length, (i) => i));
  });

  test('covers the 7-day horizon with five prayers and stays under the iOS limit', () {
    final all = PrayerKind.values.where((k) => k.isPrayer).toSet();
    final plan = planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: all, now: DateTime(2026, 10, 23, 0, 5), l: l);
    expect(plan.length, 35);
    expect(plan.length, lessThan(64));
  });

  test('no alerts when none are enabled; sunrise never alerts', () {
    expect(planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {}, now: now, l: l), isEmpty);
    expect(planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {PrayerKind.sunrise}, now: now, l: l), isEmpty);
  });

  test('Friday dhuhr is titled Jumu‘ah', () {
    final plan = planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {PrayerKind.dhuhr}, now: now, l: l);
    expect(plan.first.title, l.adhanNotifTitle(l.jumuah));
    expect(plan[1].title, l.adhanNotifTitle(l.dhuhr)); // Saturday
  });

  test('sync schedules on start, then re-plans when an alert is toggled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = _FakeScheduler();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), notificationSchedulerProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    c.listen(alertSyncProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fake.plans, hasLength(1));
    expect(fake.permissionRequests, 1); // asked once on first launch
    final before = fake.plans.last.length;

    c.read(prayerAlertsProvider.notifier).toggle(PrayerKind.fajr);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fake.plans.last.length, lessThan(before));
    expect(fake.plans.last.any((a) => a.kind == PrayerKind.fajr), isFalse);
    expect(fake.permissionRequests, 1);

    c.read(settingsProvider.notifier).setLocale(const Locale('en'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fake.plans.last.first.title, startsWith("It's time for"));
  });

  test('alerts carry the chosen sound, the adhan by default', () {
    final plan = planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {PrayerKind.dhuhr}, now: now, l: l);
    expect(plan.every((a) => a.sound == AdhanSound.adhan), isTrue);
    final quiet = planAlerts(repo: repo, location: PrayerLocation.dammam, enabled: {PrayerKind.dhuhr}, now: now, l: l, sound: AdhanSound.silent);
    expect(quiet.every((a) => a.sound == AdhanSound.silent), isTrue);
  });

  test('the sound choice is restored on the next launch and falls back to the adhan on bad data', () async {
    SharedPreferences.setMockInitialValues({'prayer.alertSound': 'tone'});
    var prefs = await SharedPreferences.getInstance();
    var c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    expect(c.read(alertSoundProvider), AdhanSound.tone);
    c.dispose();

    SharedPreferences.setMockInitialValues({'prayer.alertSound': 'nonsense'});
    prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    expect(c.read(alertSoundProvider), AdhanSound.adhan);
  });
}
