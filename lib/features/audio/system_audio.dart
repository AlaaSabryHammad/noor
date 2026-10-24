import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Lock screen, Control Center, notification and headset controls for the
/// app-wide player, through audio_service. On Android this also runs the
/// player in a foreground service so long recitations keep playing in the
/// background.
class NoorAudioHandler extends BaseAudioHandler with SeekHandler {
  NoorAudioHandler(this._player) {
    _player.playbackEventStream.listen((_) => _broadcast(), onError: (Object _, StackTrace _) => _broadcast());
    _player.playingStream.listen((_) => _broadcast());
    _player.currentIndexStream.listen((i) {
      final items = queue.value;
      if (i != null && i < items.length) mediaItem.add(items[i]);
    });
    _player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (item != null && d != null && item.isLive != true) mediaItem.add(item.copyWith(duration: d));
    });
  }

  final AudioPlayer _player;

  bool get _live => mediaItem.value?.isLive ?? false;

  void _broadcast() {
    final live = _live;
    playbackState.add(PlaybackState(
      controls: [
        if (!live) MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        if (live) MediaControl.stop else MediaControl.skipToNext,
      ],
      systemActions: live ? const {} : const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: live ? Duration.zero : _player.position,
      bufferedPosition: live ? Duration.zero : _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  /// Called by the backend whenever a new list is loaded.
  void setItems(List<MediaItem> items, int index) {
    queue.add(items);
    if (index >= 0 && index < items.length) mediaItem.add(items[index]);
    _broadcast();
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) async {
    if (!_live) await _player.seek(position);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  /// Same rule as the in-app button: restart the surah in its first seconds' grace, else go back one.
  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3) || !_player.hasPrevious) return _player.seek(Duration.zero);
    await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Swiping the notification away, or "stop" on a live radio.
  @override
  Future<void> stop() async {
    await _player.pause();
    await super.stop();
  }
}

/// Sets up audio_service once per process. Returns null when the platform
/// cannot provide system controls; playback then works without them.
Future<NoorAudioHandler?> initSystemAudio(AudioPlayer player) => _init ??= () async {
      try {
        return await AudioService.init(
          builder: () => NoorAudioHandler(player),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'app.noor.noor.recitation',
            androidNotificationChannelName: 'Quran recitation',
            androidNotificationChannelDescription: 'Playback controls for recitations and radio',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            fastForwardInterval: Duration(seconds: 15),
            rewindInterval: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        debugPrint('System media controls unavailable: $e');
        return null;
      }
    }();

Future<NoorAudioHandler?>? _init;

/// The app icon as a file, so lock screens and notifications can show it.
Future<Uri?> artworkUri() => _artwork ??= () async {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/noor_artwork.jpg');
        if (!await file.exists()) {
          final data = await rootBundle.load('assets/icon/artwork.jpg');
          await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
        }
        return file.uri;
      } catch (_) {
        return null;
      }
    }();

Future<Uri?>? _artwork;
