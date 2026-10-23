import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'data/location_service.dart';
import 'data/prayer_times_repository.dart';
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

/// The active location: a picked city or a GPS fix, persisted. Dammam until
/// the user chooses.
class PrayerLocationController extends Notifier<PrayerLocation> {
  static const _k = 'prayer.location';

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

  void select(PrayerLocation l) {
    state = l;
    ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(l.toJson()));
  }

  /// Uses the device position. Returns the failure, or null on success.
  Future<LocationFailure?> useDeviceLocation() async {
    final r = await ref.read(locationServiceProvider).current();
    if (!r.ok) return r.failure;
    select(PrayerLocation(nameAr: 'موقعي الحالي', nameEn: 'My location', latitude: r.latitude, longitude: r.longitude));
    return null;
  }
}

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
