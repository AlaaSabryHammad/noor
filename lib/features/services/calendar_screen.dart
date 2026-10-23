import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'service_widgets.dart';

/// A recurring Islamic occasion, by Hijri month/day.
class IslamicEvent {
  const IslamicEvent(this.month, this.day, this.ar, this.en);
  final int month, day;
  final String ar, en;
}

const islamicEvents = <IslamicEvent>[
  IslamicEvent(1, 1, 'رأس السنة الهجرية', 'Islamic New Year'),
  IslamicEvent(1, 10, 'يوم عاشوراء', 'Day of ‘Ashura'),
  IslamicEvent(3, 12, 'المولد النبوي (على المشهور)', 'Mawlid an-Nabi (as commonly dated)'),
  IslamicEvent(7, 27, 'الإسراء والمعراج (على المشهور)', 'Isra and Mi‘raj (as commonly dated)'),
  IslamicEvent(9, 1, 'بداية شهر رمضان', 'First day of Ramadan'),
  IslamicEvent(9, 21, 'أول ليالي الوتر من العشر الأواخر', 'First odd night of the last ten'),
  IslamicEvent(9, 27, 'ليلة السابع والعشرين', 'The 27th night'),
  IslamicEvent(10, 1, 'عيد الفطر المبارك', 'Eid al-Fitr'),
  IslamicEvent(12, 8, 'يوم التروية', 'Day of Tarwiyah'),
  IslamicEvent(12, 9, 'يوم عرفة', 'Day of ‘Arafah'),
  IslamicEvent(12, 10, 'عيد الأضحى المبارك', 'Eid al-Adha'),
  IslamicEvent(12, 11, 'أيام التشريق (١١–١٣)', 'Days of Tashriq (11–13)'),
];

/// Events falling in a Hijri [month], including the monthly white days.
List<IslamicEvent> eventsOfMonth(int month) => [
      ...islamicEvents.where((e) => e.month == month),
      if (month != 9 && month != 12) IslamicEvent(month, 13, 'بداية الأيام البيض (١٣–١٥) — يُستحب صيامها', 'White days begin (13–15) — fasting recommended'),
    ]..sort((a, b) => a.day.compareTo(b.day));

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int? _y, _m;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final now = ref.watch(nowProvider);
    final offset = ref.watch(settingsProvider.select((s) => s.hijriOffset));
    final today = NoorFormat.hijri(now, offsetDays: offset);
    final y = _y ?? today.hYear, m = _m ?? today.hMonth;
    final cal = HijriCalendar();
    final days = cal.getDaysInMonth(y, m);
    final first = cal.hijriToGregorian(y, m, 1);
    final lead = first.weekday % 7; // Sunday = 0
    final isThisMonth = y == today.hYear && m == today.hMonth;
    final ar = NoorFormat.isAr(context);
    final dow = ar ? const ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final events = eventsOfMonth(m);
    final eventDays = events.map((e) => e.day).toSet();

    void step(int d) => setState(() {
          var nm = m + d, ny = y;
          if (nm > 12) {
            nm = 1;
            ny++;
          } else if (nm < 1) {
            nm = 12;
            ny--;
          }
          _y = ny.clamp(1356, 1500);
          _m = nm;
        });

    return ServiceScaffold(title: l.svcCalendar, children: [
      HeroSurface(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
        child: Row(children: [
          IconButton(tooltip: NoorFormat.tr(context, 'الشهر السابق', 'Previous month'), onPressed: () => step(-1), icon: const Icon(Icons.chevron_left_rounded, color: Colors.white)),
          Expanded(
            child: Column(spacing: 2, children: [
              Text('${NoorFormat.hijriMonth(context, m)} ${NoorFormat.digits(context, y)}', style: NoorText.display(context, size: 26, color: Colors.white)),
              Text('${NoorFormat.gregMonth(context, first.month)} ${NoorFormat.digits(context, first.year)} — ${NoorFormat.gregMonth(context, cal.hijriToGregorian(y, m, days).month)} ${NoorFormat.digits(context, cal.hijriToGregorian(y, m, days).year)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
            ]),
          ),
          IconButton(tooltip: NoorFormat.tr(context, 'الشهر التالي', 'Next month'), onPressed: () => step(1), icon: const Icon(Icons.chevron_right_rounded, color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 12),
      NoorCard(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        // Day cells have a fixed size, so their digits scale only a little.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Column(spacing: 6, children: [
          Row(children: [for (final d in dow) Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textSecondary))))]),
          for (var week = 0; week < ((lead + days) / 7).ceil(); week++)
            Row(children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: () {
                    final day = week * 7 + col - lead + 1;
                    if (day < 1 || day > days) return const SizedBox(height: 50);
                    final g = cal.hijriToGregorian(y, m, day);
                    final isToday = isThisMonth && day == today.hDay;
                    final isFriday = g.weekday == DateTime.friday;
                    return Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: isToday ? t.primary : (eventDays.contains(day) ? t.goldSoft : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: eventDays.contains(day) && !isToday ? Border.all(color: t.goldLine) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(NoorFormat.digits(context, day), style: TextStyle(height: 1.2, fontSize: 15, fontWeight: FontWeight.w700, color: isToday ? t.onPrimary : (isFriday ? t.primary : t.text))),
                        Text(NoorFormat.digits(context, g.day), style: TextStyle(height: 1.2, fontSize: 9.5, color: isToday ? t.onPrimary.withValues(alpha: .8) : t.textSecondary)),
                      ]),
                    );
                  }(),
                ),
            ]),
        ]),
        ),
      ),
      const SizedBox(height: 12),
      if (!isThisMonth)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(onPressed: () => setState(() => _y = _m = null), icon: const Icon(Icons.today_rounded, size: 18), label: Text(NoorFormat.tr(context, 'العودة إلى اليوم', 'Back to today'))),
        ),
      SectionTitle(NoorFormat.tr(context, 'المناسبات', 'Occasions')),
      const SizedBox(height: 8),
      for (final e in events)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoorCard(
            padding: const EdgeInsets.all(14),
            child: Row(spacing: 12, children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(14)),
                child: Text(NoorFormat.digits(context, e.day), style: TextStyle(fontWeight: FontWeight.w800, color: t.goldText)),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(ar ? e.ar : e.en, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5)),
                  Text(() {
                    final g = cal.hijriToGregorian(y, m, e.day);
                    return '${NoorFormat.digits(context, g.day)} ${NoorFormat.gregMonth(context, g.month)} ${NoorFormat.digits(context, g.year)}';
                  }(), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ]),
          ),
        ),
      Text(NoorFormat.tr(context, 'التقويم الهجري بحسب أم القرى، وقد يختلف يومًا عن رؤية الهلال المحلية.', 'Umm al-Qura calendar; local moon sighting may differ by a day.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
