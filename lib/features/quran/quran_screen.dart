import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'quran_data.dart';

enum _Seg { surahs, juz }

/// "2:255" / "2 255" / "2/255" → (2, 255).
(int, int)? parseAyahRef(String q) {
  final m = RegExp(r'^\s*(\d{1,3})\s*[:/ ]\s*(\d{1,3})\s*$').firstMatch(NoorFormat.latinDigits(q));
  if (m == null) return null;
  final s = int.parse(m[1]!), a = int.parse(m[2]!);
  return s >= 1 && s <= 114 && a >= 1 ? (s, a) : null;
}

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  _Seg _seg = _Seg.surahs;
  String _query = '';
  String _textQuery = ''; // debounced: drives the full-text ayah search
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    setState(() => _query = v.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _textQuery = _query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = ref.watch(quranIndexProvider);
    final progress = ref.watch(readingProgressProvider);
    final searching = _query.isNotEmpty;
    final ref_ = parseAyahRef(_query);
    final surahOf = index.value?.surahs.where((s) => s.number == progress.surah).firstOrNull;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverColumn(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList.list(children: [
            ScreenTitle(l.quranTitle),
            const SizedBox(height: 14),
            NoorSearchField(hint: l.searchQuran, onChanged: _onQuery),
            const SizedBox(height: 16),
            if (!searching) ...[
              HeroSurface(
                radius: 26,
                padding: const EdgeInsets.all(18),
                onTap: () => context.push('/quran/reader/${progress.surah}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                        Text(l.continueReading, style: const TextStyle(fontSize: 12, color: Color(0xC7FFFFFF))),
                        Text(surahOf == null ? '—' : (NoorFormat.isAr(context) ? 'سورة ${surahOf.nameAr}' : surahOf.nameEn), style: NoorText.display(context, size: 24, color: Colors.white)),
                        Text(l.ayahOf(NoorFormat.digits(context, progress.ayah), NoorFormat.digits(context, surahOf?.ayahCount ?? 0)), style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                      ]),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: NoorTokens.onHeroAccent),
                  ]),
                  NoorProgressBar(value: progress.khatma, height: 4, color: NoorTokens.onHeroAccent, track: const Color(0x24FFFFFF)),
                  Row(children: [
                    Expanded(
                      child: Text(
                        NoorFormat.tr(context, 'الختمة: ${NoorFormat.digits(context, progress.pagesRead)} من ٦٠٤ صفحة', 'Khatma: ${progress.pagesRead} of 604 pages'),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xCCFFFFFF)),
                      ),
                    ),
                    if (progress.pagesRead > 0)
                      InkWell(
                        onTap: () => _confirmReset(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(padding: const EdgeInsets.all(4), child: Text(NoorFormat.tr(context, 'ختمة جديدة', 'New khatma'), style: const TextStyle(fontSize: 11.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600))),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              NoorSegmented<_Seg>(values: _Seg.values, labels: [l.segSurahs, l.segJuz], selected: _seg, onChanged: (v) => setState(() => _seg = v)),
              const SizedBox(height: 14),
            ],
            if (ref_ != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoorCard(
                  onTap: () => context.push('/quran/reader/${ref_.$1}?ayah=${ref_.$2}'),
                  child: Row(spacing: 12, children: [
                    const IconBadge(icon: Icons.near_me_outlined, solid: true),
                    Expanded(child: Text(NoorFormat.tr(context, 'اذهب إلى السورة ${NoorFormat.digits(context, ref_.$1)}، الآية ${NoorFormat.digits(context, ref_.$2)}', 'Go to surah ${ref_.$1}, ayah ${ref_.$2}'), style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
          ]),
        ),
        index.when(
          loading: () => const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
          data: (data) => SliverColumn(
            padding: EdgeInsets.fromLTRB(20, 0, 20, NoorLayout.navClearance(context)),
            sliver: searching ? _searchResults(context, data) : (_seg == _Seg.surahs ? SliverToBoxAdapter(child: _surahCard(context, data.surahs, '')) : _juzGrid(context, data.juz, data.surahs)),
          ),
        ),
      ]),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(NoorFormat.tr(ctx, 'بدء ختمة جديدة؟', 'Start a new khatma?')),
        content: Text(NoorFormat.tr(ctx, 'سيُصفَّر عدّاد الصفحات المقروءة وتبقى علامة موضعك الحالي.', 'The pages-read counter resets; your bookmark stays.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(NoorFormat.tr(ctx, 'إلغاء', 'Cancel'))),
          FilledButton(
            onPressed: () {
              ref.read(readingProgressProvider.notifier).resetKhatma();
              Navigator.of(ctx).pop();
            },
            child: Text(NoorFormat.tr(ctx, 'ابدأ', 'Start')),
          ),
        ],
      ),
    );
  }

  /// Surah-name matches followed by full-text ayah matches.
  Widget _searchResults(BuildContext context, QuranIndex data) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final names = _surahCard(context, data.surahs, _query, hideWhenEmpty: true);
    final hits = _textQuery.runes.length >= 2 ? ref.watch(quranSearchProvider(_textQuery)) : null;
    String surahName(int n) => data.surahs.where((s) => s.number == n).map((s) => ar ? s.nameAr : s.nameEn).firstOrNull ?? '$n';

    return SliverList.list(children: [
      names,
      if (hits != null) ...[
        const SizedBox(height: 8),
        SectionTitle(NoorFormat.tr(context, 'في آيات القرآن', 'In the ayahs')),
        const SizedBox(height: 10),
        hits.when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
              ? Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(NoorFormat.tr(context, 'لا توجد آيات مطابقة', 'No matching ayahs'), style: TextStyle(color: t.textSecondary))))
              : Column(spacing: 10, children: [
                  for (final h in list)
                    NoorCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      onTap: () => context.push('/quran/reader/${h.surah}?ayah=${h.ayah}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: [
                        Text('${surahName(h.surah)} · ${NoorFormat.digits(context, h.ayah)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.goldText)),
                        Text(h.ar, maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: NoorText.quran(context, size: 19).copyWith(height: 2)),
                        Text(h.en, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 12.5, height: 1.5, color: t.textSecondary)),
                      ]),
                    ),
                ]),
        ),
      ],
    ]);
  }

  Widget _surahCard(BuildContext context, List<Surah> all, String q, {bool hideWhenEmpty = false}) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final needle = q.toLowerCase();
    final plain = normalizeArabic(q);
    final list = q.isEmpty ? all : all.where((s) => normalizeArabic(s.nameAr).contains(plain) || s.nameEn.toLowerCase().contains(needle) || '${s.number}' == q).toList();
    if (list.isEmpty && hideWhenEmpty) return const SizedBox.shrink();
    return NoorCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          ListTile(
            minTileHeight: 64,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => context.push('/quran/reader/${list[i].number}'),
            leading: EightPointStar(
              size: 40,
              color: t.gold,
              strokeWidth: .9,
              child: Text(NoorFormat.digits(context, list[i].number), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.primary)),
            ),
            title: Text(NoorFormat.isAr(context) ? 'سورة ${list[i].nameAr}' : list[i].nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${list[i].revelation == Revelation.meccan ? l.meccan : l.medinan} · ${l.ayahCount(NoorFormat.digits(context, list[i].ayahCount))} · ${l.pageN(NoorFormat.digits(context, list[i].startPage))}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(list[i].nameAr, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: NoorFonts.quran, fontSize: 20, color: t.primary))),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _juzGrid(BuildContext context, List<JuzInfo> juz, List<Surah> surahs) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    String surahName(int n) {
      final s = surahs.where((e) => e.number == n).firstOrNull;
      if (s == null) return '$n';
      return NoorFormat.isAr(context) ? s.nameAr : s.nameEn;
    }

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: NoorLayout.isWide(context) ? 3 : 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 104),
      itemCount: juz.length,
      itemBuilder: (context, i) => NoorCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/quran/reader/${juz[i].surah}?ayah=${juz[i].ayah}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
          Text(l.juzN(NoorFormat.digits(context, juz[i].number)), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.goldText)),
          Text('${surahName(juz[i].surah)} ${NoorFormat.digits(context, juz[i].ayah)}', style: NoorText.display(context, size: 18)),
          Text(l.pageN(NoorFormat.digits(context, juz[i].page)), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
