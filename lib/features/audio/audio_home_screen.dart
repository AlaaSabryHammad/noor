import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../quran/quran_data.dart';
import 'audio_catalog.dart';
import 'audio_widgets.dart';
import 'quran_player.dart';
import 'video_screen.dart';

enum AudioTab { reciters, radio, lessons, favorites }

/// Listening hub: every reciter on mp3quran.net (complete surahs in several
/// riwayat and styles), live Quran radio, lessons (audio tafsir, series,
/// translations), recitation videos and the person's favourites.
class AudioHomeScreen extends ConsumerStatefulWidget {
  const AudioHomeScreen({super.key, this.initialTab = AudioTab.reciters});
  final AudioTab initialTab;
  @override
  ConsumerState<AudioHomeScreen> createState() => _AudioHomeScreenState();
}

class _AudioHomeScreenState extends ConsumerState<AudioHomeScreen> {
  late AudioTab _tab = widget.initialTab;
  String _q = '';
  int? _riwaya; // null = all, -1 = other
  RecitationStyle? _style; // null = all

  /// A recording that passes both filters.
  bool _moshafMatches(Moshaf m) {
    if (_style != null && m.style != _style) return false;
    if (_riwaya == null) return true;
    if (_riwaya == -1) return !riwayaFilters.any((f) => f.$1 == m.rewayaId);
    return m.rewayaId == _riwaya;
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll(' ', '');

  bool _match(String ar, String en) {
    if (_q.isEmpty) return true;
    final q = _norm(_q);
    return _norm(ar).contains(q) || _norm(en).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalog = ref.watch(audioCatalogProvider);
    return Scaffold(
      bottomNavigationBar: const MiniPlayerDock(),
      body: SafeArea(
        bottom: false,
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
          data: (c) => CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(children: [
                Row(children: [
                  const NoorBackButton(),
                  Expanded(child: Center(child: ScreenTitle(l.svcAudio, size: 22))),
                  NoorIconButton(icon: Icons.graphic_eq_rounded, tooltip: NoorFormat.tr(context, 'المشغّل', 'Player'), onPressed: () => context.push('/audio/player')),
                ]),
                const SizedBox(height: 14),
                const _ContinueCard(),
                NoorSegmented<AudioTab>(
                  values: AudioTab.values,
                  labels: [NoorFormat.tr(context, 'القرّاء', 'Reciters'), NoorFormat.tr(context, 'الإذاعات', 'Radio'), NoorFormat.tr(context, 'الدروس', 'Lessons'), NoorFormat.tr(context, 'المفضلة', 'Favourites')],
                  selected: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
                const SizedBox(height: 14),
                if (_tab != AudioTab.favorites) ...[
                  NoorSearchField(
                    key: ValueKey(_tab),
                    hint: switch (_tab) {
                      AudioTab.reciters => NoorFormat.tr(context, 'ابحث عن قارئ', 'Search reciters'),
                      AudioTab.lessons => NoorFormat.tr(context, 'ابحث عن سورة أو درس', 'Search a surah or a series'),
                      _ => NoorFormat.tr(context, 'ابحث عن إذاعة', 'Search stations'),
                    },
                    onChanged: (v) => setState(() => _q = v.trim()),
                  ),
                  const SizedBox(height: 12),
                ],
              ]),
            ),
            ...switch (_tab) {
              AudioTab.reciters => _reciterSlivers(context, c),
              AudioTab.radio => _radioSlivers(context, c),
              AudioTab.lessons => _lessonSlivers(context, c),
              AudioTab.favorites => _favoriteSlivers(context, c),
            },
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
                child: Text(NoorFormat.tr(context, 'التلاوات والإذاعات تُبثّ عبر الإنترنت من mp3quran.net.', 'Recitations and radio are streamed from mp3quran.net.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _reciterSlivers(BuildContext context, AudioCatalog c) {
    final ar = NoorFormat.isAr(context);
    final featured = [for (final id in featuredReciterIds) ?c.reciter(id)];
    final filtered = _riwaya != null || _style != null;
    final list = c.reciters.where((r) => _match(r.nameAr, r.nameEn) && (!filtered || r.moshaf.any(_moshafMatches))).toList()
      ..sort((a, b) => a.name(ar).compareTo(b.name(ar)));
    return [
      if (_q.isEmpty && !filtered)
        SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(NoorFormat.tr(context, 'قرّاء مختارون', 'Featured reciters'))),
            const SizedBox(height: 10),
            SizedBox(
              height: 112 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 78,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/audio/reciter/${featured[i].id}'),
                    child: Column(spacing: 6, children: [
                      ReciterAvatar(name: featured[i].nameAr, size: 62),
                      Text(featured[i].name(ar), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.25)),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (c.videos.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(NoorFormat.tr(context, 'مرئيات التلاوة', 'Recitation videos'))),
              const SizedBox(height: 10),
              VideoStrip(videos: c.videos, types: c.videoTypes),
              const SizedBox(height: 14),
            ],
          ]),
        ),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(spacing: 8, children: [
            for (final (id, nAr, nEn) in <(int?, String, String)>[(null, 'كل الروايات', 'All riwayat'), ...riwayaFilters, (-1, 'روايات أخرى', 'Other riwayat')])
              _FilterChip(label: ar ? nAr : nEn, selected: _riwaya == id, onTap: () => setState(() => _riwaya = id)),
          ]),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(spacing: 8, children: [
            _FilterChip(label: NoorFormat.tr(context, 'كل الأنواع', 'All styles'), selected: _style == null, onTap: () => setState(() => _style = null)),
            for (final st in RecitationStyle.values) _FilterChip(label: styleName(st, ar), selected: _style == st, onTap: () => setState(() => _style = st)),
          ]),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(child: Text(NoorFormat.tr(context, '${NoorFormat.digits(context, list.length)} قارئ', '${list.length} reciters'), style: Theme.of(context).textTheme.bodySmall)),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      if (list.isEmpty) SliverToBoxAdapter(child: _Empty(text: NoorFormat.tr(context, 'لا نتائج', 'No results'))),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: list.length,
          // With a filter on, open the reciter at the recording that matched it.
          itemBuilder: (context, i) => _ReciterTile(reciter: list[i], first: i == 0, last: i == list.length - 1, moshafId: filtered ? list[i].moshaf.firstWhere(_moshafMatches).id : null),
        ),
      ),
    ];
  }

  Widget _radioGroup(String title, List<QuranRadio> list) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        sliver: SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 10), child: SectionTitle(title))),
          SliverList.builder(itemCount: list.length, itemBuilder: (context, i) => _RadioTile(radio: list[i], first: i == 0, last: i == list.length - 1)),
        ]),
      );

  List<Widget> _radioSlivers(BuildContext context, AudioCatalog c) {
    final quran = c.radios.where((r) => r.kind == RadioKind.quran && _match(r.nameAr, r.nameEn)).toList();
    final reciters = c.radios.where((r) => r.kind == RadioKind.reciter && _match(r.nameAr, r.nameEn)).toList();
    return [
      if (quran.isEmpty && reciters.isEmpty) SliverToBoxAdapter(child: _Empty(text: NoorFormat.tr(context, 'لا نتائج', 'No results'))),
      if (quran.isNotEmpty) _radioGroup(NoorFormat.tr(context, 'إذاعات القرآن', 'Quran stations'), quran),
      if (reciters.isNotEmpty) _radioGroup(NoorFormat.tr(context, 'إذاعات القرّاء', 'Reciter stations'), reciters),
    ];
  }

  /// Audio tafsir by surah, lecture series and recited translations.
  List<Widget> _lessonSlivers(BuildContext context, AudioCatalog c) {
    final ar = NoorFormat.isAr(context);
    final surahs = ref.watch(quranIndexProvider).value?.surahs ?? const [];
    final withTafsir = [for (final s in surahs) if (c.tafsir.any((p) => p.surah == s.number) && _match('سورة ${s.nameAr}', s.nameEn)) s];
    final lessons = c.radios.where((r) => r.kind == RadioKind.lesson && _match(r.nameAr, r.nameEn)).toList();
    final translations = c.radios.where((r) => r.kind == RadioKind.translation && _match(r.nameAr, r.nameEn)).toList();
    return [
      if (withTafsir.isEmpty && lessons.isEmpty && translations.isEmpty) SliverToBoxAdapter(child: _Empty(text: NoorFormat.tr(context, 'لا نتائج', 'No results'))),
      if (withTafsir.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          sliver: SliverMainAxisGroup(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  SectionTitle(NoorFormat.tr(context, 'التفسير الصوتي', 'Audio tafsir')),
                  Text(ar ? c.tafsirName : 'A summary of Tafsir at-Tabari, in Arabic', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            SliverList.builder(
              itemCount: withTafsir.length,
              itemBuilder: (context, i) => _TafsirSurahTile(surah: withTafsir[i], parts: c.tafsirOf(withTafsir[i].number).length, first: i == 0, last: i == withTafsir.length - 1),
            ),
          ]),
        ),
      if (lessons.isNotEmpty) _radioGroup(NoorFormat.tr(context, 'سلاسل ودروس', 'Series and lessons'), lessons),
      if (translations.isNotEmpty) _radioGroup(NoorFormat.tr(context, 'ترجمات معاني القرآن', 'Translations of the meanings'), translations),
    ];
  }

  List<Widget> _favoriteSlivers(BuildContext context, AudioCatalog c) {
    final favs = ref.watch(audioFavoritesProvider);
    final reciters = [for (final k in favs) if (k.startsWith('r:')) ?c.reciter(int.tryParse(k.substring(2)) ?? -1)];
    final radios = [for (final k in favs) if (k.startsWith('radio:')) ?c.radio(int.tryParse(k.substring(6)) ?? -1)];
    if (reciters.isEmpty && radios.isEmpty) {
      return [SliverToBoxAdapter(child: _Empty(text: NoorFormat.tr(context, 'أضف قرّاءك وإذاعاتك المفضلة بالنجمة لتجدها هنا.', 'Star reciters and stations to keep them here.'), icon: Icons.star_outline_rounded))];
    }
    return [
      if (reciters.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          sliver: SliverList.builder(itemCount: reciters.length, itemBuilder: (context, i) => _ReciterTile(reciter: reciters[i], first: i == 0, last: i == reciters.length - 1)),
        ),
      if (radios.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          sliver: SliverList.builder(itemCount: radios.length, itemBuilder: (context, i) => _RadioTile(radio: radios[i], first: i == 0, last: i == radios.length - 1)),
        ),
    ];
  }
}

/// "Continue listening" while nothing is loaded in the player.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastListenProvider);
    final playing = ref.watch(quranPlayerProvider.select((s) => s.current != null));
    final catalog = ref.watch(audioCatalogProvider).value;
    final index = ref.watch(quranIndexProvider).value;
    if (last == null || playing || catalog == null) return const SizedBox.shrink();
    final d = describeLastListen(last, catalog, index?.surahs ?? const [], NoorFormat.isAr(context));
    if (d == null) return const SizedBox.shrink();
    final (:title, :subtitle, :avatar) = d;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HeroSurface(
        padding: const EdgeInsets.all(16),
        onTap: () => _resume(context, ref, last),
        child: Row(spacing: 14, children: [
          ReciterAvatar(name: avatar, size: 52, onHero: true),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Text(NoorFormat.tr(context, 'تابع الاستماع', 'Continue listening'), style: const TextStyle(fontSize: 12, color: Color(0xBFFFFFFF))),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: NoorText.display(context, size: 21, color: Colors.white)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent)),
            ]),
          ),
          IconButton.filled(
            tooltip: NoorFormat.tr(context, 'تشغيل', 'Play'),
            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF075E54), fixedSize: const Size(48, 48)),
            onPressed: () => _resume(context, ref, last),
            icon: const Icon(Icons.play_arrow_rounded, size: 30),
          ),
        ]),
      ),
    );
  }

  Future<void> _resume(BuildContext context, WidgetRef ref, LastListen last) async {
    HapticFeedback.lightImpact();
    final ok = await resumeListening(ref, last);
    if (!ok && context.mounted) showNoorSnack(context, NoorFormat.tr(context, 'لم يعد هذا التسجيل متاحًا.', 'This recording is no longer available.'));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: t.primary,
      backgroundColor: t.surface,
      labelStyle: TextStyle(color: selected ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 13),
      side: BorderSide(color: selected ? t.primary : t.border),
    );
  }
}

/// A row inside a continuous rounded list (first/last rows carry the corners).
class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.first, required this.last, required this.child, this.onTap});
  final bool first, last;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final r = BorderRadius.vertical(top: Radius.circular(first ? NoorRadius.card : 0), bottom: Radius.circular(last ? NoorRadius.card : 0));
    final side = BorderSide(color: t.border);
    return Container(
      decoration: BoxDecoration(color: t.surface, borderRadius: r, border: Border(left: side, right: side, top: first ? side : BorderSide.none, bottom: last ? side : BorderSide.none)),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(children: [
            if (!first) Divider(height: 1, indent: 16, endIndent: 16, color: t.border),
            child,
          ]),
        ),
      ),
    );
  }
}

class _ReciterTile extends ConsumerWidget {
  const _ReciterTile({required this.reciter, required this.first, required this.last, this.moshafId});
  final QuranReciter reciter;
  final bool first, last;

  /// Recording to open (the one a filter matched), else the reciter's default.
  final int? moshafId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final fav = ref.watch(audioFavoritesProvider.select((f) => f.contains('r:${reciter.id}')));
    final playing = ref.watch(quranPlayerProvider.select((s) => s.playing && s.current?.reciterId == reciter.id));
    final m = reciter.moshafById(moshafId)!;
    final extra = reciter.moshaf.length > 1 ? NoorFormat.tr(context, ' · ${NoorFormat.digits(context, reciter.moshaf.length)} تسجيلات', ' · ${reciter.moshaf.length} recordings') : '';
    return ListRow(
      first: first,
      last: last,
      onTap: () => context.push('/audio/reciter/${reciter.id}${moshafId == null ? '' : '?moshaf=$moshafId'}'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
        child: Row(spacing: 12, children: [
          ReciterAvatar(name: reciter.nameAr, size: 44),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Text(reciter.name(ar), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${ar ? m.nameAr : m.nameEn}$extra', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          if (playing) PlayingBars(active: true, color: t.gold),
          IconButton(
            tooltip: fav ? NoorFormat.tr(context, 'إزالة من المفضلة', 'Remove from favourites') : NoorFormat.tr(context, 'أضف إلى المفضلة', 'Add to favourites'),
            onPressed: () => ref.read(audioFavoritesProvider.notifier).toggle('r:${reciter.id}'),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? t.gold : t.textSecondary),
          ),
        ]),
      ),
    );
  }
}

class _RadioTile extends ConsumerWidget {
  const _RadioTile({required this.radio, required this.first, required this.last});
  final QuranRadio radio;
  final bool first, last;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final key = 'radio:${radio.id}';
    final current = ref.watch(quranPlayerProvider.select((s) => s.current?.key == key));
    final playing = ref.watch(quranPlayerProvider.select((s) => s.playing && s.current?.key == key));
    final fav = ref.watch(audioFavoritesProvider.select((f) => f.contains(key)));
    final player = ref.read(quranPlayerProvider.notifier);
    return ListRow(
      first: first,
      last: last,
      onTap: () {
        HapticFeedback.lightImpact();
        current ? player.toggle() : player.playQueue([radioTrack(radio)]);
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
        child: Row(spacing: 12, children: [
          IconBadge(
            icon: switch (radio.kind) {
              RadioKind.reciter => Icons.radio_rounded,
              RadioKind.quran => Icons.podcasts_rounded,
              RadioKind.lesson => Icons.school_outlined,
              RadioKind.translation => Icons.translate_rounded,
            },
            gold: radio.thematic,
            size: 44,
          ),
          Expanded(child: Text(radio.name(ar), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35))),
          if (current) PlayingBars(active: playing, color: t.gold),
          IconButton(
            tooltip: fav ? NoorFormat.tr(context, 'إزالة من المفضلة', 'Remove from favourites') : NoorFormat.tr(context, 'أضف إلى المفضلة', 'Add to favourites'),
            onPressed: () => ref.read(audioFavoritesProvider.notifier).toggle(key),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? t.gold : t.textSecondary),
          ),
        ]),
      ),
    );
  }
}

/// One surah of the audio tafsir; playing it continues into the next surahs.
class _TafsirSurahTile extends ConsumerWidget {
  const _TafsirSurahTile({required this.surah, required this.parts, required this.first, required this.last});
  final Surah surah;
  final int parts;
  final bool first, last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final current = ref.watch(quranPlayerProvider.select((s) => s.current?.tafsirId != null && s.current?.surah == surah.number));
    final playing = ref.watch(quranPlayerProvider.select((s) => s.playing)) && current;
    return ListRow(
      first: first,
      last: last,
      onTap: () {
        HapticFeedback.selectionClick();
        current ? ref.read(quranPlayerProvider.notifier).toggle() : playTafsir(ref, surah.number);
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 8, 9),
        child: Row(spacing: 12, children: [
          EightPointStar(size: 38, color: t.gold, strokeWidth: .9, child: Text(NoorFormat.digits(context, surah.number), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ar ? 'تفسير سورة ${surah.nameAr}' : 'Tafsir: ${surah.nameEn}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: current ? t.primary : null)),
              Text(parts > 1 ? NoorFormat.tr(context, '${NoorFormat.digits(context, parts)} مقاطع', '$parts parts') : NoorFormat.tr(context, 'مقطع واحد', 'One part'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          if (current) PlayingBars(active: playing, color: t.gold) else Icon(Icons.play_circle_outline_rounded, color: t.primary, size: 28),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 20),
      child: Column(spacing: 12, children: [
        if (icon != null) Icon(icon, size: 40, color: t.gold) else EightPointStar(size: 48, color: t.gold, strokeWidth: 1.3),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.7)),
      ]),
    );
  }
}
