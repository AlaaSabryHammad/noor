import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../khutab/khutab_data.dart';
import '../khutab/khutab_screens.dart' show KhutbaBlockView;
import '../prayer/prayer_providers.dart' show todayProvider;
import '../services/service_widgets.dart';
import '../settings/settings_controller.dart';

@immutable
class SpotlightAction {
  const SpotlightAction({required this.route, required this.labelAr, required this.labelEn});
  final String route, labelAr, labelEn;
  String label(bool ar) => ar ? labelAr : labelEn;
}

/// A themed page tied to a season of the Hijri year (or year-round).
@immutable
class Spotlight {
  const Spotlight({required this.id, required this.titleAr, required this.titleEn, required this.summaryAr, required this.summaryEn, required this.seasons, required this.blocks, required this.actions});
  final String id, titleAr, titleEn, summaryAr, summaryEn;

  /// (hijri month or 0 for every month, first day, last day).
  final List<(int, int, int)> seasons;
  final List<KhutbaBlock> blocks;
  final List<SpotlightAction> actions;

  bool get yearRound => seasons.isEmpty;
  String title(bool ar) => ar ? titleAr : titleEn;
  String summary(bool ar) => ar ? summaryAr : summaryEn;

  bool inSeason(int hMonth, int hDay) => seasons.any((s) => (s.$1 == 0 || s.$1 == hMonth) && hDay >= s.$2 && hDay <= s.$3);

  factory Spotlight.fromJson(Map<String, dynamic> j) => Spotlight(
        id: j['id'] as String,
        titleAr: j['titleAr'] as String,
        titleEn: j['titleEn'] as String,
        summaryAr: j['summaryAr'] as String,
        summaryEn: j['summaryEn'] as String,
        seasons: [for (final s in (j['seasons'] as List).cast<List>()) ((s[0] as num).toInt(), (s[1] as num).toInt(), (s[2] as num).toInt())],
        blocks: [for (final b in (j['blocks'] as List)) KhutbaBlock.fromJson(b as Map<String, dynamic>)],
        actions: [for (final a in (j['actions'] as List).cast<Map<String, dynamic>>()) SpotlightAction(route: a['route'] as String, labelAr: a['labelAr'] as String, labelEn: a['labelEn'] as String)],
      );
}

/// The spotlight for [date]: the first one in season (the list is in
/// priority order), otherwise a year-round topic that changes weekly.
Spotlight? spotlightFor(List<Spotlight> all, DateTime date, {int hijriOffset = 0}) {
  if (all.isEmpty) return null;
  final h = NoorFormat.hijri(date, offsetDays: hijriOffset);
  for (final s in all) {
    if (!s.yearRound && s.inSeason(h.hMonth, h.hDay)) return s;
  }
  final evergreen = all.where((s) => s.yearRound).toList();
  if (evergreen.isEmpty) return null;
  final week = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(2024, 1, 5)).inDays ~/ 7;
  return evergreen[week % evergreen.length];
}

final spotlightsProvider = FutureProvider<List<Spotlight>>((ref) async {
  final raw = await ref.watch(contentLoaderProvider)('assets/data/spotlights.json');
  return [for (final s in ((jsonDecode(raw) as Map<String, dynamic>)['spotlights'] as List)) Spotlight.fromJson(s as Map<String, dynamic>)];
});

/// Today's spotlight, following the Hijri date and the person's day adjustment.
final currentSpotlightProvider = Provider<Spotlight?>((ref) {
  final all = ref.watch(spotlightsProvider).value;
  if (all == null) return null;
  return spotlightFor(all, ref.watch(todayProvider), hijriOffset: ref.watch(settingsProvider.select((s) => s.hijriOffset)));
});

IconData spotlightIcon(String id) => switch (id) {
      'last-ten' || 'ramadan' => Icons.nightlight_round,
      'shawwal' || 'white-days' || 'muharram' => Icons.brightness_3_outlined,
      'dhulhijjah' => Icons.landscape_outlined,
      'shaban' => Icons.event_available_outlined,
      'sacred-months' => Icons.shield_moon_outlined,
      'salawat' => Icons.favorite_outline_rounded,
      'istighfar' => Icons.water_drop_outlined,
      _ => Icons.auto_awesome_outlined,
    };

/// Home card: today's spotlight in one line, opening the full page.
class SpotlightCard extends ConsumerWidget {
  const SpotlightCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(currentSpotlightProvider);
    if (s == null) return const SizedBox.shrink();
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: NoorCard(
        color: t.goldSoft,
        borderColor: t.goldLine,
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/spotlights/${s.id}'),
        child: Row(spacing: 14, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)), child: Icon(spotlightIcon(s.id), color: t.goldText)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Text(s.yearRound ? NoorFormat.tr(context, 'إضاءة الأسبوع', 'This week’s spotlight') : NoorFormat.tr(context, 'إضاءة الموسم', 'Seasonal spotlight'), style: TextStyle(fontSize: 12, color: t.goldText, fontWeight: FontWeight.w600)),
              Text(s.title(ar), style: NoorText.display(context, size: 19)),
              Text(s.summary(ar), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.5, color: t.textSecondary)),
            ]),
          ),
          Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: t.goldText),
        ]),
      ),
    );
  }
}

/// All spotlights; the one in season first.
class SpotlightsScreen extends ConsumerWidget {
  const SpotlightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = NoorFormat.isAr(context);
    final t = context.noor;
    final current = ref.watch(currentSpotlightProvider);
    return ServiceScaffold(title: NoorFormat.tr(context, 'الإضاءات', 'Spotlights'), children: [
      ref.watch(spotlightsProvider).when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('$e')),
            data: (all) {
              final ordered = [?current, ...all.where((s) => s.id != current?.id)];
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
                Text(NoorFormat.tr(context, 'صفحات موضوعية تتجدّد مع مواسم العام الهجري، تجمع الآيات والأحاديث وما يُشرع فيها.', 'Topic pages that follow the seasons of the Hijri year, gathering ayahs, hadith and what is recommended in them.'), style: TextStyle(color: t.textSecondary, height: 1.6)),
                for (final s in ordered)
                  NoorCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => context.push('/spotlights/${s.id}'),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
                      IconBadge(icon: spotlightIcon(s.id), gold: !s.yearRound, size: 46),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                          Row(children: [
                            Expanded(child: Text(s.title(ar), style: NoorText.display(context, size: 20))),
                            if (s.id == current?.id)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(99)),
                                child: Text(NoorFormat.tr(context, 'الآن', 'Now'), style: TextStyle(fontSize: 11, color: t.onPrimary, fontWeight: FontWeight.w700)),
                              ),
                          ]),
                          Text(s.summary(ar), style: TextStyle(fontSize: 13, height: 1.5, color: t.textSecondary)),
                        ]),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
    ]);
  }
}

class SpotlightScreen extends ConsumerWidget {
  const SpotlightScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = NoorFormat.isAr(context);
    final t = context.noor;
    final s = ref.watch(spotlightsProvider).value?.where((x) => x.id == id).firstOrNull;
    final fs = ref.watch(khutbaFontSizeProvider);
    return ServiceScaffold(title: NoorFormat.tr(context, 'إضاءة', 'Spotlight'), children: [
      if (s == null && ref.watch(spotlightsProvider).hasValue) Center(child: Text(NoorFormat.tr(context, 'لم يُعثر على هذه الإضاءة.', 'Spotlight not found.'))),
      if (s != null) ...[
        HeroSurface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Icon(spotlightIcon(s.id), color: NoorTokens.onHeroAccent, size: 30),
            Text(s.title(ar), style: NoorText.display(context, size: 28, color: Colors.white)),
            Text(s.summary(ar), style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xE6FFFFFF))),
          ]),
        ),
        const SizedBox(height: 18),
        for (final b in s.blocks) Padding(padding: const EdgeInsets.only(bottom: 14), child: KhutbaBlockView(block: b, ar: ar, fs: fs, translation: false)),
        if (s.actions.isNotEmpty) ...[
          const SizedBox(height: 4),
          SectionTitle(NoorFormat.tr(context, 'ابدأ الآن', 'Start now')),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in s.actions)
              ActionChip(
                avatar: Icon(Icons.arrow_outward_rounded, size: 16, color: t.primary),
                label: Text(a.label(ar)),
                labelStyle: TextStyle(color: t.primary, fontWeight: FontWeight.w600),
                backgroundColor: t.primarySoft,
                side: BorderSide.none,
                onPressed: () => context.push(a.route),
              ),
          ]),
        ],
        const SizedBox(height: 16),
        Text(NoorFormat.tr(context, 'الآيات منقولة من نص المصحف، والأحاديث معزوّة إلى مصادرها.', 'Ayahs are quoted from the mushaf text; every hadith cites its source.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    ]);
  }
}
