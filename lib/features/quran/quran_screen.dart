import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'quran_data.dart';

enum _Seg { surahs, juz }

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  _Seg _seg = _Seg.surahs;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = ref.watch(quranIndexProvider);
    final progress = ref.watch(readingProgressProvider);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList.list(children: [
            ScreenTitle(l.quranTitle),
            const SizedBox(height: 14),
            NoorSearchField(hint: l.searchQuran, onChanged: (v) => setState(() => _query = v.trim())),
            const SizedBox(height: 16),
            HeroSurface(
              radius: 26,
              padding: const EdgeInsets.all(18),
              onTap: () => context.push('/quran/reader/${progress.surah}'),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                    Text(l.continueReading, style: const TextStyle(fontSize: 12, color: Color(0xC7FFFFFF))),
                    Text(
                      index.value?.surahs.where((s) => s.number == progress.surah).map((s) => NoorFormat.isAr(context) ? 'سورة ${s.nameAr}' : s.nameEn).firstOrNull ?? '—',
                      style: NoorText.display(context, size: 24, color: Colors.white),
                    ),
                  ]),
                ),
                const Icon(Icons.arrow_forward_rounded, color: NoorTokens.onHeroAccent),
              ]),
            ),
            const SizedBox(height: 16),
            NoorSegmented<_Seg>(values: _Seg.values, labels: [l.segSurahs, l.segJuz], selected: _seg, onChanged: (v) => setState(() => _seg = v)),
            const SizedBox(height: 14),
          ]),
        ),
        index.when(
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
          data: (data) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: _seg == _Seg.surahs ? _surahList(context, data.surahs) : _juzGrid(context, data.juz, data.surahs),
          ),
        ),
      ]),
    );
  }

  Widget _surahList(BuildContext context, List<Surah> all) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final q = _query;
    final list = q.isEmpty ? all : all.where((s) => s.nameAr.contains(q) || s.nameEn.toLowerCase().contains(q.toLowerCase()) || '${s.number}' == q).toList();
    return SliverToBoxAdapter(
      child: NoorCard(
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
              title: Text(NoorFormat.isAr(context) ? 'سورة ${list[i].nameAr}' : list[i].nameEn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${list[i].revelation == Revelation.meccan ? l.meccan : l.medinan} · ${l.ayahCount(NoorFormat.digits(context, list[i].ayahCount))} · ${l.pageN(NoorFormat.digits(context, list[i].startPage))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(list[i].nameAr, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: NoorFonts.quran, fontSize: 20, color: t.primary)),
            ),
          ],
        ]),
      ),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 104),
      itemCount: juz.length,
      itemBuilder: (context, i) => NoorCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/quran/reader/${juz[i].surah}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
          Text(l.juzN(NoorFormat.digits(context, juz[i].number)), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.goldText)),
          Text('${surahName(juz[i].surah)} ${NoorFormat.digits(context, juz[i].ayah)}', style: NoorText.display(context, size: 18)),
          Text(l.pageN(NoorFormat.digits(context, juz[i].page)), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
