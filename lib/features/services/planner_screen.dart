import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/domain/prayer_models.dart';
import '../prayer/prayer_providers.dart';
import 'service_widgets.dart';

/// A daily worship item. The five prayers carry their [PrayerKind].
class PlannerTask {
  const PlannerTask(this.id, this.ar, this.en, this.icon, {this.prayer});
  final String id, ar, en;
  final IconData icon;
  final PrayerKind? prayer;
}

const plannerTasks = <PlannerTask>[
  PlannerTask('fajr', 'صلاة الفجر', 'Fajr prayer', Icons.wb_twilight_rounded, prayer: PrayerKind.fajr),
  PlannerTask('dhuhr', 'صلاة الظهر', 'Dhuhr prayer', Icons.light_mode_outlined, prayer: PrayerKind.dhuhr),
  PlannerTask('asr', 'صلاة العصر', 'Asr prayer', Icons.wb_sunny_rounded, prayer: PrayerKind.asr),
  PlannerTask('maghrib', 'صلاة المغرب', 'Maghrib prayer', Icons.wb_twilight_rounded, prayer: PrayerKind.maghrib),
  PlannerTask('isha', 'صلاة العشاء', 'Isha prayer', Icons.dark_mode_outlined, prayer: PrayerKind.isha),
  PlannerTask('duha', 'صلاة الضحى', 'Duha prayer', Icons.wb_sunny_outlined),
  PlannerTask('witr', 'صلاة الوتر', 'Witr prayer', Icons.nightlight_outlined),
  PlannerTask('morning', 'أذكار الصباح', 'Morning adhkar', Icons.wb_sunny_outlined),
  PlannerTask('evening', 'أذكار المساء', 'Evening adhkar', Icons.wb_twilight_rounded),
  PlannerTask('quran', 'ورد القرآن', 'Quran reading', Icons.menu_book_rounded),
  PlannerTask('charity', 'صدقة', 'Charity', Icons.volunteer_activism_outlined),
];

const _fivePrayers = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

String plannerKey(DateTime d) => 'planner.${d.year}-${d.month}-${d.day}';

/// Completed task ids for the civil day of [date], persisted.
class PlannerDay extends Notifier<Set<String>> {
  PlannerDay(this.date);
  final DateTime date;

  @override
  Set<String> build() => (ref.watch(sharedPreferencesProvider).getStringList(plannerKey(date)) ?? const []).toSet();

  void toggle(String id) {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(plannerKey(date), next.toList());
  }
}

final plannerDayProvider = NotifierProvider.family<PlannerDay, Set<String>, DateTime>(PlannerDay.new);

/// Consecutive days up to and including [today] on which all five prayers
/// were ticked. Today does not break a streak while still incomplete.
int prayerStreak(DateTime today, Set<String> Function(DateTime) done) {
  var streak = 0;
  for (var i = 0; i < 365; i++) {
    final d = DateTime(today.year, today.month, today.day - i);
    final ok = done(d).containsAll(_fivePrayers);
    if (ok) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
}

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final today = ref.watch(todayProvider);
    final done = ref.watch(plannerDayProvider(today));
    final ctrl = ref.read(plannerDayProvider(today).notifier);
    final prefs = ref.watch(sharedPreferencesProvider);
    Set<String> of(DateTime d) => d == today ? done : (prefs.getStringList(plannerKey(d)) ?? const <String>[]).toSet();
    final streak = prayerStreak(today, of);
    final week = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i)];
    final pct = done.where(plannerTasks.map((e) => e.id).contains).length / plannerTasks.length;

    return ServiceScaffold(title: l.svcPlanner, children: [
      HeroSurface(
        radius: 28,
        child: Row(spacing: 16, children: [
          SizedBox.square(
            dimension: 78,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: pct, strokeWidth: 7, backgroundColor: const Color(0x29FFFFFF), color: NoorTokens.onHeroAccent, strokeCap: StrokeCap.round)),
              Text(ar ? '${NoorFormat.digits(context, (pct * 100).round())}٪' : '${(pct * 100).round()}%', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(NoorFormat.tr(context, 'عبادات اليوم', "Today's worship"), style: NoorText.display(context, size: 24, color: Colors.white)),
              Text(NoorFormat.tr(context, '${NoorFormat.digits(context, done.length)} من ${NoorFormat.digits(context, plannerTasks.length)} مكتملة', '${done.length} of ${plannerTasks.length} done'), style: const TextStyle(color: Color(0xD9FFFFFF))),
              Text(NoorFormat.tr(context, 'سلسلة الصلوات الخمس: ${NoorFormat.digits(context, streak)} يومًا', 'Five-prayer streak: $streak days'), style: const TextStyle(color: NoorTokens.onHeroAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      NoorCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(children: [
          for (final d in week)
            Expanded(
              child: Column(spacing: 6, children: [
                Text(NoorFormat.digits(context, d.day), style: TextStyle(fontSize: 12, fontWeight: d == today ? FontWeight.w800 : FontWeight.w500, color: d == today ? t.primary : t.textSecondary)),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: of(d).containsAll(_fivePrayers) ? t.primary : (of(d).isNotEmpty ? t.goldSoft : t.sunk),
                    border: of(d).isNotEmpty && !of(d).containsAll(_fivePrayers) ? Border.all(color: t.goldLine) : null,
                  ),
                  child: of(d).containsAll(_fivePrayers) ? Icon(Icons.check_rounded, size: 14, color: t.onPrimary) : null,
                ),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      for (final task in plannerTasks)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoorCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: done.contains(task.id) ? t.primarySoft : null,
            borderColor: done.contains(task.id) ? t.primaryLine : null,
            onTap: () {
              HapticFeedback.selectionClick();
              ctrl.toggle(task.id);
            },
            child: Row(spacing: 12, children: [
              IconBadge(icon: task.icon, size: 40, solid: done.contains(task.id)),
              Expanded(child: Text(ar ? task.ar : task.en, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, decoration: done.contains(task.id) ? TextDecoration.lineThrough : null, decorationColor: t.textSecondary, color: done.contains(task.id) ? t.textSecondary : t.text))),
              Icon(done.contains(task.id) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done.contains(task.id) ? t.primary : t.borderStrong),
            ]),
          ),
        ),
    ]);
  }
}
