import 'dart:math' as math;

import 'prayer_models.dart';

/// Asr shadow rule: [standard] = Shafi‘i / Maliki / Hanbali, [hanafi] = later Asr.
enum AsrMadhab { standard, hanafi }

/// The user's choice. A null [method] means "automatic": pick by location.
class PrayerCalcSettings {
  const PrayerCalcSettings({this.method, this.madhab = AsrMadhab.standard});
  final PrayerMethod? method;
  final AsrMadhab madhab;
}

/// Regional default for a place. Cities carry an explicit method; a GPS fix
/// borrows the nearest listed city within [maxKm], else the Muslim World League.
PrayerMethod methodFor(PrayerLocation loc, List<PrayerLocation> cities, {double maxKm = 800}) {
  if (loc.method != null) return loc.method!;
  PrayerLocation? best;
  var bestKm = double.infinity;
  for (final c in cities) {
    if (c.method == null) continue;
    final km = approxKm(loc.latitude, loc.longitude, c.latitude, c.longitude);
    if (km < bestKm) {
      bestKm = km;
      best = c;
    }
  }
  return best != null && bestKm <= maxKm ? best.method! : PrayerMethod.muslimWorldLeague;
}

/// Equirectangular distance; plenty for "which region is this".
double approxKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0, rad = math.pi / 180;
  final dx = (lng2 - lng1) * rad * math.cos((lat1 + lat2) / 2 * rad);
  final dy = (lat2 - lat1) * rad;
  return r * math.sqrt(dx * dx + dy * dy);
}
