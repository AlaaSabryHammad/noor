import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/data/prayer_times_repository.dart';
import 'package:noor/features/prayer/domain/prayer_cities.dart';
import 'package:noor/features/prayer/domain/prayer_method.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  PrayerLocation city(String prefix) => prayerCities.firstWhere((c) => c.nameEn.startsWith(prefix));

  test('every listed city has a regional method', () {
    expect(prayerCities.every((c) => c.method != null), isTrue);
    expect(methodFor(city('Riyadh'), prayerCities), PrayerMethod.ummAlQura);
    expect(methodFor(city('Karachi'), prayerCities), PrayerMethod.karachi);
    expect(methodFor(city('Istanbul'), prayerCities), PrayerMethod.turkey);
  });

  test('GPS fix borrows the nearest city, far away falls back to MWL', () {
    const nearDubai = PrayerLocation(nameAr: '', nameEn: '', latitude: 25.0, longitude: 55.0);
    const london = PrayerLocation(nameAr: '', nameEn: '', latitude: 51.5, longitude: -0.12);
    expect(methodFor(nearDubai, prayerCities), PrayerMethod.dubai);
    expect(methodFor(london, prayerCities), PrayerMethod.muslimWorldLeague);
  });

  test('different methods give different Fajr; Hanafi Asr is later', () {
    final d = DateTime(2026, 10, 23);
    final loc = PrayerLocation.dammam;
    final umm = const AdhanPrayerTimesRepository().dayFor(d, loc);
    final mwl = const AdhanPrayerTimesRepository(method: PrayerMethod.muslimWorldLeague).dayFor(d, loc);
    final hanafi = const AdhanPrayerTimesRepository(madhab: AsrMadhab.hanafi).dayFor(d, loc);
    expect(umm.timeOf(PrayerKind.fajr), isNot(mwl.timeOf(PrayerKind.fajr)));
    expect(hanafi.timeOf(PrayerKind.asr).isAfter(umm.timeOf(PrayerKind.asr)), isTrue);
  });

  test('Umm al-Qura isha is +90 min normally and +120 min in Ramadan', () {
    const repo = AdhanPrayerTimesRepository();
    int gap(DateTime d) {
      final day = repo.dayFor(d, PrayerLocation.dammam);
      return day.timeOf(PrayerKind.isha).difference(day.timeOf(PrayerKind.maghrib)).inMinutes;
    }

    expect(gap(DateTime(2026, 10, 23)), 90);
    expect(gap(DateTime(2026, 3, 5)), 120); // Ramadan 1447
    // Other methods are untouched by the Ramadan rule.
    const mwl = AdhanPrayerTimesRepository(method: PrayerMethod.muslimWorldLeague);
    final d = mwl.dayFor(DateTime(2026, 3, 5), PrayerLocation.dammam);
    expect(d.timeOf(PrayerKind.isha).difference(d.timeOf(PrayerKind.maghrib)).inMinutes, isNot(120));
  });

  test('choice persists; effective method follows location until overridden', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    expect(c.read(effectiveMethodProvider), PrayerMethod.ummAlQura); // Dammam default
    c.read(prayerLocationProvider.notifier).select(city('Karachi'));
    expect(c.read(effectiveMethodProvider), PrayerMethod.karachi);
    c.read(prayerCalcProvider.notifier).setMethod(PrayerMethod.egyptian);
    c.read(prayerCalcProvider.notifier).setMadhab(AsrMadhab.hanafi);
    expect(c.read(effectiveMethodProvider), PrayerMethod.egyptian);

    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(prayerCalcProvider).method, PrayerMethod.egyptian);
    expect(c2.read(prayerCalcProvider).madhab, AsrMadhab.hanafi);
    c2.read(prayerCalcProvider.notifier).setMethod(null);
    expect(c2.read(effectiveMethodProvider), PrayerMethod.karachi);
  });
}
