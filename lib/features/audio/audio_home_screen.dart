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

enum AudioTab { reciters, radio, favorites }

/// Listening hub: every reciter on mp3quran.net (complete surahs in several
/// riwayat), live Quran and topic radios, and the person's favourites.
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
                  labels: [NoorFormat.tr(context, 'القرّاء', 'Reciters'), NoorFormat.tr(context, 'الإذاعات', 'Radio'), NoorFormat.tr(context, 'المفضلة', 'Favourites')],
                  selected: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
                const SizedBox(height: 14),
                if (_tab != AudioTab.favorites) ...[
                  NoorSearchField(
                    key: ValueKey(_tab),
                    hint: _tab == AudioTab.reciters ? NoorFormat.tr(context, 'ابحث عن قارئ', 'Search reciters') : NoorFormat.tr(context, 'ابحث عن إذاعة', 'Search stations'),
                    onChanged: (v) => setState(() => _q = v.trim()),
                  ),
                  const SizedBox(height: 12),
                ],
              ]),
            ),
            ...switch (_tab) {
              AudioTab.reciters => _reciterSlivers(context, c),
              AudioTab.radio => _radioSlivers(context, c),
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
    final list = c.reciters.where((r) {
      if (!_match(r.nameAr, r.nameEn)) return false;
      if (_riwaya == null) return true;
      if (_riwaya == -1) return r.riwayat.any((id) => !riwayaFilters.any((f) => f.$1 == id));
      return r.riwayat.contains(_riwaya);
    }).toList()
      ..sort((a, b) => a.name(ar).compareTo(b.name(ar)));
    return [
      if (_q.isEmpty && _riwaya == null)
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
          ]),
        ),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(spacing: 8, children: [
            for (final (id, nAr, nEn) in <(int?, String, String)>[(null, 'الكل', 'All'), ...riwayaFilters, (-1, 'روايات أخرى', 'Other riwayat')])
              _FilterChip(label: ar ? nAr : nEn, selected: _riwaya == id, onTap: () => setState(() => _riwaya = id)),
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
        sliver: SliverList.builder(itemCount: list.length, itemBuilder: (context, i) => _ReciterTile(reciter: list[i], first: i == 0, last: i == list.length - 1)),
      ),
    ];
  }

  List<Widget> _radioSlivers(BuildContext context, AudioCatalog c) {
    final thematic = c.radios.where((r) => r.thematic && _match(r.nameAr, r.nameEn)).toList();
    final reciters = c.radios.where((r) => !r.thematic && _match(r.nameAr, r.nameEn)).toList();
    Widget group(String title, List<QuranRadio> list) => SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          sliver: SliverMainAxisGroup(slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 10), child: SectionTitle(title))),
            SliverList.builder(itemCount: list.length, itemBuilder: (context, i) => _RadioTile(radio: list[i], first: i == 0, last: i == list.length - 1)),
          ]),
        );
    return [
      if (thematic.isEmpty && reciters.isEmpty) SliverToBoxAdapter(child: _Empty(text: NoorFormat.tr(context, 'لا نتائج', 'No results'))),
      if (thematic.isNotEmpty) group(NoorFormat.tr(context, 'إذاعات موضوعية', 'Topic stations'), thematic),
      if (reciters.isNotEmpty) group(NoorFormat.tr(context, 'إذاعات القرّاء', 'Reciter stations'), reciters),
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
    final ar = NoorFormat.isAr(context);
    final radio = last.radioId == null ? null : catalog.radio(last.radioId!);
    final reciter = last.reciterId == null ? null : catalog.reciter(last.reciterId!);
    final surah = index?.surahs.where((s) => s.number == last.surah).firstOrNull;
    final title = radio?.name(ar) ?? (surah == null ? '' : (ar ? 'سورة ${surah.nameAr}' : surah.nameEn));
    final subtitle = radio != null ? NoorFormat.tr(context, 'بث مباشر', 'Live') : reciter?.name(ar) ?? '';
    if (title.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HeroSurface(
        padding: const EdgeInsets.all(16),
        onTap: () => _resume(context, ref, last),
        child: Row(spacing: 14, children: [
          ReciterAvatar(name: radio?.nameAr ?? reciter?.nameAr ?? '', size: 52, onHero: true),
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
  const _ReciterTile({required this.reciter, required this.first, required this.last});
  final QuranReciter reciter;
  final bool first, last;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final fav = ref.watch(audioFavoritesProvider.select((f) => f.contains('r:${reciter.id}')));
    final playing = ref.watch(quranPlayerProvider.select((s) => s.playing && s.current?.reciterId == reciter.id));
    final m = reciter.moshaf.first;
    final extra = reciter.moshaf.length > 1 ? NoorFormat.tr(context, ' · ${NoorFormat.digits(context, reciter.moshaf.length)} تسجيلات', ' · ${reciter.moshaf.length} recordings') : '';
    return ListRow(
      first: first,
      last: last,
      onTap: () => context.push('/audio/reciter/${reciter.id}'),
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
          IconBadge(icon: radio.thematic ? Icons.podcasts_rounded : Icons.radio_rounded, gold: radio.thematic, size: 44),
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
