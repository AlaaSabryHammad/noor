import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import 'audio_catalog.dart';
import 'audio_widgets.dart';
import 'quran_player.dart';

/// Full-screen player: artwork, seek bar, transport, speed, repeat, sleep timer, queue.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranPlayerProvider);
    final track = s.current;
    final t = context.noor;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            Row(children: [
              NoorIconButton(icon: Icons.keyboard_arrow_down_rounded, tooltip: MaterialLocalizations.of(context).closeButtonTooltip, onPressed: () => Navigator.of(context).maybePop()),
              Expanded(child: Center(child: Text(NoorFormat.tr(context, 'يُتلى الآن', 'Now playing'), style: Theme.of(context).textTheme.titleMedium))),
              NoorIconButton(icon: Icons.queue_music_rounded, tooltip: NoorFormat.tr(context, 'قائمة التشغيل', 'Queue'), onPressed: track == null ? null : () => _showQueue(context, ref)),
            ]),
            Expanded(child: track == null ? _Idle() : _Playing(state: s, track: track)),
            if (track == null) const SizedBox.shrink() else _Tools(state: s, track: track),
            const SizedBox(height: 4),
            Text(NoorFormat.tr(context, 'يُبثّ من mp3quran.net', 'Streamed from mp3quran.net'), style: TextStyle(fontSize: 11, color: t.textSecondary)),
          ]),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final s = ref.watch(quranPlayerProvider);
        final ar = NoorFormat.isAr(ctx);
        final t = ctx.noor;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(NoorFormat.tr(ctx, 'قائمة التشغيل', 'Queue'), style: Theme.of(ctx).textTheme.titleMedium))),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: s.queue.length,
                  itemBuilder: (ctx, i) => ListTile(
                    selected: i == s.index,
                    selectedColor: t.primary,
                    leading: i == s.index ? PlayingBars(active: s.playing, color: t.gold) : Text(NoorFormat.digits(ctx, i + 1), style: TextStyle(color: t.textSecondary)),
                    title: Text(s.queue[i].title(ar), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(s.queue[i].subtitle(ar)),
                    onTap: () {
                      ref.read(quranPlayerProvider.notifier).skipTo(i);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _Idle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, spacing: 14, children: [
        EightPointStar(size: 84, color: t.gold, strokeWidth: 1.4, child: Icon(Icons.headphones_rounded, size: 34, color: t.primary)),
        Text(NoorFormat.tr(context, 'لا شيء قيد التشغيل', 'Nothing is playing'), style: NoorText.display(context, size: 24)),
        Text(NoorFormat.tr(context, 'اختر قارئًا أو إذاعة لتبدأ الاستماع.', 'Pick a reciter or a radio station to start listening.'), textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary)),
        NoorPrimaryButton(label: NoorFormat.tr(context, 'تصفّح القرّاء', 'Browse reciters'), onPressed: () => context.pushReplacement('/audio')),
      ]),
    );
  }
}

class _Playing extends ConsumerWidget {
  const _Playing({required this.state, required this.track});
  final PlayerSnapshot state;
  final AudioTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final player = ref.read(quranPlayerProvider.notifier);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final favKey = track.live ? 'radio:${track.radioId}' : 'r:${track.reciterId}';
    final fav = ref.watch(audioFavoritesProvider.select((f) => f.contains(favKey)));
    return LayoutBuilder(builder: (context, c) {
      final art = (c.maxHeight * .48).clamp(150.0, 320.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            const SizedBox(height: 8),
            SizedBox.square(
              dimension: art,
              child: HeroSurface(
                radius: 36,
                padding: EdgeInsets.zero,
                child: Center(
                  child: EightPointStar(
                    size: art * .78,
                    color: const Color(0x8CE0C486),
                    strokeWidth: 1.2,
                    child: Padding(
                      padding: EdgeInsets.all(art * .12),
                      child: FittedBox(
                        child: track.live
                            ? const Icon(Icons.radio_rounded, color: Colors.white, size: 64)
                            : Text(track.titleAr.replaceFirst('سورة ', ''), textDirection: TextDirection.rtl, style: NoorText.quran(context, size: 40, color: Colors.white).copyWith(height: 1.5)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(track.title(ar), maxLines: 2, overflow: TextOverflow.ellipsis, style: NoorText.display(context, size: 26)),
                  InkWell(
                    onTap: track.reciterId == null ? null : () => context.push('/audio/reciter/${track.reciterId}'),
                    child: Text(track.live ? NoorFormat.tr(context, 'إذاعة · بث مباشر', 'Radio · Live') : track.subtitle(ar), style: TextStyle(fontSize: 14, color: t.goldText, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              IconButton(
                tooltip: fav ? NoorFormat.tr(context, 'إزالة من المفضلة', 'Remove from favourites') : NoorFormat.tr(context, 'أضف إلى المفضلة', 'Add to favourites'),
                onPressed: () => ref.read(audioFavoritesProvider.notifier).toggle(favKey),
                icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, color: fav ? t.gold : t.textSecondary, size: 28),
              ),
            ]),
            const SizedBox(height: 10),
            if (track.live)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(spacing: 8, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: state.playing ? const Color(0xFFD64545) : t.textSecondary, shape: BoxShape.circle)),
                  Text(NoorFormat.tr(context, 'مباشر', 'LIVE'), style: TextStyle(fontWeight: FontWeight.w700, color: t.textSecondary, letterSpacing: .5)),
                  Expanded(child: state.playing ? LinearProgressIndicator(color: t.gold, backgroundColor: t.sunk, minHeight: 2) : const SizedBox()),
                ]),
              )
            else
              const _SeekBar(),
            if (state.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(NoorFormat.tr(context, 'تعذّر التشغيل. تحقق من اتصالك ثم اضغط تشغيل.', 'Couldn’t play. Check your connection, then press play.'), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _SmallToggle(
                tooltip: switch (state.repeat) {
                  ListenRepeat.off => NoorFormat.tr(context, 'التكرار متوقف', 'Repeat off'),
                  ListenRepeat.one => NoorFormat.tr(context, 'تكرار السورة', 'Repeat surah'),
                  ListenRepeat.all => NoorFormat.tr(context, 'تكرار القائمة', 'Repeat all'),
                },
                icon: state.repeat == ListenRepeat.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                on: state.repeat != ListenRepeat.off,
                onPressed: track.live ? null : player.cycleRepeat,
              ),
              IconButton(
                tooltip: NoorFormat.tr(context, 'السابق', 'Previous'),
                iconSize: 38,
                onPressed: track.live ? null : player.previous,
                icon: Icon(rtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded),
              ),
              SizedBox.square(
                dimension: 76,
                child: IconButton.filled(
                  tooltip: state.playing ? NoorFormat.tr(context, 'إيقاف مؤقت', 'Pause') : NoorFormat.tr(context, 'تشغيل', 'Play'),
                  style: IconButton.styleFrom(backgroundColor: t.primary, foregroundColor: t.onPrimary),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    player.toggle();
                  },
                  icon: state.loading && !state.failed ? SizedBox.square(dimension: 30, child: CircularProgressIndicator(strokeWidth: 3, color: t.onPrimary)) : Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 44),
                ),
              ),
              IconButton(
                tooltip: NoorFormat.tr(context, 'التالي', 'Next'),
                iconSize: 38,
                onPressed: track.live || !state.hasNext ? null : player.next,
                icon: Icon(rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded),
              ),
              _SmallToggle(
                tooltip: NoorFormat.tr(context, 'سرعة التلاوة', 'Playback speed'),
                label: '${state.speed == state.speed.roundToDouble() ? state.speed.toInt() : state.speed}×',
                on: state.speed != 1,
                onPressed: track.live ? null : player.cycleSpeed,
              ),
            ]),
            if (!track.live)
              Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 24, children: [
                TextButton.icon(
                  onPressed: () => player.seekBy(const Duration(seconds: -15)),
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: Text(NoorFormat.tr(context, '١٥ ث', '15 s')),
                ),
                TextButton.icon(
                  onPressed: () => player.seekBy(const Duration(seconds: 15)),
                  // The replay arrow mirrored: clockwise, i.e. forward.
                  icon: Transform.flip(flipX: true, child: const Icon(Icons.replay_rounded, size: 20)),
                  label: Text(NoorFormat.tr(context, '١٥ ث', '15 s')),
                ),
              ]),
          ]),
        ),
      );
    });
  }
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar();
  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final (pos, dur) = ref.watch(playerProgressProvider).value ?? (Duration.zero, null);
    final total = dur?.inMilliseconds ?? 0;
    final value = _drag ?? (total == 0 ? 0.0 : (pos.inMilliseconds / total).clamp(0.0, 1.0));
    final shown = _drag == null ? pos : Duration(milliseconds: (_drag! * total).round());
    return Column(children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), activeTrackColor: t.primary, inactiveTrackColor: t.sunk, thumbColor: t.primary),
        child: Slider(
          value: value,
          onChanged: total == 0 ? null : (v) => setState(() => _drag = v),
          onChangeEnd: total == 0
              ? null
              : (v) {
                  setState(() => _drag = null);
                  ref.read(quranPlayerProvider.notifier).seek(Duration(milliseconds: (v * total).round()));
                },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: Row(children: [
            Text(formatDuration(shown), style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 12, color: t.textSecondary)),
            const Spacer(),
            Text(dur == null ? '--:--' : formatDuration(dur), style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 12, color: t.textSecondary)),
          ]),
        ),
      ),
    ]);
  }
}

class _SmallToggle extends StatelessWidget {
  const _SmallToggle({required this.tooltip, required this.on, required this.onPressed, this.icon, this.label});
  final String tooltip;
  final bool on;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final color = onPressed == null ? t.border : (on ? t.primary : t.textSecondary);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: on && onPressed != null ? t.primarySoft : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 46,
            child: Center(child: icon != null ? Icon(icon, color: color, size: 24) : Text(label ?? '', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontWeight: FontWeight.w700, color: color, fontSize: 14))),
          ),
        ),
      ),
    );
  }
}

/// Sleep timer, "open in the mushaf" and the reciter page.
class _Tools extends ConsumerWidget {
  const _Tools({required this.state, required this.track});
  final PlayerSnapshot state;
  final AudioTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final now = ref.watch(nowProvider);
    final sleepLabel = state.stopAfterTrack
        ? NoorFormat.tr(context, 'نهاية السورة', 'End of surah')
        : state.sleepAt != null
            ? NoorFormat.digits(context, formatDuration(state.sleepAt!.difference(now).isNegative ? Duration.zero : state.sleepAt!.difference(now)))
            : NoorFormat.tr(context, 'مؤقت النوم', 'Sleep timer');
    final sleeping = state.stopAfterTrack || state.sleepAt != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(NoorRadius.md), border: Border.all(color: t.border)),
      child: Row(children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => _sleepSheet(context, ref),
            icon: Icon(Icons.bedtime_outlined, size: 20, color: sleeping ? t.gold : null),
            label: Text(sleepLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (track.surah != null)
          Expanded(
            child: TextButton.icon(
              onPressed: () => context.push('/quran/reader/${track.surah}'),
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: Text(NoorFormat.tr(context, 'اقرأ مع التلاوة', 'Read along'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ]),
    );
  }

  void _sleepSheet(BuildContext context, WidgetRef ref) {
    final player = ref.read(quranPlayerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(NoorFormat.tr(ctx, 'إيقاف التلاوة بعد', 'Stop playing after'), style: Theme.of(ctx).textTheme.titleMedium))),
          for (final m in const [10, 15, 30, 45, 60])
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(NoorFormat.tr(ctx, '${NoorFormat.digits(ctx, m)} دقيقة', '$m minutes')),
              onTap: () {
                player.setSleepTimer(Duration(minutes: m));
                Navigator.of(ctx).pop();
              },
            ),
          if (!track.live)
            ListTile(
              leading: const Icon(Icons.last_page_rounded),
              title: Text(NoorFormat.tr(ctx, 'نهاية السورة الحالية', 'End of this surah')),
              onTap: () {
                player.sleepAtEndOfTrack();
                Navigator.of(ctx).pop();
              },
            ),
          if (state.sleepAt != null || state.stopAfterTrack)
            ListTile(
              leading: Icon(Icons.close_rounded, color: Theme.of(ctx).colorScheme.error),
              title: Text(NoorFormat.tr(ctx, 'إلغاء المؤقت', 'Cancel timer')),
              onTap: () {
                player.setSleepTimer(null);
                Navigator.of(ctx).pop();
              },
            ),
        ]),
      ),
    );
  }
}
