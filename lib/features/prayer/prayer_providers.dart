import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'data/location_service.dart';
import 'data/place_names.dart';
import 'data/prayer_times_repository.dart';
import 'domain/alert_models.dart';
import 'domain/prayer_cities.dart';
import 'domain/prayer_method.dart';
import 'domain/prayer_models.dart';

/// The user's method (null = automatic by location) and Asr rule, persisted.
class PrayerCalcController extends Notifier<PrayerCalcSettings> {
  static const _kMethod = 'prayer.method', _kMadhab = 'prayer.madhab';

  @override
  PrayerCalcSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    final m = p.getString(_kMethod), a = p.getString(_kMadhab);
    return PrayerCalcSettings(
      method: PrayerMethod.values.where((e) => e.name == m).firstOrNull,
      madhab: AsrMadhab.values.where((e) => e.name == a).firstOrNull ?? AsrMadhab.standard,
    );
  }

  /// Pass null for automatic.
  void setMethod(PrayerMethod? m) {
    state = PrayerCalcSettings(method: m, madhab: state.madhab);
    final p = ref.read(sharedPreferencesProvider);
    m == null ? p.remove(_kMethod) : p.setString(_kMethod, m.name);
  }

  void setMadhab(AsrMadhab a) {
    state = PrayerCalcSettings(method: state.method, madhab: a);
    ref.read(sharedPreferencesProvider).setString(_kMadhab, a.name);
  }
}

final prayerCalcProvider = NotifierProvider<PrayerCalcController, PrayerCalcSettings>(PrayerCalcController.new);

/// What is actually used: the user's pick, else the regional default.
final effectiveMethodProvider = Provider<PrayerMethod>((ref) => ref.watch(prayerCalcProvider).method ?? methodFor(ref.watch(prayerLocationProvider), prayerCities));

final prayerRepositoryProvider = Provider<PrayerTimesRepository>((ref) => AdhanPrayerTimesRepository(method: ref.watch(effectiveMethodProvider), madhab: ref.watch(prayerCalcProvider).madhab));

final locationServiceProvider = Provider<LocationService>((ref) => const GeolocatorLocationService());

final placeNamerProvider = Provider<PlaceNamer>((ref) => PlatformPlaceNamer());

/// The active location: a picked city, a searched place or the device
/// position, persisted. Dammam until the person allows location or chooses.
class PrayerLocationController extends Notifier<PrayerLocation> {
  static const _k = 'prayer.location', _kAsked = 'prayer.location.asked';

  /// Moving less than this keeps the current fix (and its name) as it is.
  static const followKm = 3.0;

  @override
  PrayerLocation build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_k);
    if (raw == null) return PrayerLocation.dammam;
    try {
      return PrayerLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>) ?? PrayerLocation.dammam;
    } catch (_) {
      return PrayerLocation.dammam;
    }
  }

  /// False until the person allows location or picks a place: times are for the Dammam default.
  bool get chosen => ref.read(sharedPreferencesProvider).containsKey(_k);

  void select(PrayerLocation l) {
    state = l;
    ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(l.toJson()));
  }

  /// The city's real name from the map service; offline, the listed city it
  /// is in (within 30 km), else a generic label.
  Future<PlaceName> _nameOf(double lat, double lng) async {
    final named = await ref.read(placeNamerProvider).nameOf(lat, lng);
    if (named != null) return named;
    PrayerLocation? near;
    var best = 30.0;
    for (final c in prayerCities) {
      final km = approxKm(lat, lng, c.latitude, c.longitude);
      if (km < best) (best, near) = (km, c);
    }
    return near != null ? (ar: near.nameAr, en: near.nameEn, country: null) : (ar: 'موقعي الحالي', en: 'My location', country: null);
  }

  /// Uses the device position. Returns the failure, or null on success.
  Future<LocationFailure?> useDeviceLocation({bool prompt = true}) async {
    final r = await ref.read(locationServiceProvider).current(prompt: prompt);
    if (!r.ok) return r.failure;
    final name = await _nameOf(r.latitude, r.longitude);
    select(PrayerLocation(nameAr: name.ar, nameEn: name.en, countryCode: name.country, latitude: r.latitude, longitude: r.longitude, fromDevice: true));
    return null;
  }

  /// A place found by name: exact coordinates, shown in the device time zone.
  void selectPlace(PlaceHit hit) => select(PrayerLocation(nameAr: hit.name.ar, nameEn: hit.name.en, countryCode: hit.name.country, latitude: hit.latitude, longitude: hit.longitude));

  /// At launch: the first time, ask for the location once; afterwards, when
  /// the person uses their location, follow the device without asking again.
  Future<void> bootstrap() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!chosen) {
      if (prefs.getBool(_kAsked) ?? false) return;
      await prefs.setBool(_kAsked, true);
      await useDeviceLocation();
      return;
    }
    if (!state.fromDevice) return;
    final r = await ref.read(locationServiceProvider).current(prompt: false);
    if (!r.ok) return;
    final moved = approxKm(state.latitude, state.longitude, r.latitude, r.longitude) >= followKm;
    // Older versions saved the fix without its city's name or its country: fill them in.
    final unnamed = state.nameEn == 'My location';
    if (!moved && !unnamed && state.countryCode != null) return;
    final name = await _nameOf(r.latitude, r.longitude);
    // Offline in the same place: keep the real name rather than swap it for a guess.
    if (!moved && !unnamed && name.country == null) return;
    select(PrayerLocation(nameAr: name.ar, nameEn: name.en, countryCode: name.country, latitude: moved ? r.latitude : state.latitude, longitude: moved ? r.longitude : state.longitude, fromDevice: true));
  }
}

/// False while times are for the Dammam default (nothing chosen, location not allowed).
final locationChosenProvider = Provider<bool>((ref) {
  ref.watch(prayerLocationProvider);
  return ref.read(prayerLocationProvider.notifier).chosen;
});

/// Runs [PrayerLocationController.bootstrap] once per launch.
final locationBootstrapProvider = FutureProvider<void>((ref) => ref.read(prayerLocationProvider.notifier).bootstrap());

final prayerLocationProvider = NotifierProvider<PrayerLocationController, PrayerLocation>(PrayerLocationController.new);

/// Recomputed only when the civil date changes.
final todayProvider = Provider<DateTime>((ref) {
  final n = ref.watch(nowProvider);
  return DateTime(n.year, n.month, n.day);
});

final prayerDayProvider = Provider<PrayerDay>((ref) {
  final date = ref.watch(todayProvider);
  return ref.watch(prayerRepositoryProvider).dayFor(date, ref.watch(prayerLocationProvider));
});

/// Per-prayer adhan alert toggles, persisted. Scheduling the actual
/// notifications is the job of a NotificationScheduler (flutter_local_notifications).
class PrayerAlertsController extends Notifier<Set<PrayerKind>> {
  static const _k = 'prayer.alerts';

  @override
  Set<PrayerKind> build() {
    final saved = ref.watch(sharedPreferencesProvider).getStringList(_k);
    if (saved == null) return {PrayerKind.fajr, PrayerKind.dhuhr, PrayerKind.asr, PrayerKind.maghrib, PrayerKind.isha};
    return saved.map(PrayerKind.values.byName).toSet();
  }

  void toggle(PrayerKind k) {
    final next = {...state};
    next.contains(k) ? next.remove(k) : next.add(k);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_k, next.map((e) => e.name).toList());
  }
}

final prayerAlertsProvider = NotifierProvider<PrayerAlertsController, Set<PrayerKind>>(PrayerAlertsController.new);

/// What the alerts play: the adhan recording (default), the phone's tone, or vibration only. Persisted.
class AlertSoundController extends Notifier<AdhanSound> {
  static const _k = 'prayer.alertSound';

  @override
  AdhanSound build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_k);
    return AdhanSound.values.where((s) => s.name == saved).firstOrNull ?? AdhanSound.adhan;
  }

  void select(AdhanSound s) {
    state = s;
    ref.read(sharedPreferencesProvider).setString(_k, s.name);
  }
}

final alertSoundProvider = NotifierProvider<AlertSoundController, AdhanSound>(AlertSoundController.new);

String methodName(AppLocalizations l, PrayerMethod m) => switch (m) {
      PrayerMethod.ummAlQura => l.methodUmmAlQura,
      PrayerMethod.muslimWorldLeague => l.methodMwl,
      PrayerMethod.egyptian => l.methodEgyptian,
      PrayerMethod.karachi => l.methodKarachi,
      PrayerMethod.dubai => l.methodDubai,
      PrayerMethod.kuwait => l.methodKuwait,
      PrayerMethod.qatar => l.methodQatar,
      PrayerMethod.turkey => l.methodTurkey,
      PrayerMethod.singapore => l.methodSingapore,
      PrayerMethod.northAmerica => l.methodNorthAmerica,
      PrayerMethod.moonSighting => l.methodMoonSighting,
    };

String prayerName(AppLocalizations l, PrayerKind k, {bool friday = false}) => switch (k) {
      PrayerKind.fajr => l.fajr,
      PrayerKind.sunrise => l.sunrise,
      PrayerKind.dhuhr => friday ? l.jumuah : l.dhuhr,
      PrayerKind.asr => l.asr,
      PrayerKind.maghrib => l.maghrib,
      PrayerKind.isha => l.isha,
    };

IconData prayerIcon(PrayerKind k) => switch (k) {
      PrayerKind.fajr => Icons.wb_twilight_rounded,
      PrayerKind.sunrise => Icons.wb_sunny_outlined,
      PrayerKind.dhuhr => Icons.light_mode_outlined,
      PrayerKind.asr => Icons.wb_sunny_rounded,
      PrayerKind.maghrib => Icons.wb_twilight_rounded,
      PrayerKind.isha => Icons.dark_mode_outlined,
    };
