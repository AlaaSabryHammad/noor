import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/data/location_service.dart';
import 'package:noor/features/prayer/data/prayer_times_repository.dart';
import 'package:noor/features/prayer/domain/prayer_cities.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements LocationService {
  _Fake(this.result);
  final LocationResult result;
  @override
  Future<LocationResult> current() async => result;
}

Future<ProviderContainer> _container(LocationResult r, [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), locationServiceProvider.overrideWithValue(_Fake(r))]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults to Dammam, picked city persists across containers', () async {
    final c = await _container(const LocationResult.fail(LocationFailure.unavailable));
    expect(c.read(prayerLocationProvider), PrayerLocation.dammam);
    final cairoLike = prayerCities.firstWhere((x) => x.nameEn.startsWith('Amman'));
    c.read(prayerLocationProvider.notifier).select(cairoLike);

    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(prayerLocationProvider), cairoLike);
  });

  test('device location success replaces the city and has no fixed offset', () async {
    final c = await _container(const LocationResult.ok(51.5, -0.12));
    expect(await c.read(prayerLocationProvider.notifier).useDeviceLocation(), isNull);
    final l = c.read(prayerLocationProvider);
    expect((l.latitude, l.longitude, l.utcOffsetMinutes), (51.5, -0.12, null));
  });

  test('device location failure keeps the previous location', () async {
    final c = await _container(const LocationResult.fail(LocationFailure.deniedForever));
    expect(await c.read(prayerLocationProvider.notifier).useDeviceLocation(), LocationFailure.deniedForever);
    expect(c.read(prayerLocationProvider), PrayerLocation.dammam);
  });

  test('corrupt saved location falls back to Dammam', () async {
    final c = await _container(const LocationResult.fail(LocationFailure.unavailable), {'prayer.location': '{"lat": 999, "lng": 0}'});
    expect(c.read(prayerLocationProvider), PrayerLocation.dammam);
  });

  test('city offset re-bases wall clock without moving the instant', () {
    const repo = AdhanPrayerTimesRepository();
    final jakarta = prayerCities.firstWhere((x) => x.nameEn.startsWith('Jakarta'));
    final day = repo.dayFor(DateTime(2026, 10, 23), jakarta);
    final fajr = day.timeOf(PrayerKind.fajr);
    expect(day.wall(fajr).hour, inInclusiveRange(3, 5)); // Jakarta fajr ≈ 04:3x WIB
    expect(day.wall(fajr).toUtc().difference(fajr.toUtc()), const Duration(hours: 7));
  });

  test('every listed city has valid coordinates', () {
    for (final c in prayerCities) {
      expect(c.latitude.abs() <= 90 && c.longitude.abs() <= 180, isTrue, reason: c.nameEn);
      expect(c.utcOffsetMinutes, isNotNull, reason: c.nameEn);
    }
  });
}
