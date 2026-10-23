import 'package:adhan/adhan.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';

import '../domain/prayer_method.dart';
import '../domain/prayer_models.dart';

abstract interface class PrayerTimesRepository {
  PrayerDay dayFor(DateTime date, PrayerLocation location);
}

adhan.CalculationMethod _toAdhan(PrayerMethod m) => switch (m) {
      PrayerMethod.ummAlQura => adhan.CalculationMethod.umm_al_qura,
      PrayerMethod.muslimWorldLeague => adhan.CalculationMethod.muslim_world_league,
      PrayerMethod.egyptian => adhan.CalculationMethod.egyptian,
      PrayerMethod.karachi => adhan.CalculationMethod.karachi,
      PrayerMethod.dubai => adhan.CalculationMethod.dubai,
      PrayerMethod.kuwait => adhan.CalculationMethod.kuwait,
      PrayerMethod.qatar => adhan.CalculationMethod.qatar,
      PrayerMethod.turkey => adhan.CalculationMethod.turkey,
      PrayerMethod.singapore => adhan.CalculationMethod.singapore,
      PrayerMethod.northAmerica => adhan.CalculationMethod.north_america,
      PrayerMethod.moonSighting => adhan.CalculationMethod.moon_sighting_committee,
    };

/// Fully offline calculation with the `adhan` package.
///
/// Umm al-Qura: Fajr 18.5°, Isha = Maghrib + 90 min, and + 120 min through
/// Ramadan as in the official Makkah calendar.
class AdhanPrayerTimesRepository implements PrayerTimesRepository {
  const AdhanPrayerTimesRepository({this.method = PrayerMethod.ummAlQura, this.madhab = AsrMadhab.standard});

  final PrayerMethod method;
  final AsrMadhab madhab;

  adhan.PrayerTimes _times(DateTime d, adhan.Coordinates c) {
    final params = _toAdhan(method).getParameters()..madhab = madhab == AsrMadhab.hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    if (method == PrayerMethod.ummAlQura && HijriCalendar.fromDate(d).hMonth == 9) params.adjustments.isha += 30;
    return adhan.PrayerTimes(c, adhan.DateComponents.from(d), params);
  }

  @override
  PrayerDay dayFor(DateTime date, PrayerLocation location) {
    final c = adhan.Coordinates(location.latitude, location.longitude);
    final day = DateTime(date.year, date.month, date.day);
    final t = _times(day, c);
    final tomorrow = _times(day.add(const Duration(days: 1)), c);
    final yesterday = _times(day.subtract(const Duration(days: 1)), c);
    DateTime l(DateTime x) => x.toLocal();
    return PrayerDay(
      date: day,
      slots: [
        PrayerSlot(PrayerKind.fajr, l(t.fajr)),
        PrayerSlot(PrayerKind.sunrise, l(t.sunrise)),
        PrayerSlot(PrayerKind.dhuhr, l(t.dhuhr)),
        PrayerSlot(PrayerKind.asr, l(t.asr)),
        PrayerSlot(PrayerKind.maghrib, l(t.maghrib)),
        PrayerSlot(PrayerKind.isha, l(t.isha)),
      ],
      tomorrowFajr: l(tomorrow.fajr),
      yesterdayIsha: l(yesterday.isha),
      qiblaBearing: adhan.Qibla(c).direction,
      displayOffset: location.utcOffset,
    );
  }
}
