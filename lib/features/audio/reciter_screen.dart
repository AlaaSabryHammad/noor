import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../quran/quran_data.dart';
import 'audio_catalog.dart';
import 'audio_home_screen.dart' show ListRow;
import 'audio_widgets.dart';
import 'quran_player.dart';
import 'video_screen.dart';

/// One reciter: choose a recording (riwaya) and play any surah or all of them.
class ReciterScreen extends ConsumerStatefulWidget {
  const ReciterScreen({super.key, required this.reciterId, this.moshafId});
  final int reciterId;

  /// Recording to open with (from a filtered list); else the last one picked.
  final int? moshafId;
  @override
  ConsumerState<ReciterScreen> createState() => _ReciterScreenState();
}

class _ReciterScreenState extends ConsumerState<ReciterScreen> {
  int? _moshafId;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _moshafId = widget.moshafId ?? ref.read(sharedPreferencesProvider).getInt('audio.moshaf.${widget.reciterId}');
  }

  void _pickMoshaf(int id) {
    setState(() => _moshafId = id);
    ref.read(sharedPreferencesProvider).setInt('audio.moshaf.${widget.reciterId}', id);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(audioCatalogProvider);
    final index = ref.watch(quranIndexProvider);
    return Scaffold(
      bottomNavigationBar: const MiniPlayerDock(),
      body: SafeArea(
        bottom: false,
        child: switch ((catalog, index)) {
          (AsyncData(value: final c), AsyncData(value: final idx)) => _body(context, c, c.reciter(widget.reciterId), idx.surahs),
          (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _body(BuildContext context, AudioCatalog catalog, QuranReciter? r, List<Surah> surahs) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    if (r == null) {
      return Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Align(alignment: AlignmentDirectional.centerStart, child: NoorBackButton())),
        Expanded(child: Center(child: Text(NoorFormat.tr(context, 'لم يُعثر على هذا القارئ.', 'Reciter not found.')))),
      ]);
    }
    final m = r.moshafById(_moshafId)!;
    final tracks = surahTracks(r, m, surahs);
    final q = _q.trim().toLowerCase();
    final shown = [
      for (var i = 0; i < tracks.length; i++)
        if (q.isEmpty || tracks[i].titleAr.contains(_q.trim()) || tracks[i].titleEn.toLowerCase().contains(q) || '${tracks[i].surah}' == NoorFormat.latinDigits(q)) i,
    ];
    final fav = ref.watch(audioFavoritesProvider.select((f) => f.contains('r:${r.id}')));
    final playerState = ref.watch(quranPlayerProvider);
    final player = ref.read(quranPlayerProvider.notifier);
    final fromThis = playerState.current?.reciterId == r.id && playerState.current?.moshafId == m.id;
    final byNumber = {for (final s in surahs) s.number: s};

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            const NoorBackButton(),
            const Spacer(),
            NoorIconButton(
              icon: fav ? Icons.star_rounded : Icons.star_outline_rounded,
              tooltip: fav ? NoorFormat.tr(context, 'إزالة من المفضلة', 'Remove from favourites') : NoorFormat.tr(context, 'أضف إلى المفضلة', 'Add to favourites'),
              onPressed: () => ref.read(audioFavoritesProvider.notifier).toggle('r:${r.id}'),
              child: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? t.gold : t.text, size: 22),
            ),
          ]),
          const SizedBox(height: 12),
          HeroSurface(
            child: Column(spacing: 12, children: [
              ReciterAvatar(name: r.nameAr, size: 84, onHero: true),
              Text(r.name(ar), textAlign: TextAlign.center, style: NoorText.display(context, size: 26, color: Colors.white)),
              Text(
                '${ar ? m.nameAr : m.nameEn} · ${NoorFormat.tr(context, '${NoorFormat.digits(context, m.surahs.length)} سورة', '${m.surahs.length} surahs')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: NoorTokens.onHeroAccent),
              ),
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF075E54), minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm))),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (fromThis) {
                      player.toggle();
                    } else {
                      player.playQueue(tracks);
                    }
                  },
                  icon: Icon(fromThis && playerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(fromThis ? (playerState.playing ? NoorFormat.tr(context, 'إيقاف مؤقت', 'Pause') : NoorFormat.tr(context, 'متابعة', 'Resume')) : NoorFormat.tr(context, 'تشغيل الكل', 'Play all')),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x66FFFFFF)), minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm))),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    player.playQueue([...tracks]..shuffle());
                  },
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(NoorFormat.tr(context, 'عشوائي', 'Shuffle')),
                ),
              ]),
            ]),
          ),
          if (r.moshaf.length > 1) ...[
            const SizedBox(height: 16),
            SectionTitle(NoorFormat.tr(context, 'التسجيلات والروايات', 'Recordings')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final x in r.moshaf)
                ChoiceChip(
                  label: Text('${ar ? x.nameAr : x.nameEn}${x.complete ? '' : ' (${NoorFormat.digits(context, x.surahs.length)})'}'),
                  selected: x.id == m.id,
                  showCheckmark: false,
                  onSelected: (_) => _pickMoshaf(x.id),
                  selectedColor: t.primary,
                  backgroundColor: t.surface,
                  labelStyle: TextStyle(color: x.id == m.id ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 12.5),
                  side: BorderSide(color: x.id == m.id ? t.primary : t.border),
                ),
            ]),
          ],
          if (catalog.videos.where((v) => v.reciterId == r.id).toList() case final videos when videos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionTitle(NoorFormat.tr(context, 'مرئيات', 'Videos')),
            const SizedBox(height: 10),
            VideoStrip(videos: videos, types: catalog.videoTypes, showReciter: false, padding: EdgeInsets.zero),
          ],
          const SizedBox(height: 16),
          NoorSearchField(hint: NoorFormat.tr(context, 'ابحث عن سورة', 'Search for a surah'), onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 12),
        ]),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        sliver: SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (context, j) {
            final i = shown[j];
            final track = tracks[i];
            final s = byNumber[track.surah];
            final current = playerState.current?.key == track.key;
            return ListRow(
              first: j == 0,
              last: j == shown.length - 1,
              onTap: () {
                HapticFeedback.selectionClick();
                if (current) {
                  player.toggle();
                } else if (fromThis) {
                  player.skipTo(i);
                } else {
                  player.playQueue(tracks, start: i);
                }
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 8, 9),
                child: Row(spacing: 12, children: [
                  EightPointStar(size: 38, color: t.gold, strokeWidth: .9, child: Text(NoorFormat.digits(context, track.surah!), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary))),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(track.title(ar), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: current ? t.primary : null)),
                      if (s != null) Text('${s.revelation == Revelation.meccan ? AppLocalizations.of(context).meccan : AppLocalizations.of(context).medinan} · ${AppLocalizations.of(context).ayahCount(NoorFormat.digits(context, s.ayahCount))}', style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                  if (current) PlayingBars(active: playerState.playing, color: t.gold) else Icon(Icons.play_circle_outline_rounded, color: t.primary, size: 28),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
