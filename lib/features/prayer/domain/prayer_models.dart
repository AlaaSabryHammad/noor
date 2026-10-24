import 'package:flutter/foundation.dart';

enum PrayerKind { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Calculation methods offered in the app (a curated subset of what the
/// `adhan` package supports).
enum PrayerMethod { ummAlQura, muslimWorldLeague, egyptian, karachi, dubai, kuwait, qatar, turkey, singapore, northAmerica, moonSighting }

extension PrayerKindX on PrayerKind {
  /// Sunrise is a time marker, not a prayer — it gets no adhan alert.
  bool get isPrayer => this != PrayerKind.sunrise;
}

@immutable
class PrayerLocation {
  const PrayerLocation({required this.nameAr, required this.nameEn, required this.latitude, required this.longitude, this.utcOffsetMinutes, this.method, this.fromDevice = false, this.countryCode});

  /// Regional default method for a listed city; null for a GPS fix.
  final PrayerMethod? method;
  final String nameAr;
  final String nameEn;
  final double latitude;
  final double longitude;

  /// Fixed UTC offset used to *display* times for a picked city. Null means
  /// the device time zone (GPS fix, or the default). Only cities without
  /// daylight saving carry one, so a fixed offset is always right.
  final int? utcOffsetMinutes;

  Duration? get utcOffset => utcOffsetMinutes == null ? null : Duration(minutes: utcOffsetMinutes!);

  /// Taken from the device position: kept up to date when the person moves.
  final bool fromDevice;

  /// ISO country code ("SA") from the map service, for a GPS fix or a place
  /// found by name; null for listed cities (they carry [method]) or offline.
  final String? countryCode;

  /// Default until the user grants location or picks a city.
  static const dammam = PrayerLocation(nameAr: 'الدمام، المملكة العربية السعودية', nameEn: 'Dammam, Saudi Arabia', latitude: 26.4207, longitude: 50.0888, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura);

  Map<String, Object?> toJson() => {'nameAr': nameAr, 'nameEn': nameEn, 'lat': latitude, 'lng': longitude, 'utc': utcOffsetMinutes, 'method': method?.name, 'gps': fromDevice, 'cc': countryCode};

  static PrayerLocation? fromJson(Map<String, dynamic> j) {
    final lat = (j['lat'] as num?)?.toDouble(), lng = (j['lng'] as num?)?.toDouble();
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
    final m = j['method'] as String?;
    return PrayerLocation(
      nameAr: j['nameAr'] as String? ?? '',
      nameEn: j['nameEn'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      utcOffsetMinutes: j['utc'] as int?,
      method: PrayerMethod.values.where((e) => e.name == m).firstOrNull,
      fromDevice: j['gps'] as bool? ?? false,
      countryCode: j['cc'] as String?,
    );
  }

  // Every field counts: providers skip updates that compare equal, so naming a
  // fix or learning its country at the same coordinates must still notify.
  @override
  bool operator ==(Object other) =>
      other is PrayerLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.utcOffsetMinutes == utcOffsetMinutes &&
      other.nameAr == nameAr &&
      other.nameEn == nameEn &&
      other.method == method &&
      other.fromDevice == fromDevice &&
      other.countryCode == countryCode;

  @override
  int get hashCode => Object.hash(latitude, longitude, utcOffsetMinutes, nameAr, nameEn, method, fromDevice, countryCode);
}

@immutable
class PrayerSlot {
  const PrayerSlot(this.kind, this.time);
  final PrayerKind kind;
  final DateTime time;
}

/// One civil day of prayer times plus the neighbours needed to roll over midnight.
@immutable
class PrayerDay {
  const PrayerDay({required this.date, required this.slots, required this.tomorrowFajr, required this.yesterdayIsha, required this.qiblaBearing, this.displayOffset});

  final DateTime date;

  /// When set, wall-clock times are shown for this UTC offset instead of the
  /// device time zone. Instants themselves stay absolute.
  final Duration? displayOffset;

  /// [t] re-based for display (read `.hour` / `.minute` from the result).
  DateTime wall(DateTime t) => displayOffset == null ? t : t.toUtc().add(displayOffset!);
  final List<PrayerSlot> slots; // fajr, sunrise, dhuhr, asr, maghrib, isha
  final DateTime tomorrowFajr;
  final DateTime yesterdayIsha;
  final double qiblaBearing; // degrees clockwise from true north

  bool get isFriday => date.weekday == DateTime.friday;

  DateTime timeOf(PrayerKind k) => slots.firstWhere((s) => s.kind == k).time;

  /// Next actual prayer (sunrise skipped).
  PrayerSlot next(DateTime now) {
    for (final s in slots) {
      if (s.kind.isPrayer && s.time.isAfter(now)) return s;
    }
    return PrayerSlot(PrayerKind.fajr, tomorrowFajr);
  }

  /// Most recent event including sunrise (so 06:00–Dhuhr reads as Duha).
  PrayerSlot previous(DateTime now) {
    PrayerSlot? last;
    for (final s in slots) {
      if (!s.time.isAfter(now)) last = s;
    }
    return last ?? PrayerSlot(PrayerKind.isha, yesterdayIsha);
  }

  /// 0–1 progress between previous event and next prayer.
  double progress(DateTime now) {
    final a = previous(now).time, b = next(now).time;
    final total = b.difference(a).inSeconds;
    if (total <= 0) return 0;
    return (now.difference(a).inSeconds / total).clamp(0, 1);
  }
}
