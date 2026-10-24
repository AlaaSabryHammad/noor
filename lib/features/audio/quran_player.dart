import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/providers.dart';
import '../settings/settings_controller.dart';
import 'system_audio.dart';

/// Something the app-wide player can play: a surah by a reciter or a live radio.
@immutable
class AudioTrack {
  const AudioTrack({required this.key, required this.titleAr, required this.titleEn, required this.subtitleAr, required this.subtitleEn, required this.url, this.surah, this.reciterId, this.moshafId, this.radioId});

  /// Stable identity, e.g. `s:123:45:2` (reciter, mushaf, surah) or `radio:109`.
  final String key;
  final String titleAr, titleEn, subtitleAr, subtitleEn;
  final Uri url;
  final int? surah, reciterId, moshafId, radioId;

  bool get live => radioId != null;
  String title(bool ar) => ar ? titleAr : titleEn;
  String subtitle(bool ar) => ar ? subtitleAr : subtitleEn;
}

enum ListenRepeat { off, one, all }

const listeningSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

@immutable
class PlayerSnapshot {
  const PlayerSnapshot({this.queue = const [], this.index = 0, this.playing = false, this.loading = false, this.failed = false, this.speed = 1, this.repeat = ListenRepeat.off, this.sleepAt, this.stopAfterTrack = false});
  final List<AudioTrack> queue;
  final int index;
  final bool playing, loading, failed;
  final double speed;
  final ListenRepeat repeat;

  /// Pause at this time (sleep timer), or at the end of the current track.
  final DateTime? sleepAt;
  final bool stopAfterTrack;

  AudioTrack? get current => index >= 0 && index < queue.length ? queue[index] : null;
  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;

  PlayerSnapshot copyWith({List<AudioTrack>? queue, int? index, bool? playing, bool? loading, bool? failed, double? speed, ListenRepeat? repeat, DateTime? Function()? sleepAt, bool? stopAfterTrack}) => PlayerSnapshot(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
        speed: speed ?? this.speed,
        repeat: repeat ?? this.repeat,
        sleepAt: sleepAt == null ? this.sleepAt : sleepAt(),
        stopAfterTrack: stopAfterTrack ?? this.stopAfterTrack,
      );
}

/// Streaming playback, behind an interface so screens can be tested without
/// audio hardware or network.
abstract interface class AudioBackend {
  Stream<bool> get playing;

  /// Index in the loaded list each time a track starts.
  Stream<int> get index;

  /// True while the source is loading or buffering.
  Stream<bool> get loading;

  /// The last track finished (and repeat is off).
  Stream<void> get completed;
  Stream<Object> get errors;
  Stream<Duration> get position;
  Stream<Duration?> get duration;
  Duration get currentPosition;

  /// Replaces the list. [arabic] picks the language of the titles shown by
  /// the system (lock screen, notification).
  Future<void> load(List<AudioTrack> tracks, {int index = 0, Duration position = Duration.zero, bool arabic = true});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position, {int? index});
  Future<void> setSpeed(double speed);
  Future<void> setRepeat(ListenRepeat mode);
  Future<void> dispose();
}

class JustAudioBackend implements AudioBackend {
  final _player = AudioPlayer();
  final _errors = StreamController<Object>.broadcast();
  bool _sessionReady = false;

  JustAudioBackend() {
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) => _errors.add(e));
  }

  @override
  Stream<bool> get playing => _player.playingStream;
  @override
  Stream<int> get index => _player.currentIndexStream.where((i) => i != null).cast<int>();
  @override
  Stream<bool> get loading => _player.processingStateStream.map((s) => s == ProcessingState.loading || s == ProcessingState.buffering);
  @override
  Stream<void> get completed => _player.processingStateStream.where((s) => s == ProcessingState.completed);
  @override
  Stream<Object> get errors => _errors.stream;
  @override
  Stream<Duration> get position => _player.positionStream;
  @override
  Stream<Duration?> get duration => _player.durationStream;
  @override
  Duration get currentPosition => _player.position;

  @override
  Future<void> load(List<AudioTrack> tracks, {int index = 0, Duration position = Duration.zero, bool arabic = true}) async {
    if (!_sessionReady) {
      // Long-form listening: keeps playing with the screen locked (iOS background mode "audio").
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _sessionReady = true;
    }
    final handler = await initSystemAudio(_player);
    final art = await artworkUri();
    handler?.setItems([
      for (final t in tracks) MediaItem(id: t.key, title: t.title(arabic), artist: t.subtitle(arabic), album: arabic ? 'نور' : 'NOOR', artUri: art, isLive: t.live),
    ], index);
    await _player.setAudioSources([for (final t in tracks) AudioSource.uri(t.url)], initialIndex: index, initialPosition: position);
  }

  @override
  Future<void> play() async => unawaited(_player.play());
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position, {int? index}) => _player.seek(position, index: index);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  @override
  Future<void> setRepeat(ListenRepeat mode) => _player.setLoopMode(switch (mode) {
        ListenRepeat.off => LoopMode.off,
        ListenRepeat.one => LoopMode.one,
        ListenRepeat.all => LoopMode.all,
      });

  @override
  Future<void> dispose() async {
    await _errors.close();
    await _player.dispose();
  }
}

/// Created on the first play, so merely opening the app never touches audio.
final audioBackendFactoryProvider = Provider<AudioBackend Function()>((ref) => JustAudioBackend.new);

/// Where listening stopped, so it can resume from the home and audio screens.
@immutable
class LastListen {
  const LastListen({this.reciterId, this.moshafId, this.surah, this.radioId, this.position = Duration.zero});
  final int? reciterId, moshafId, surah, radioId;
  final Duration position;

  Map<String, Object?> toJson() => {'r': reciterId, 'm': moshafId, 's': surah, 'radio': radioId, 'ms': position.inMilliseconds};
  static LastListen? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final l = LastListen(reciterId: j['r'] as int?, moshafId: j['m'] as int?, surah: j['s'] as int?, radioId: j['radio'] as int?, position: Duration(milliseconds: (j['ms'] as num?)?.toInt() ?? 0));
    return l.radioId != null || (l.reciterId != null && l.surah != null) ? l : null;
  }
}

class LastListenController extends Notifier<LastListen?> {
  static const _k = 'audio.last';

  @override
  LastListen? build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_k);
    if (raw == null) return null;
    try {
      return LastListen.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  void save(LastListen l) {
    state = l;
    ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(l.toJson()));
  }
}

final lastListenProvider = NotifierProvider<LastListenController, LastListen?>(LastListenController.new);

/// The app-wide player behind the mini player and the full player screen.
class QuranPlayer extends Notifier<PlayerSnapshot> {
  AudioBackend? _backend;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _sleep;

  @override
  PlayerSnapshot build() {
    ref.onDispose(() {
      _sleep?.cancel();
      for (final s in _subs) {
        s.cancel();
      }
      _backend?.dispose();
    });
    final p = ref.read(sharedPreferencesProvider);
    final speed = p.getDouble('audio.listenSpeed') ?? 1;
    return PlayerSnapshot(speed: listeningSpeeds.contains(speed) ? speed : 1, repeat: ListenRepeat.values.elementAtOrNull(p.getInt('audio.repeat') ?? 0) ?? ListenRepeat.off);
  }

  /// Position stream of the current track (empty until something plays).
  Stream<Duration> get position => _backend?.position ?? const Stream.empty();
  Stream<Duration?> get duration => _backend?.duration ?? const Stream.empty();

  AudioBackend get _b {
    final existing = _backend;
    if (existing != null) return existing;
    final b = _backend = ref.read(audioBackendFactoryProvider)();
    _subs.addAll([
      b.playing.listen((p) {
        state = state.copyWith(playing: p, failed: p ? false : null);
        if (!p) _remember();
      }),
      b.loading.listen((l) => state = state.copyWith(loading: l)),
      b.index.listen(_onIndex),
      b.completed.listen((_) {
        state = state.copyWith(playing: false);
        _remember(position: Duration.zero);
      }),
      b.errors.listen((e) {
        debugPrint('Playback error: $e');
        state = state.copyWith(failed: true, playing: false, loading: false);
      }),
    ]);
    return b;
  }

  void _onIndex(int i) {
    final previous = state.index;
    state = state.copyWith(index: i);
    if (state.stopAfterTrack && i != previous) {
      // "End of this surah": stop at the start of the next one.
      state = state.copyWith(stopAfterTrack: false, sleepAt: () => null);
      _b.pause();
    }
    _remember(position: Duration.zero);
  }

  void _remember({Duration? position}) {
    final t = state.current;
    if (t == null) return;
    ref.read(lastListenProvider.notifier).save(LastListen(
          reciterId: t.reciterId,
          moshafId: t.moshafId,
          surah: t.surah,
          radioId: t.radioId,
          position: t.live ? Duration.zero : (position ?? _backend?.currentPosition ?? Duration.zero),
        ));
  }

  /// Replaces the queue and starts at [start] (optionally part-way through it).
  Future<void> playQueue(List<AudioTrack> tracks, {int start = 0, Duration position = Duration.zero}) async {
    if (tracks.isEmpty) return;
    final i = start.clamp(0, tracks.length - 1);
    state = state.copyWith(queue: tracks, index: i, failed: false, loading: true);
    try {
      await _b.load(tracks, index: i, position: position, arabic: ref.read(settingsProvider).locale.languageCode == 'ar');
      // Loaded; any later buffering is reported by the backend's own stream.
      state = state.copyWith(loading: false);
      await _b.setSpeed(tracks[i].live ? 1 : state.speed);
      await _b.setRepeat(tracks[i].live ? ListenRepeat.off : state.repeat);
      await _b.play();
      _remember(position: position);
    } catch (e) {
      debugPrint('Playback failed: $e');
      state = state.copyWith(failed: true, playing: false, loading: false);
    }
  }

  bool isCurrent(String key) => state.current?.key == key;

  Future<void> toggle() async {
    if (state.current == null) return;
    if (state.playing) return pause();
    if (state.failed) return playQueue(state.queue, start: state.index);
    await _b.play();
  }

  Future<void> pause() async {
    if (_backend == null) return;
    await _b.pause();
  }

  Future<void> next() async {
    if (state.hasNext) await _b.seek(Duration.zero, index: state.index + 1);
  }

  /// Back to the start of the track, or to the previous one in its first seconds.
  Future<void> previous() async {
    if (state.current == null) return;
    final pos = _backend?.currentPosition ?? Duration.zero;
    if (pos > const Duration(seconds: 3) || !state.hasPrevious) return _b.seek(Duration.zero);
    await _b.seek(Duration.zero, index: state.index - 1);
  }

  Future<void> skipTo(int i) async {
    if (i < 0 || i >= state.queue.length) return;
    if (state.failed) return playQueue(state.queue, start: i);
    await _b.seek(Duration.zero, index: i);
    await _b.play();
  }

  Future<void> seek(Duration d) async {
    if (state.current?.live ?? true) return;
    await _b.seek(d);
  }

  Future<void> seekBy(Duration delta) async {
    final pos = (_backend?.currentPosition ?? Duration.zero) + delta;
    await seek(pos.isNegative ? Duration.zero : pos);
  }

  void cycleSpeed() {
    final next = listeningSpeeds[(listeningSpeeds.indexOf(state.speed) + 1) % listeningSpeeds.length];
    state = state.copyWith(speed: next);
    ref.read(sharedPreferencesProvider).setDouble('audio.listenSpeed', next);
    if (!(state.current?.live ?? true)) _backend?.setSpeed(next);
  }

  void cycleRepeat() {
    final next = ListenRepeat.values[(state.repeat.index + 1) % ListenRepeat.values.length];
    state = state.copyWith(repeat: next);
    ref.read(sharedPreferencesProvider).setInt('audio.repeat', next.index);
    if (!(state.current?.live ?? true)) _backend?.setRepeat(next);
  }

  /// Pauses after [after]; null cancels the timer.
  void setSleepTimer(Duration? after) {
    _sleep?.cancel();
    if (after == null) {
      state = state.copyWith(sleepAt: () => null, stopAfterTrack: false);
      return;
    }
    state = state.copyWith(sleepAt: () => DateTime.now().add(after), stopAfterTrack: false);
    _sleep = Timer(after, () {
      state = state.copyWith(sleepAt: () => null);
      pause();
    });
  }

  void sleepAtEndOfTrack() {
    _sleep?.cancel();
    state = state.copyWith(sleepAt: () => null, stopAfterTrack: true);
  }

  /// Stops and clears the queue (hides the mini player).
  Future<void> close() async {
    _sleep?.cancel();
    _remember();
    await _backend?.pause();
    state = PlayerSnapshot(speed: state.speed, repeat: state.repeat);
  }
}

final quranPlayerProvider = NotifierProvider<QuranPlayer, PlayerSnapshot>(QuranPlayer.new);

/// (position, duration) of the current track for progress bars.
final playerProgressProvider = StreamProvider<(Duration, Duration?)>((ref) {
  final key = ref.watch(quranPlayerProvider.select((s) => s.current?.key));
  if (key == null) return Stream.value((Duration.zero, null));
  final player = ref.read(quranPlayerProvider.notifier);
  Duration? dur;
  final c = StreamController<(Duration, Duration?)>();
  final subs = [
    player.duration.listen((d) {
      dur = d;
    }),
    player.position.listen((p) => c.add((p, dur))),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
    c.close();
  });
  return c.stream;
});
