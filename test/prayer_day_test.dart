import 'package:flutter_test/flutter_test.dart';
import 'package:noor/features/prayer/data/prayer_times_repository.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';

void main() {
  const repo = AdhanPrayerTimesRepository();
  final day = repo.dayFor(DateTime(2026, 10, 23), PrayerLocation.dammam);

  test('six slots in chronological order', () {
    expect(day.slots.map((s) => s.kind), PrayerKind.values);
    for (var i = 1; i < day.slots.length; i++) {
      expect(day.slots[i].time.isAfter(day.slots[i - 1].time), isTrue);
    }
  });

  test('Umm al-Qura isha is maghrib + 90 minutes', () {
    expect(day.timeOf(PrayerKind.isha).difference(day.timeOf(PrayerKind.maghrib)).inMinutes, 90);
  });

  test('next skips sunrise; previous after sunrise is sunrise (Duha)', () {
    final afterSunrise = day.timeOf(PrayerKind.sunrise).add(const Duration(minutes: 30));
    expect(day.next(afterSunrise).kind, PrayerKind.dhuhr);
    expect(day.previous(afterSunrise).kind, PrayerKind.sunrise);
  });

  test('after isha the next prayer is tomorrow fajr', () {
    final late = day.timeOf(PrayerKind.isha).add(const Duration(minutes: 1));
    final n = day.next(late);
    expect(n.kind, PrayerKind.fajr);
    expect(n.time.isAfter(late), isTrue);
  });

  test('qibla bearing from Dammam is ~244°', () {
    expect(day.qiblaBearing, closeTo(244, 1.5));
  });

  test('23 Oct 2026 is a Friday', () => expect(day.isFriday, isTrue));
}
