import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../quran/quran_data.dart';
import 'audio_catalog.dart';
import 'quran_player.dart';

/// Surahs of [m] as player tracks; names come from the bundled Quran index.
List<AudioTrack> surahTracks(QuranReciter r, Moshaf m, List<Surah> surahs) {
  final byNumber = {for (final s in surahs) s.number: s};
  return [
    for (final n in m.surahs)
      AudioTrack(
        key: 's:${r.id}:${m.id}:$n',
        titleAr: 'سورة ${byNumber[n]?.nameAr ?? n}',
        titleEn: byNumber[n]?.nameEn ?? 'Surah $n',
        subtitleAr: r.nameAr,
        subtitleEn: r.nameEn,
        url: m.surahUrl(n),
        surah: n,
        reciterId: r.id,
        moshafId: m.id,
      ),
  ];
}

AudioTrack radioTrack(QuranRadio radio) => AudioTrack(
      key: 'radio:${radio.id}',
      titleAr: radio.nameAr,
      titleEn: radio.nameEn,
      subtitleAr: 'بث مباشر',
      subtitleEn: 'Live',
      url: Uri.parse(radio.url),
      radioId: radio.id,
    );

/// Picks up where [last] stopped: the same surah and position, or the same radio.
Future<bool> resumeListening(WidgetRef ref, LastListen last) async {
  final catalog = await ref.read(audioCatalogProvider.future);
  final player = ref.read(quranPlayerProvider.notifier);
  if (last.radioId != null) {
    final radio = catalog.radio(last.radioId!);
    if (radio == null) return false;
    await player.playQueue([radioTrack(radio)]);
    return true;
  }
  final reciter = catalog.reciter(last.reciterId ?? -1);
  final moshaf = reciter?.moshafById(last.moshafId);
  final index = await ref.read(quranIndexProvider.future);
  if (reciter == null || moshaf == null) return false;
  final tracks = surahTracks(reciter, moshaf, index.surahs);
  final start = tracks.indexWhere((t) => t.surah == last.surah);
  await player.playQueue(tracks, start: start < 0 ? 0 : start, position: start < 0 ? Duration.zero : last.position);
  return true;
}

/// Round monogram for a reciter: the first letter inside the eight-point star.
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({super.key, required this.name, this.size = 46, this.onHero = false});
  final String name;
  final double size;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final letter = name.replaceAll(RegExp(r'^(الشيخ|شيخ|ال)\s*'), '').characters.firstOrNull ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: onHero ? null : t.heroGradient,
        color: onHero ? const Color(0x24FFFFFF) : null,
      ),
      child: EightPointStar(
        size: size * .82,
        color: onHero ? NoorTokens.onHeroAccent : const Color(0x80E0C486),
        strokeWidth: .9,
        child: Text(letter, style: TextStyle(fontFamily: NoorFonts.display, fontSize: size * .36, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
      ),
    );
  }
}

/// Three bouncing bars marking the track that is playing.
class PlayingBars extends StatefulWidget {
  const PlayingBars({super.key, required this.active, this.color, this.size = 18});
  final bool active;
  final Color? color;
  final double size;

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlayingBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && !context.reduceMotion) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.noor.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final phase in const [0.0, .45, .8])
            Container(
              width: widget.size / 6,
              height: widget.size * (widget.active ? .3 + .7 * ((_c.value + phase) % 1.0) : .35),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
        ]),
      ),
    );
  }
}

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Compact player shown above the bottom navigation while something plays.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranPlayerProvider);
    final track = s.current;
    if (track == null) return const SizedBox.shrink();
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final player = ref.read(quranPlayerProvider.notifier);
    final progress = ref.watch(playerProgressProvider).value;
    final dur = progress?.$2;
    final value = track.live || dur == null || dur.inMilliseconds == 0 ? null : progress!.$1.inMilliseconds / dur.inMilliseconds;
    return Semantics(
      container: true,
      label: '${track.title(ar)} · ${track.subtitle(ar)}',
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: t.border)),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () => context.push('/audio/player'),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 2.5,
                child: value == null
                    ? (track.live && s.playing ? LinearProgressIndicator(color: t.gold, backgroundColor: t.sunk, minHeight: 2.5) : ColoredBox(color: t.sunk))
                    : LinearProgressIndicator(value: value.clamp(0, 1), color: t.primary, backgroundColor: t.sunk, minHeight: 2.5),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 4, 7),
                child: Row(spacing: 10, children: [
                  ReciterAvatar(name: track.live ? track.titleAr : track.subtitleAr, size: 40),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(track.title(ar), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                        s.failed ? NoorFormat.tr(context, 'تعذّر التشغيل — اضغط للمحاولة', 'Couldn’t play — tap to retry') : track.subtitle(ar),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: s.failed ? Theme.of(context).colorScheme.error : t.textSecondary),
                      ),
                    ]),
                  ),
                  if (s.loading && !s.failed)
                    SizedBox.square(dimension: 40, child: Padding(padding: const EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2.2, color: t.primary)))
                  else
                    IconButton(
                      tooltip: s.playing ? NoorFormat.tr(context, 'إيقاف مؤقت', 'Pause') : NoorFormat.tr(context, 'تشغيل', 'Play'),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        player.toggle();
                      },
                      icon: Icon(s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30, color: t.primary),
                    ),
                  if (!track.live && s.hasNext)
                    IconButton(
                      tooltip: NoorFormat.tr(context, 'التالي', 'Next'),
                      onPressed: player.next,
                      icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded, size: 26, color: t.text),
                    )
                  else
                    IconButton(
                      tooltip: NoorFormat.tr(context, 'إغلاق المشغّل', 'Close player'),
                      onPressed: player.close,
                      icon: Icon(Icons.close_rounded, size: 22, color: t.textSecondary),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Bottom area for the audio screens: the mini player with breathing room.
class MiniPlayerDock extends ConsumerWidget {
  const MiniPlayerDock({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(quranPlayerProvider.select((s) => s.current == null))) return const SizedBox.shrink();
    return SafeArea(minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: context.noor.cardShadow), child: const MiniPlayer()));
  }
}
