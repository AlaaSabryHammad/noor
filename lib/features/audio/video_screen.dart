import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import 'audio_catalog.dart';
import 'audio_widgets.dart' show formatDuration;
import 'quran_player.dart';

/// Horizontal row of recitation videos (thumbnail, category, reciter).
class VideoStrip extends StatelessWidget {
  const VideoStrip({super.key, required this.videos, required this.types, this.showReciter = true, this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<ReciterVideo> videos;
  final Map<int, String> types;
  final bool showReciter;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    return SizedBox(
      height: 112 + 50 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final v = videos[i];
          return SizedBox(
            width: 200,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/audio/video/${v.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 200,
                      height: 112,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(decoration: BoxDecoration(gradient: t.heroGradient)),
                          if (v.thumb.startsWith('https://')) Image.network(v.thumb, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                          const ColoredBox(color: Color(0x33000000)),
                          const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44)),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    videoTypeName(v.type, types[v.type] ?? '', ar),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: t.goldText, fontWeight: FontWeight.w600),
                  ),
                  if (showReciter)
                    Text(
                      v.reciterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen player for one recitation video.
class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key, required this.videoId});
  final int videoId;
  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  VideoPlayerController? _c;
  Object? _error;

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _open(ReciterVideo v) async {
    if (_c != null) return;
    // One voice at a time: the surah player pauses for the video.
    await ref.read(quranPlayerProvider.notifier).pause();
    final c = _c = VideoPlayerController.networkUrl(Uri.parse(v.url));
    c.addListener(() {
      if (mounted) setState(() {});
    });
    try {
      await c.initialize();
      await c.play();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = NoorFormat.isAr(context);
    final catalog = ref.watch(audioCatalogProvider).value;
    final v = catalog?.video(widget.videoId);
    if (v != null) WidgetsBinding.instance.addPostFrameCallback((_) => _open(v));
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const NoorBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v?.reciterName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NoorText.display(context, size: 20, color: Colors.white),
                        ),
                        if (v != null) Text(videoTypeName(v.type, catalog!.videoTypes[v.type] ?? '', ar), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _error != null || (v == null && catalog != null)
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          NoorFormat.tr(context, 'تعذّر تشغيل المقطع. تحقق من اتصالك بالإنترنت.', 'Couldn’t play this video. Check your internet connection.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, height: 1.7),
                        ),
                      )
                    : ready
                    ? GestureDetector(
                        onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                        child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            if (ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                // The progress bar does not mirror, so the whole timeline reads left to right.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    spacing: 6,
                    children: [
                      VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(playedColor: NoorTokens.onHeroAccent, bufferedColor: Color(0x55FFFFFF), backgroundColor: Color(0x22FFFFFF)),
                      ),
                      Row(
                        children: [
                          Text(
                            formatDuration(c.value.position),
                            style: const TextStyle(fontFamily: NoorFonts.latinUi, color: Colors.white70, fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton.filled(
                            tooltip: c.value.isPlaying ? NoorFormat.tr(context, 'إيقاف مؤقت', 'Pause') : NoorFormat.tr(context, 'تشغيل', 'Play'),
                            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, fixedSize: const Size(56, 56)),
                            onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                            icon: Icon(c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32),
                          ),
                          const Spacer(),
                          Text(
                            formatDuration(c.value.duration),
                            style: const TextStyle(fontFamily: NoorFonts.latinUi, color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
