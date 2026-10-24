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

  test('a known country decides the method, across a nearer border', () {
    const hafar = PrayerLocation(nameAr: '', nameEn: '', latitude: 28.4328, longitude: 45.9708);
    // Nearest listed city is Kuwait City; the country says Saudi Arabia.
    expect(methodFor(hafar, prayerCities), PrayerMethod.kuwait);
    const hafarSa = PrayerLocation(nameAr: '', nameEn: '', latitude: 28.4328, longitude: 45.9708, countryCode: 'SA');
    expect(methodFor(hafarSa, prayerCities), PrayerMethod.ummAlQura);
    const jahra = PrayerLocation(nameAr: '', nameEn: '', latitude: 29.34, longitude: 47.66, countryCode: 'KW');
    expect(methodFor(jahra, prayerCities), PrayerMethod.kuwait);
    const khobarSide = PrayerLocation(nameAr: '', nameEn: '', latitude: 26.2, longitude: 50.55, countryCode: 'BH');
    expect(methodFor(khobarSide, prayerCities), PrayerMethod.muslimWorldLeague);
  });

  test('listed cities and the country table agree', () {
    const codes = {
      'Saudi Arabia': 'SA', 'UAE': 'AE', 'Qatar': 'QA', 'Kuwait': 'KW', 'Bahrain': 'BH', 'Oman': 'OM', 'Jordan': 'JO', 'Syria': 'SY', 'Iraq': 'IQ', 'Yemen': 'YE', //
      'Türkiye': 'TR', 'Sudan': 'SD', 'Libya': 'LY', 'Tunisia': 'TN', 'Algeria': 'DZ', 'Somalia': 'SO', 'Pakistan': 'PK', 'Bangladesh': 'BD', 'Indonesia': 'ID', 'Malaysia': 'MY',
    };
    for (final c in prayerCities) {
      final code = codes[c.nameEn.split(', ').last];
      expect(code, isNotNull, reason: c.nameEn);
      expect(countryMethods[code] ?? PrayerMethod.muslimWorldLeague, c.method, reason: c.nameEn);
    }
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
