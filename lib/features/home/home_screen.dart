import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../adhkar/adhkar_data.dart';
import '../library/favorites.dart';
import '../adhkar/adhkar_screen.dart' show adhkarTitle;
import '../prayer/domain/prayer_models.dart';
import '../prayer/location_sheet.dart';
import '../prayer/prayer_providers.dart';
import '../quran/quran_data.dart';
import '../settings/crash_consent_card.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Only the hour and the civil date matter here; the per-second clock is
    // watched by the hero card alone so the rest of the screen stays still.
    final hour = ref.watch(nowProvider.select((n) => n.hour));
    final today = ref.watch(todayProvider);
    final day = ref.watch(prayerDayProvider);
    final loc = ref.watch(prayerLocationProvider);
    final hijriOffset = ref.watch(settingsProvider.select((s) => s.hijriOffset));
    final t = context.noor;
    final greeting = day.isFriday ? l.greetingFriday : (hour < 12 ? l.greetingMorning : l.greetingEvening);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                InkWell(
                  onTap: () => showLocationSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                      Icon(Icons.location_on_outlined, size: 15, color: t.textSecondary),
                      Flexible(child: Text(NoorFormat.isAr(context) ? loc.nameAr : loc.nameEn, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                      Icon(Icons.expand_more_rounded, size: 16, color: t.textSecondary),
                    ]),
                  ),
                ),
                ScreenTitle(greeting),
                Text(NoorFormat.fullDateLine(context, today, hijriOffset: hijriOffset), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            const SizedBox(width: 12),
            Row(spacing: 8, children: [
              NoorIconButton(
                icon: Icons.translate,
                tooltip: l.language,
                onPressed: () => ref.read(settingsProvider.notifier).toggleLocale(),
                child: Text(NoorFormat.isAr(context) ? 'EN' : 'ع', style: TextStyle(fontWeight: FontWeight.w700, color: t.text, fontFamily: NoorFormat.isAr(context) ? NoorFonts.latinUi : NoorFonts.arabicUi)),
              ),
              NoorIconButton(
                icon: Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                tooltip: l.appearance,
                onPressed: () => ref.read(settingsProvider.notifier).toggleDark(Theme.of(context).brightness),
              ),
              NoorIconButton(icon: Icons.tune_rounded, tooltip: l.settings, onPressed: () => showSettingsSheet(context)),
            ]),
          ]),
          const SizedBox(height: 18),
          NextPrayerHero(day: day, method: ref.watch(effectiveMethodProvider)),
          const SizedBox(height: 16),
          const CrashConsentCard(), // one-time question; takes no space once answered
          if (day.isFriday) ...[_FridayCard(), const SizedBox(height: 16)],
          const _ContinueReadingCard(),
          const SizedBox(height: 18),
          SectionTitle(l.quickAccess),
          const SizedBox(height: 10),
          Row(spacing: 10, children: [
            Expanded(child: _QuickTile(icon: Icons.explore_outlined, label: l.svcQibla, onTap: () => context.push('/qibla'))),
            Expanded(child: _QuickTile(icon: Icons.blur_circular_rounded, label: l.svcTasbeeh, gold: true, onTap: () => context.push('/tasbeeh'))),
            Expanded(child: _QuickTile(icon: Icons.volunteer_activism_outlined, label: l.svcDuas, onTap: () => context.push('/duas'))),
            Expanded(child: _QuickTile(icon: Icons.calendar_month_outlined, label: l.svcCalendar, gold: true, onTap: () => context.push('/calendar'))),
          ]),
          const SizedBox(height: 18),
          const _MorningAdhkarCard(),
          const SizedBox(height: 16),
          const _DailyLightCard(),
        ],
      ),
    );
  }
}

/// The signature card: next prayer, live countdown, five-prayer strip.
class NextPrayerHero extends ConsumerWidget {
  const NextPrayerHero({super.key, required this.day, required this.method});
  final PrayerMethod method;
  final PrayerDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(nowProvider);
    final next = day.next(now);
    final prev = day.previous(now);
    final period = prev.kind == PrayerKind.sunrise ? l.duhaTime : l.timeOf(prayerName(l, prev.kind, friday: day.isFriday));
    return Semantics(
      label: '${l.nextPrayer}: ${prayerName(l, next.kind, friday: day.isFriday)} ${NoorFormat.time(context, day.wall(next.time))}',
      container: true,
      child: HeroSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
          Row(children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: NoorTokens.onHeroAccent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('${l.nextPrayer} · $period', style: const TextStyle(fontSize: 12.5, color: Color(0xD1FFFFFF)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(99)),
              child: Text(methodName(l, method), style: const TextStyle(fontSize: 11.5, color: Color(0xE6FFFFFF))),
            ),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prayerName(l, next.kind, friday: day.isFriday), style: NoorText.display(context, size: 40, color: Colors.white)),
                Text(NoorFormat.time(context, day.wall(next.time)), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NoorTokens.onHeroAccent)),
              ]),
            ),
            // Shrinks the figure on narrow screens instead of overflowing.
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(l.remaining, style: const TextStyle(fontSize: 11.5, color: Color(0xBFFFFFFF))),
                FittedBox(fit: BoxFit.scaleDown, child: Directionality(textDirection: TextDirection.ltr, child: Text(NoorFormat.countdown(next.time.difference(now)), style: NoorText.numerals()))),
              ]),
            ),
          ]),
          NoorProgressBar(value: day.progress(now), height: 4, color: NoorTokens.onHeroAccent, track: const Color(0x24FFFFFF)),
          Row(spacing: 4, children: [
            for (final s in day.slots.where((s) => s.kind.isPrayer))
              Expanded(child: _HeroPrayerCell(slot: s, shown: day.wall(s.time), isNext: s.kind == next.kind && next.time.day == s.time.day, past: !s.time.isAfter(now), friday: day.isFriday)),
          ]),
        ]),
      ),
    );
  }
}

class _HeroPrayerCell extends StatelessWidget {
  const _HeroPrayerCell({required this.slot, required this.shown, required this.isNext, required this.past, required this.friday});
  final PrayerSlot slot;
  final DateTime shown;
  final bool isNext, past, friday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = isNext ? NoorTokens.onHeroAccent : (past ? const Color(0x8CFFFFFF) : Colors.white);
    return AnimatedContainer(
      duration: NoorMotion.theme,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: isNext ? const Color(0x2EE0C486) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isNext ? const Color(0x73E0C486) : Colors.transparent),
      ),
      child: Column(spacing: 3, children: [
        Text(prayerName(l, slot.kind, friday: friday), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.fade),
        Text(NoorFormat.time(context, shown, withPeriod: false), style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }
}

class _FridayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return NoorCard(
      color: t.goldSoft,
      borderColor: t.goldLine,
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)), child: EightPointStar(size: 26, color: t.goldText, strokeWidth: 1.6)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
            Text(l.fridaySunnahTitle, style: TextStyle(fontSize: 12, color: t.goldText, fontWeight: FontWeight.w600)),
            Text(l.fridaySunnahBody, style: const TextStyle(fontSize: 14, height: 1.55)),
            const SizedBox(height: 8),
            NoorPrimaryButton(label: l.readKahf, onPressed: () => context.push('/quran/reader/18')),
          ]),
        ),
      ]),
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final progress = ref.watch(readingProgressProvider);
    final index = ref.watch(quranIndexProvider).value;
    final surah = index?.surahs.where((s) => s.number == progress.surah).firstOrNull;
    final pct = (progress.khatma * 100).round();
    return NoorCard(
      onTap: () => context.push('/quran/reader/${progress.surah}'),
      child: Row(spacing: 16, children: [
        SizedBox.square(
          dimension: 74,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(child: CircularProgressIndicator(value: progress.khatma, strokeWidth: 6, backgroundColor: t.border, color: t.primary, strokeCap: StrokeCap.round)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(NoorFormat.isAr(context) ? '${NoorFormat.digits(context, pct)}٪' : '$pct%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(l.khatma, style: TextStyle(fontSize: 10, color: t.textSecondary)),
            ]),
          ]),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
            Text(l.continueReading, style: Theme.of(context).textTheme.bodySmall),
            Text(surah == null ? '—' : (NoorFormat.isAr(context) ? 'سورة ${surah.nameAr}' : surah.nameEn), style: NoorText.display(context, size: 22)),
            Text(l.ayahOf(NoorFormat.digits(context, progress.ayah), NoorFormat.digits(context, surah?.ayahCount ?? 0)), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        NoorPrimaryButton(label: l.resume, onPressed: () => context.push('/quran/reader/${progress.surah}')),
      ]),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.onTap, this.gold = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gold;

  @override
  Widget build(BuildContext context) => NoorCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(spacing: 8, children: [
          IconBadge(icon: icon, gold: gold),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _MorningAdhkarCard extends ConsumerWidget {
  const _MorningAdhkarCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final cat = ref.watch(nowProvider).hour < 12 ? 'morning' : 'evening';
    final list = ref.watch(adhkarProvider(cat)).value ?? const <Dhikr>[];
    ref.watch(dhikrSessionProvider(cat));
    final ctrl = ref.read(dhikrSessionProvider(cat).notifier);
    final done = list.where((d) => ctrl.remaining(d) == 0).length;
    return NoorCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/adhkar/session/$cat'),
      child: Row(spacing: 14, children: [
        IconBadge(icon: cat == 'morning' ? Icons.wb_sunny_outlined : Icons.wb_twilight_rounded, size: 48),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Row(children: [
              Expanded(child: Text(adhkarTitle(context, cat), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Text(l.adhkarProgress(NoorFormat.digits(context, done), NoorFormat.digits(context, list.length)), style: Theme.of(context).textTheme.bodySmall),
            ]),
            NoorProgressBar(value: list.isEmpty ? 0 : done / list.length, color: t.gold),
          ]),
        ),
        NoorPrimaryButton(label: l.continueAction, soft: true, onPressed: () => context.push('/adhkar/session/$cat')),
      ]),
    );
  }
}

class _DailyLightCard extends ConsumerStatefulWidget {
  const _DailyLightCard();
  @override
  ConsumerState<_DailyLightCard> createState() => _DailyLightCardState();
}

class _DailyLightCardState extends ConsumerState<_DailyLightCard> {
  String _tab = 'ayah';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final item = dailyItemFor(ref.watch(dailyContentProvider).value, _tab, ref.watch(todayProvider));
    final ref_ = item == null ? '' : (NoorFormat.isAr(context) ? item.refAr : item.refEn);
    return NoorCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
        Row(children: [
          Expanded(child: SectionTitle(l.dailyLight)),
          SizedBox(width: 190, child: NoorSegmented<String>(values: const ['ayah', 'hadith', 'dua'], labels: [l.tabAyah, l.tabHadith, l.tabDua], selected: _tab, dense: true, onChanged: (v) => setState(() => _tab = v))),
        ]),
        if (item != null) ...[
          AnimatedSwitcher(
            duration: context.reduceMotion ? Duration.zero : NoorMotion.enter,
            child: Text(
              item.ar,
              key: ValueKey(_tab),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: item.quranic ? NoorText.quran(context, size: 22, color: t.text).copyWith(height: 2) : NoorText.display(context, size: 21).copyWith(height: 2, fontWeight: FontWeight.w400),
            ),
          ),
          Text(item.en, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13.5, height: 1.6, color: t.textSecondary, fontStyle: FontStyle.italic)),
          const Divider(),
          Row(children: [
            Expanded(child: Text(ref_, style: TextStyle(fontSize: 12, color: t.goldText, fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: l.copy,
              icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${item.ar}\n— $ref_'));
                showNoorSnack(context, l.copied);
              },
            ),
            SaveButton(item: SavedItem(key: 'daily:$_tab', kind: _tab, title: ref_, body: item.ar, translation: item.en, source: ref_), tooltip: l.save),
          ]),
        ],
      ]),
    );
  }
}
