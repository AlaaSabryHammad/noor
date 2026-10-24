import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/domain/prayer_models.dart';
import '../prayer/prayer_providers.dart';
import '../settings/settings_controller.dart';
import 'service_widgets.dart';

/// Fasting days ticked off for a Hijri year, persisted.
class FastingLog extends Notifier<Set<int>> {
  FastingLog(this.year);
  final int year;
  String get _k => 'ramadan.fasted.$year';

  @override
  Set<int> build() => (ref.watch(sharedPreferencesProvider).getStringList(_k) ?? const []).map(int.parse).toSet();

  void toggle(int day) {
    final next = {...state};
    next.contains(day) ? next.remove(day) : next.add(day);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_k, next.map((e) => '$e').toList());
  }
}

final fastingLogProvider = NotifierProvider.family<FastingLog, Set<int>, int>(FastingLog.new);

class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final now = ref.watch(nowProvider);
    final offset = ref.watch(settingsProvider.select((s) => s.hijriOffset));
    final h = NoorFormat.hijri(now, offsetDays: offset);
    final inRamadan = h.hMonth == 9;
    final targetYear = h.hMonth <= 9 ? h.hYear : h.hYear + 1;
    final start = HijriCalendar().hijriToGregorian(targetYear, 9, 1).subtract(Duration(days: offset));
    final daysLeft = DateTime(start.year, start.month, start.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final day = ref.watch(prayerDayProvider);
    final fajr = day.timeOf(PrayerKind.fajr), maghrib = day.timeOf(PrayerKind.maghrib);
    final fasted = ref.watch(fastingLogProvider(h.hYear));
    final fastedCtrl = ref.read(fastingLogProvider(h.hYear).notifier);
    final monthLen = HijriCalendar().getDaysInMonth(inRamadan ? h.hYear : targetYear, 9);
    // Remaining until the next fasting boundary: fajr (start) or maghrib (iftar).
    final fasting = now.isAfter(fajr) && now.isBefore(maghrib);
    final target = fasting ? maghrib : (now.isBefore(fajr) ? fajr : day.tomorrowFajr);

    return ServiceScaffold(title: l.svcRamadan, children: [
      HeroSurface(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          if (inRamadan) ...[
            Text(NoorFormat.tr(context, 'رمضان كريم', 'Ramadan Mubarak'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
            Text(NoorFormat.tr(context, 'اليوم ${NoorFormat.digits(context, h.hDay)} من ${NoorFormat.digits(context, monthLen)}', 'Day ${h.hDay} of $monthLen'), style: NoorText.display(context, size: 32, color: Colors.white)),
            NoorProgressBar(value: h.hDay / monthLen, height: 5, color: NoorTokens.onHeroAccent, track: const Color(0x29FFFFFF)),
            Row(children: [
              Expanded(child: _TimeCell(label: NoorFormat.tr(context, 'السحور حتى', 'Suhoor until'), time: NoorFormat.time(context, day.wall(fajr)))),
              Expanded(child: _TimeCell(label: NoorFormat.tr(context, 'الإفطار', 'Iftar'), time: NoorFormat.time(context, day.wall(maghrib)))),
            ]),
            Center(
              child: Column(spacing: 2, children: [
                Text(fasting ? NoorFormat.tr(context, 'المتبقي للإفطار', 'Until iftar') : NoorFormat.tr(context, 'المتبقي لبدء الصيام', 'Until the fast begins'), style: const TextStyle(fontSize: 11.5, color: Color(0xBFFFFFFF))),
                Directionality(textDirection: TextDirection.ltr, child: Text(NoorFormat.countdown(target.difference(now)), style: NoorText.numerals(size: 30))),
              ]),
            ),
          ] else ...[
            Text(NoorFormat.tr(context, 'يبدأ رمضان بعد', 'Ramadan begins in'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
            Text(NoorFormat.tr(context, '${NoorFormat.digits(context, daysLeft)} يومًا', '$daysLeft days'), style: NoorText.display(context, size: 38, color: Colors.white)),
            Text('${NoorFormat.digits(context, start.day)} ${NoorFormat.gregMonth(context, start.month)} ${NoorFormat.digits(context, start.year)} · ${NoorFormat.hijriMonth(context, 9)} ${NoorFormat.digits(context, targetYear)}', style: const TextStyle(color: Color(0xD9FFFFFF))),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'متتبع الصيام', 'Fasting tracker'), trailing: Text('${NoorFormat.digits(context, fasted.length)} / ${NoorFormat.digits(context, monthLen)}', style: Theme.of(context).textTheme.bodySmall)),
      const SizedBox(height: 10),
      NoorCard(
        padding: const EdgeInsets.all(14),
        child: GridView.count(
          crossAxisCount: NoorLayout.isWide(context) ? 10 : 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var d = 1; d <= monthLen; d++)
              Semantics(
                button: true,
                selected: fasted.contains(d),
                label: NoorFormat.tr(context, 'اليوم $d', 'Day $d'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    fastedCtrl.toggle(d);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fasted.contains(d) ? t.primary : (inRamadan && d == h.hDay ? t.goldSoft : t.sunk),
                      borderRadius: BorderRadius.circular(12),
                      border: inRamadan && d == h.hDay ? Border.all(color: t.gold) : null,
                    ),
                    child: fasted.contains(d) ? Icon(Icons.check_rounded, size: 18, color: t.onPrimary) : Text(NoorFormat.digits(context, d), style: TextStyle(fontWeight: FontWeight.w600, color: t.textSecondary)),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'خطة ختمة القرآن', 'Quran completion plan')),
      const SizedBox(height: 10),
      NoorCard(
        child: Row(spacing: 14, children: [
          const IconBadge(icon: Icons.menu_book_rounded, size: 46),
          Expanded(
            child: Text(
              NoorFormat.tr(context, 'لختمة في ${NoorFormat.digits(context, monthLen)} يومًا اقرأ نحو ${NoorFormat.digits(context, (604 / monthLen).ceil())} صفحة يوميًا (جزءًا واحدًا كل يوم تقريبًا).', 'To finish in $monthLen days, read about ${(604 / monthLen).ceil()} pages a day (roughly one juz).'),
              style: const TextStyle(height: 1.7),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'تذكير', 'Reminders')),
      const SizedBox(height: 10),
      for (final tip in [
        (Icons.nightlight_outlined, NoorFormat.tr(context, 'التماس ليلة القدر في الوتر من العشر الأواخر', 'Seek Laylat al-Qadr in the odd nights of the last ten')),
        (Icons.mosque_outlined, NoorFormat.tr(context, 'صلاة التراويح والقيام مع الجماعة', 'Taraweeh and night prayer in congregation')),
        (Icons.savings_outlined, NoorFormat.tr(context, 'زكاة الفطر قبل صلاة العيد', 'Zakat al-Fitr before the Eid prayer')),
        (Icons.volunteer_activism_outlined, NoorFormat.tr(context, 'الإكثار من الدعاء والصدقة وتفطير الصائمين', 'Supplicate often, give charity and feed the fasting')),
        (Icons.wb_twilight_outlined, NoorFormat.tr(context, 'السحور بركة: تأخيره وتعجيل الفطر على رطب أو تمر أو ماء', 'Suhoor is a blessing: delay it, and hasten iftar with dates or water')),
        (Icons.spa_outlined, NoorFormat.tr(context, 'حفظ اللسان والجوارح عن اللغو والغيبة والخصومة', 'Guard the tongue and limbs from idle talk, backbiting and quarrels')),
        (Icons.home_outlined, NoorFormat.tr(context, 'الاعتكاف في العشر الأواخر لمن تيسّر له', 'I‘tikaf in the last ten days for those able to')),
        (Icons.event_repeat_outlined, NoorFormat.tr(context, 'قضاء ما فاتك من أيام رمضان الماضي قبل قدوم الجديد', 'Make up any missed days of the previous Ramadan before the next one')),
        (Icons.calendar_today_outlined, NoorFormat.tr(context, 'صيام ست من شوال بعد عيد الفطر', 'Fast six days of Shawwal after Eid al-Fitr')),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoorCard(padding: const EdgeInsets.all(14), child: Row(spacing: 12, children: [IconBadge(icon: tip.$1, gold: true, size: 38), Expanded(child: Text(tip.$2, style: const TextStyle(height: 1.6)))])),
        ),
    ]);
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.label, required this.time});
  final String label, time;
  @override
  Widget build(BuildContext context) => Column(spacing: 2, children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xBFFFFFFF))),
        Text(time, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NoorTokens.onHeroAccent)),
      ]);
}
