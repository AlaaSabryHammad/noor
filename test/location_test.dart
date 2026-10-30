import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' show Placemark;
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/data/location_service.dart';
import 'package:noor/features/prayer/data/place_names.dart';
import 'package:noor/features/prayer/data/prayer_times_repository.dart';
import 'package:noor/features/prayer/domain/prayer_cities.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements LocationService {
  _Fake(this.result);
  LocationResult result;
  final prompts = <bool>[];
  @override
  Future<LocationResult> current({bool prompt = true}) async {
    prompts.add(prompt);
    return result;
  }
}

class _Namer implements PlaceNamer {
  _Namer([this.name]);
  final PlaceName? name;
  int calls = 0;
  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async {
    calls++;
    return name;
  }

  @override
  Future<List<PlaceHit>> search(String query) async => [(name: _hafar, latitude: 28.4328, longitude: 45.9708)];
}

const _hafar = (ar: 'حفر الباطن، السعودية', en: 'Hafar Al Batin, Saudi Arabia', country: 'SA');

Future<ProviderContainer> _container(LocationResult r, [Map<String, Object> initial = const {}, PlaceNamer? namer]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs), locationServiceProvider.overrideWithValue(_Fake(r)), placeNamerProvider.overrideWithValue(namer ?? _Namer())],
  );
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
    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), placeNamerProvider.overrideWithValue(_Namer())]);
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

  test('device location gets the real city name and is marked as from the device', () async {
    final c = await _container(const LocationResult.ok(28.4328, 45.9708), const {}, _Namer(_hafar));
    expect(c.read(locationChosenProvider), isFalse);
    expect(await c.read(prayerLocationProvider.notifier).useDeviceLocation(), isNull);
    final l = c.read(prayerLocationProvider);
    expect((l.nameAr, l.nameEn, l.fromDevice), ('حفر الباطن، السعودية', 'Hafar Al Batin, Saudi Arabia', true));
    expect(c.read(locationChosenProvider), isTrue);
    // Survives a restart with the flag.
    final again = PrayerLocation.fromJson(jsonDecode(c.read(sharedPreferencesProvider).getString('prayer.location')!) as Map<String, dynamic>)!;
    expect(again.fromDevice, isTrue);
  });

  test('the country, not the nearest city, picks the method: Hafar Al-Batin is Umm al-Qura', () async {
    final c = await _container(const LocationResult.ok(28.4328, 45.9708), const {}, _Namer(_hafar));
    await c.read(prayerLocationProvider.notifier).useDeviceLocation();
    expect(c.read(prayerLocationProvider).countryCode, 'SA');
    expect(c.read(effectiveMethodProvider), PrayerMethod.ummAlQura);
    final again = PrayerLocation.fromJson(jsonDecode(c.read(sharedPreferencesProvider).getString('prayer.location')!) as Map<String, dynamic>)!;
    expect(again.countryCode, 'SA');
  });

  test('a fix saved without its country gets it at launch; offline keeps the name', () async {
    final saved = {'prayer.location': jsonEncode(const PrayerLocation(nameAr: 'حفر الباطن', nameEn: 'Hafar Al Batin', latitude: 28.4328, longitude: 45.9708, fromDevice: true).toJson())};
    final offline = await _container(const LocationResult.ok(28.4329, 45.9709), saved);
    await offline.read(prayerLocationProvider.notifier).bootstrap();
    expect((offline.read(prayerLocationProvider).nameEn, offline.read(prayerLocationProvider).countryCode), ('Hafar Al Batin', null));

    final online = await _container(const LocationResult.ok(28.4329, 45.9709), saved, _Namer(_hafar));
    // Nearest listed city until the country is known; the same coordinates must still update it.
    expect(online.read(effectiveMethodProvider), PrayerMethod.kuwait);
    await online.read(prayerLocationProvider.notifier).bootstrap();
    final l = online.read(prayerLocationProvider);
    expect((l.countryCode, l.latitude, l.fromDevice), ('SA', 28.4328, true));
    expect(online.read(effectiveMethodProvider), PrayerMethod.ummAlQura);
    // Complete now: the next launch in the same place asks the map nothing.
    final namer = online.read(placeNamerProvider) as _Namer;
    final calls = namer.calls;
    await online.read(prayerLocationProvider.notifier).bootstrap();
    expect(namer.calls, calls);
  });

  test('offline: named after the listed city it is in, else a generic label', () async {
    final inRiyadh = await _container(const LocationResult.ok(24.72, 46.68));
    await inRiyadh.read(prayerLocationProvider.notifier).useDeviceLocation();
    expect(inRiyadh.read(prayerLocationProvider).nameEn, 'Riyadh, Saudi Arabia');
    final inDesert = await _container(const LocationResult.ok(28.4328, 45.9708));
    await inDesert.read(prayerLocationProvider.notifier).useDeviceLocation();
    expect(inDesert.read(prayerLocationProvider).nameEn, 'My location');
  });

  test('first launch asks once; later launches follow the device silently', () async {
    final c = await _container(const LocationResult.ok(28.4328, 45.9708), const {}, _Namer(_hafar));
    final ctrl = c.read(prayerLocationProvider.notifier);
    final gps = c.read(locationServiceProvider) as _Fake;
    await ctrl.bootstrap();
    expect(gps.prompts, [true]);
    expect(c.read(prayerLocationProvider).nameEn, startsWith('Hafar'));
    // Next launch, same place: no prompt, no change.
    await ctrl.bootstrap();
    expect(gps.prompts, [true, false]);
    // Moved ~100 km: the location follows.
    gps.result = const LocationResult.ok(27.5, 45.9);
    await ctrl.bootstrap();
    expect(c.read(prayerLocationProvider).latitude, 27.5);
  });

  test('a refused first prompt is not repeated; a picked city is never overridden', () async {
    final c = await _container(const LocationResult.fail(LocationFailure.denied));
    final ctrl = c.read(prayerLocationProvider.notifier);
    final gps = c.read(locationServiceProvider) as _Fake;
    await ctrl.bootstrap();
    await ctrl.bootstrap();
    expect(gps.prompts, [true]);
    expect(c.read(prayerLocationProvider), PrayerLocation.dammam);
    ctrl.select(prayerCities.first);
    gps.result = const LocationResult.ok(28.4328, 45.9708);
    await ctrl.bootstrap();
    expect(c.read(prayerLocationProvider), prayerCities.first);
  });

  test('a first launch that got no answer (GPS without a fix, location switched off) asks again next time', () async {
    for (final failure in [LocationFailure.unavailable, LocationFailure.serviceOff]) {
      final c = await _container(LocationResult.fail(failure));
      final ctrl = c.read(prayerLocationProvider.notifier);
      final gps = c.read(locationServiceProvider) as _Fake;
      await ctrl.bootstrap();
      await ctrl.bootstrap();
      expect(gps.prompts, [true, true], reason: '$failure: nothing was decided, so it is not "asked"');
      gps.result = const LocationResult.ok(28.4328, 45.9708);
      await ctrl.bootstrap();
      expect(c.read(locationChosenProvider), isTrue, reason: '$failure: the third try works');
    }
  });

  test('a remembered position (weak signal) is used and known to be old; a new fix is not', () async {
    expect(const LocationResult.ok(1, 2).stale, isFalse);
    expect(const LocationResult.ok(1, 2, age: Duration(minutes: 9)).stale, isFalse);
    expect(const LocationResult.ok(1, 2, age: Duration(minutes: 70)).stale, isTrue);

    final c = await _container(const LocationResult.ok(28.4328, 45.9708, age: Duration(minutes: 70), accuracyMeters: 20), const {}, _Namer(_hafar));
    final ctrl = c.read(prayerLocationProvider.notifier);
    expect(await ctrl.useDeviceLocation(), isNull, reason: 'better than staying on the default city');
    expect(c.read(prayerLocationProvider).nameEn, startsWith('Hafar'));
    expect((ctrl.lastFixStale, ctrl.lastFixAge), (true, const Duration(minutes: 70)));

    (c.read(locationServiceProvider) as _Fake).result = const LocationResult.ok(28.4329, 45.9709, accuracyMeters: 12);
    await ctrl.useDeviceLocation();
    expect((ctrl.lastFixStale, ctrl.lastFixAccuracy), (false, 12.0));
  });

  test('a first launch interrupted behind the permission dialog is not counted as asked', () async {
    // The app is closed while the dialog is up: bootstrap never finishes, so nothing is saved.
    final c = await _container(const LocationResult.fail(LocationFailure.denied));
    expect(c.read(sharedPreferencesProvider).containsKey('prayer.location.asked'), isFalse);
    await c.read(prayerLocationProvider.notifier).bootstrap();
    expect(c.read(sharedPreferencesProvider).getBool('prayer.location.asked'), isTrue, reason: 'an answer was given');
  });

  test('a place found by name keeps its exact coordinates and the device time zone', () async {
    final c = await _container(const LocationResult.fail(LocationFailure.unavailable));
    final hits = await c.read(placeNamerProvider).search('حفر الباطن');
    c.read(prayerLocationProvider.notifier).selectPlace(hits.first);
    final l = c.read(prayerLocationProvider);
    expect((l.latitude, l.longitude, l.utcOffsetMinutes, l.fromDevice), (28.4328, 45.9708, null, false));
    expect((l.nameAr, l.countryCode), ('حفر الباطن، السعودية', 'SA'));
  });

  test('city name: most specific level the map knows, then the country', () {
    expect(composePlaceName(Placemark(locality: 'حفر الباطن', administrativeArea: 'المنطقة الشرقية', country: 'السعودية'), arabic: true), 'حفر الباطن، السعودية');
    expect(composePlaceName(Placemark(subAdministrativeArea: 'Hafar Al Batin', country: 'Saudi Arabia'), arabic: false), 'Hafar Al Batin, Saudi Arabia');
    expect(composePlaceName(Placemark(locality: ' ', administrativeArea: 'Eastern Province', country: 'Saudi Arabia'), arabic: false), 'Eastern Province, Saudi Arabia');
    expect(composePlaceName(Placemark(country: 'Qatar'), arabic: false), 'Qatar');
    expect(composePlaceName(Placemark(), arabic: false), isNull);
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
