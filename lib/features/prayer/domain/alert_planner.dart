import '../../../l10n/app_localizations.dart';
import '../data/prayer_times_repository.dart';
import '../prayer_providers.dart' show prayerName;
import 'prayer_models.dart';

/// One adhan notification to schedule. [time] is an absolute instant.
class PlannedAlert {
  const PlannedAlert({required this.id, required this.kind, required this.time, required this.title, required this.body});
  final int id;
  final PrayerKind kind;
  final DateTime time;
  final String title, body;
}

/// iOS keeps at most 64 pending local notifications; 7 days × 5 prayers stays
/// well under that. The plan is rebuilt whenever the app opens or an input
/// (location, alerts, language) changes, so it never runs dry in normal use.
const alertHorizonDays = 7;

/// Upcoming alerts for the enabled prayers, soonest first. Pure: the same
/// inputs always give the same plan.
List<PlannedAlert> planAlerts({
  required PrayerTimesRepository repo,
  required PrayerLocation location,
  required Set<PrayerKind> enabled,
  required DateTime now,
  required AppLocalizations l,
  int days = alertHorizonDays,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final place = l.localeName == 'ar' ? location.nameAr : location.nameEn;
  final out = <PlannedAlert>[];
  for (var d = 0; d < days; d++) {
    final day = repo.dayFor(DateTime(today.year, today.month, today.day + d), location);
    for (final s in day.slots) {
      if (!s.kind.isPrayer || !enabled.contains(s.kind) || !s.time.isAfter(now)) continue;
      out.add(PlannedAlert(
        id: out.length,
        kind: s.kind,
        time: s.time,
        title: l.adhanNotifTitle(prayerName(l, s.kind, friday: day.isFriday)),
        body: place,
      ));
    }
  }
  return out;
}
