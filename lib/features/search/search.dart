import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../adhkar/adhkar_data.dart' show hisnPrefix;
import '../adhkar/adhkar_screen.dart' show adhkarTitle;
import '../library/favorites.dart';
import '../library/share_image.dart';
import '../quran/quran_data.dart';

enum SearchKind { hadith, dhikr, hisn, name, faq, story, khutba, spotlight, lesson }

/// One searchable piece of bundled content.
@immutable
class SearchEntry {
  SearchEntry({required this.kind, required this.titleAr, required this.titleEn, required this.bodyAr, required this.bodyEn, required this.route, this.source = '', this.openDirectly = true})
      : _ar = normalizeArabic('$titleAr $bodyAr'),
        _en = '$titleEn $bodyEn'.toLowerCase(),
        _titleAr = normalizeArabic(titleAr),
        _titleEn = titleEn.toLowerCase();

  final SearchKind kind;
  final String titleAr, titleEn, bodyAr, bodyEn, route, source;

  /// Sections with a page per item open it; the rest show the text in a sheet first.
  final bool openDirectly;
  final String _ar, _en, _titleAr, _titleEn;

  String title(bool ar) => ar || titleEn.isEmpty ? titleAr : titleEn;
  String body(bool ar) => ar || bodyEn.isEmpty ? bodyAr : bodyEn;

  /// 2 = the title matches, 1 = the text matches, 0 = no match.
  int score(String qAr, String qEn) {
    if ((qAr.isNotEmpty && _titleAr.contains(qAr)) || (qEn.isNotEmpty && _titleEn.contains(qEn))) return 2;
    if ((qAr.isNotEmpty && _ar.contains(qAr)) || (qEn.isNotEmpty && _en.contains(qEn))) return 1;
    return 0;
  }
}

/// Matches across all entries, title hits first, at most [perKind] per section.
Map<SearchKind, List<SearchEntry>> searchEntries(List<SearchEntry> entries, String query, {int perKind = 12}) {
  final q = query.trim();
  if (q.runes.length < 2) return const {};
  final qAr = normalizeArabic(q), qEn = q.toLowerCase();
  final scored = <(SearchEntry, int)>[
    for (final e in entries)
      if (e.score(qAr, qEn) case final s when s > 0) (e, s),
  ]..sort((a, b) => b.$2 - a.$2);
  final out = <SearchKind, List<SearchEntry>>{};
  for (final (e, _) in scored) {
    final list = out.putIfAbsent(e.kind, () => []);
    if (list.length < perKind) list.add(e);
  }
  return out;
}

/// Everything the app ships offline, flattened for search (built once).
final searchIndexProvider = FutureProvider<List<SearchEntry>>((ref) async {
  final load = ref.watch(contentLoaderProvider);
  Future<dynamic> json(String name) async => jsonDecode(await load('assets/data/$name.json'));
  final out = <SearchEntry>[];
  String s(Object? v) => v as String? ?? '';

  final hadith = await json('hadith') as Map<String, dynamic>;
  for (final h in (hadith['items'] as List).cast<Map<String, dynamic>>()) {
    out.add(SearchEntry(kind: SearchKind.hadith, titleAr: s(h['sourceAr']), titleEn: s(h['sourceEn']), bodyAr: s(h['ar']), bodyEn: s(h['en']), route: '/hadith', source: s(h['sourceAr']), openDirectly: false));
  }
  final adhkar = await json('adhkar') as Map<String, dynamic>;
  for (final e in adhkar.entries.where((e) => e.value is List)) {
    for (final d in (e.value as List).cast<Map<String, dynamic>>()) {
      out.add(SearchEntry(kind: SearchKind.dhikr, titleAr: e.key, titleEn: e.key, bodyAr: s(d['ar']), bodyEn: s(d['en']), route: '/adhkar/session/${e.key}', source: s(d['sourceAr'])));
    }
  }
  final hisn = await json('hisn') as Map<String, dynamic>;
  for (final c in (hisn['categories'] as List).cast<Map<String, dynamic>>()) {
    final items = (c['items'] as List).cast<Map<String, dynamic>>();
    out.add(SearchEntry(kind: SearchKind.hisn, titleAr: s(c['titleAr']), titleEn: s(c['titleEn']), bodyAr: items.map((i) => s(i['ar'])).join(' '), bodyEn: '', route: '/adhkar/session/$hisnPrefix${c['id']}'));
  }
  final names = await json('names') as Map<String, dynamic>;
  for (final n in (names['names'] as List).cast<Map<String, dynamic>>()) {
    out.add(SearchEntry(kind: SearchKind.name, titleAr: s(n['ar']), titleEn: '${s(n['tr'])} — ${s(n['en'])}', bodyAr: s(n['meaningAr']), bodyEn: s(n['en']), route: '/names', openDirectly: false));
  }
  final faq = await json('faq') as Map<String, dynamic>;
  for (final f in (faq['items'] as List).cast<Map<String, dynamic>>()) {
    out.add(SearchEntry(kind: SearchKind.faq, titleAr: s(f['qAr']), titleEn: s(f['qEn']), bodyAr: s(f['aAr']), bodyEn: s(f['aEn']), route: '/ask', openDirectly: false));
  }
  final stories = await json('stories') as Map<String, dynamic>;
  for (final st in (stories['items'] as List).cast<Map<String, dynamic>>()) {
    out.add(SearchEntry(kind: SearchKind.story, titleAr: s(st['nameAr']), titleEn: s(st['nameEn']), bodyAr: s(st['bodyAr']), bodyEn: s(st['bodyEn']), route: '/stories', source: s(st['refAr']), openDirectly: false));
  }
  final khutab = await json('khutab') as Map<String, dynamic>;
  for (final k in (khutab['khutab'] as List).cast<Map<String, dynamic>>()) {
    final blocks = [for (final p in (k['parts'] as List).cast<Map<String, dynamic>>()) ...(p['blocks'] as List).cast<Map<String, dynamic>>()];
    out.add(SearchEntry(kind: SearchKind.khutba, titleAr: s(k['titleAr']), titleEn: s(k['titleEn']), bodyAr: '${s(k['summaryAr'])} ${blocks.map((b) => s(b['ar'])).join(' ')}', bodyEn: '${s(k['summaryEn'])} ${blocks.map((b) => s(b['en'])).join(' ')}', route: '/khutab/${k['id']}'));
  }
  final spots = await json('spotlights') as Map<String, dynamic>;
  for (final sp in (spots['spotlights'] as List).cast<Map<String, dynamic>>()) {
    final blocks = (sp['blocks'] as List).cast<Map<String, dynamic>>();
    out.add(SearchEntry(kind: SearchKind.spotlight, titleAr: s(sp['titleAr']), titleEn: s(sp['titleEn']), bodyAr: '${s(sp['summaryAr'])} ${blocks.map((b) => s(b['ar'])).join(' ')}', bodyEn: '${s(sp['summaryEn'])} ${blocks.map((b) => s(b['en'])).join(' ')}', route: '/spotlights/${sp['id']}'));
  }
  final academy = await json('academy') as Map<String, dynamic>;
  for (final c in (academy['courses'] as List).cast<Map<String, dynamic>>()) {
    final lessons = (c['lessons'] as List).cast<Map<String, dynamic>>();
    out.add(SearchEntry(kind: SearchKind.lesson, titleAr: s(c['titleAr']), titleEn: s(c['titleEn']), bodyAr: lessons.map((l) => '${s(l['titleAr'])} ${s(l['bodyAr'])}').join(' '), bodyEn: lessons.map((l) => '${s(l['titleEn'])} ${s(l['bodyEn'])}').join(' '), route: '/academy/${c['id']}'));
  }
  return out;
});

String searchKindTitle(BuildContext context, SearchKind k) => switch (k) {
      SearchKind.hadith => NoorFormat.tr(context, 'الأحاديث', 'Hadith'),
      SearchKind.dhikr => NoorFormat.tr(context, 'الأذكار والأدعية', 'Adhkar & duas'),
      SearchKind.hisn => NoorFormat.tr(context, 'حصن المسلم', 'Hisn al-Muslim'),
      SearchKind.name => NoorFormat.tr(context, 'الأسماء الحسنى', 'Names of Allah'),
      SearchKind.faq => NoorFormat.tr(context, 'أسئلة وأجوبة', 'Questions'),
      SearchKind.story => NoorFormat.tr(context, 'قصص الأنبياء', 'Stories'),
      SearchKind.khutba => NoorFormat.tr(context, 'الخطب', 'Sermons'),
      SearchKind.spotlight => NoorFormat.tr(context, 'الإضاءات', 'Spotlights'),
      SearchKind.lesson => NoorFormat.tr(context, 'الأكاديمية', 'Academy'),
    };

IconData _icon(SearchKind k) => switch (k) {
      SearchKind.hadith => Icons.receipt_long_outlined,
      SearchKind.dhikr => Icons.volunteer_activism_outlined,
      SearchKind.hisn => Icons.auto_stories_rounded,
      SearchKind.name => Icons.auto_awesome_outlined,
      SearchKind.faq => Icons.forum_outlined,
      SearchKind.story => Icons.auto_stories_outlined,
      SearchKind.khutba => Icons.record_voice_over_outlined,
      SearchKind.spotlight => Icons.wb_twilight_rounded,
      SearchKind.lesson => Icons.school_outlined,
    };

/// One search box over the Quran and every offline section of the app.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _field = TextEditingController(text: widget.initialQuery);
  late String _q = widget.initialQuery.trim();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final index = ref.watch(searchIndexProvider);
    final quran = _q.runes.length >= 2 ? ref.watch(quranSearchProvider(_q)) : null;
    final surahs = ref.watch(quranIndexProvider).value?.surahs ?? const [];
    final results = index.whenData((e) => searchEntries(e, _q)).value ?? const {};
    final ayahs = (quran?.value ?? const <SearchHit>[]).take(10).toList();
    final total = ayahs.length + results.values.fold(0, (s, l) => s + l.length);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverColumn(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverList.list(children: [
              Row(spacing: 10, children: [
                const NoorBackButton(),
                Expanded(
                  child: TextField(
                    controller: _field,
                    autofocus: widget.initialQuery.isEmpty,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _q = v.trim()),
                    decoration: InputDecoration(
                      hintText: NoorFormat.tr(context, 'ابحث في القرآن والأحاديث والأذكار والخطب…', 'Search the Quran, hadith, adhkar, sermons…'),
                      hintStyle: TextStyle(color: t.textSecondary, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: t.textSecondary, size: 20),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() {
                                _field.clear();
                                _q = '';
                              }),
                            ),
                      filled: true,
                      fillColor: t.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.primary, width: 1.5)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              if (_q.runes.length < 2)
                _Hint(text: NoorFormat.tr(context, 'اكتب كلمتين أو أكثر. البحث يتجاهل التشكيل ويعمل دون اتصال.', 'Type two letters or more. Search ignores diacritics and works offline.'))
              else if (total == 0 && !index.isLoading && !(quran?.isLoading ?? false))
                _Hint(text: NoorFormat.tr(context, 'لا نتائج لـ«$_q».', 'No results for “$_q”.'))
              else
                Text(NoorFormat.tr(context, '${NoorFormat.digits(context, total)} نتيجة', '$total results'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          if (ayahs.isNotEmpty)
            _Section(
              title: NoorFormat.tr(context, 'القرآن الكريم', 'The Quran'),
              children: [
                for (final h in ayahs)
                  _ResultTile(
                    icon: Icons.menu_book_outlined,
                    title: () {
                      final name = surahs.where((s) => s.number == h.surah).firstOrNull;
                      return ar ? '${name == null ? '' : 'سورة ${name.nameAr}'} · ${NoorFormat.digits(context, h.ayah)}' : '${name?.nameEn ?? ''} ${h.surah}:${h.ayah}';
                    }(),
                    body: ar ? h.ar : h.en,
                    quranic: ar,
                    onTap: () => context.push('/quran/reader/${h.surah}?ayah=${h.ayah}'),
                  ),
              ],
            ),
          for (final k in SearchKind.values)
            if (results[k] case final list? when list.isNotEmpty)
              _Section(
                title: searchKindTitle(context, k),
                children: [
                  for (final e in list)
                    _ResultTile(
                      icon: _icon(k),
                      title: k == SearchKind.dhikr ? adhkarTitle(context, e.titleAr) : e.title(ar),
                      body: e.body(ar),
                      onTap: () => e.openDirectly ? context.push(e.route) : _preview(context, e),
                    ),
                ],
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ]),
      ),
    );
  }

  void _preview(BuildContext context, SearchEntry e) {
    final ar = NoorFormat.isAr(context);
    final item = SavedItem(key: 'search:${e.kind.name}:${e.titleAr.hashCode}', kind: e.kind == SearchKind.hadith ? 'hadith' : 'search', title: e.title(ar), body: e.kind == SearchKind.name ? '${e.titleAr}\n${e.bodyAr}' : e.bodyAr, translation: e.bodyEn, source: e.source.isEmpty ? e.title(true) : e.source);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              Text(e.title(ar), style: Theme.of(ctx).textTheme.titleMedium),
              SelectableText(e.bodyAr, textDirection: TextDirection.rtl, style: NoorText.display(ctx, size: 19).copyWith(height: 1.9, fontWeight: FontWeight.w400)),
              if (e.bodyEn.isNotEmpty && e.bodyEn != e.bodyAr) Text(e.bodyEn, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13.5, height: 1.6, color: ctx.noor.textSecondary)),
              Row(children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push(e.route);
                    },
                    icon: Icon(_icon(e.kind), size: 18),
                    label: Text(searchKindTitle(ctx, e.kind)),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(ctx).copy,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.shareText));
                    showNoorSnack(ctx, AppLocalizations.of(ctx).copied);
                  },
                ),
                ShareImageButton(item: item, size: 24),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(spacing: 12, children: [
          EightPointStar(size: 52, color: context.noor.gold, strokeWidth: 1.3, child: Icon(Icons.search_rounded, color: context.noor.primary)),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.noor.textSecondary, height: 1.7)),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SliverColumn(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        sliver: SliverList.list(children: [
          SectionTitle(title, trailing: Text(NoorFormat.digits(context, children.length), style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 8),
          for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
        ]),
      );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.icon, required this.title, required this.body, required this.onTap, this.quranic = false});
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;
  final bool quranic;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return NoorCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
        IconBadge(icon: icon, size: 38),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.goldText)),
            Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: quranic ? NoorText.quran(context, size: 18).copyWith(height: 1.9) : const TextStyle(fontSize: 14, height: 1.6)),
          ]),
        ),
      ]),
    );
  }
}
