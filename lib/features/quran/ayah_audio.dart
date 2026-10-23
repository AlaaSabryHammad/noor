import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/providers.dart';

class Reciter {
  const Reciter(this.id, this.ar, this.en);

  /// Folder name on everyayah.com (one MP3 per ayah: SSSAAA.mp3).
  final String id;
  final String ar, en;
}

const reciters = <Reciter>[
  Reciter('Alafasy_128kbps', 'مشاري راشد العفاسي', 'Mishary Rashid Alafasy'),
  Reciter('Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس', 'Abdurrahman As-Sudais'),
  Reciter('Saood_ash-Shuraym_128kbps', 'سعود الشريم', 'Saud Ash-Shuraym'),
  Reciter('MaherAlMuaiqly128kbps', 'ماهر المعيقلي', 'Maher Al-Muaiqly'),
  Reciter('Husary_128kbps', 'محمود خليل الحصري', 'Mahmoud Khalil Al-Husary'),
  Reciter('Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي', 'Mohamed Siddiq Al-Minshawi'),
  Reciter('Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد', 'Abdul Basit Abdus-Samad'),
  Reciter('Ghamadi_40kbps', 'سعد الغامدي', 'Saad Al-Ghamdi'),
];

String ayahAudioUrl(String reciterId, int surah, int ayah) => 'https://everyayah.com/data/$reciterId/${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

class ReciterController extends Notifier<String> {
  static const _k = 'quran.reciter';

  @override
  String build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_k);
    return reciters.any((r) => r.id == saved) ? saved! : reciters.first.id;
  }

  void select(String id) {
    state = id;
    ref.read(sharedPreferencesProvider).setString(_k, id);
  }
}

final reciterProvider = NotifierProvider<ReciterController, String>(ReciterController.new);

/// Ayah-by-ayah recitation. Behind an interface so the reader can be tested
/// without audio hardware or network.
abstract interface class AyahAudio {
  /// Ayah number each time one starts playing.
  Stream<int> get ayah;

  /// True while sound is playing (false when paused, finished or failed).
  Stream<bool> get playing;

  /// Emits when the last ayah finished.
  Stream<void> get completed;

  /// Emits a message when a track cannot be loaded (offline, missing file).
  Stream<Object> get errors;

  Future<void> start({required String reciterId, required int surah, required int fromAyah, required int total});
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

class JustAudioAyahAudio implements AyahAudio {
  final _player = AudioPlayer();
  final _ayah = StreamController<int>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  int _from = 1;
  late final List<StreamSubscription<Object?>> _subs;

  JustAudioAyahAudio() {
    _subs = [
      _player.currentIndexStream.listen((i) {
        if (i != null) _ayah.add(_from + i);
      }),
      _player.processingStateStream.listen((s) {
        if (s == ProcessingState.completed) _completed.add(null);
      }),
      _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) => _errors.add(e)),
    ];
  }

  @override
  Stream<int> get ayah => _ayah.stream;
  @override
  Stream<bool> get playing => _player.playingStream;
  @override
  Stream<void> get completed => _completed.stream;
  @override
  Stream<Object> get errors => _errors.stream;

  @override
  Future<void> start({required String reciterId, required int surah, required int fromAyah, required int total}) async {
    _from = fromAyah;
    try {
      await _player.setAudioSources([for (var a = fromAyah; a <= total; a++) AudioSource.uri(Uri.parse(ayahAudioUrl(reciterId, surah, a)))]);
      unawaited(_player.play());
    } catch (e) {
      _errors.add(e);
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async {
    unawaited(_player.play());
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _ayah.close();
    await _completed.close();
    await _errors.close();
    await _player.dispose();
  }
}

/// Creates the player when the reader first needs it. Override in tests.
final ayahAudioFactoryProvider = Provider<AyahAudio Function()>((ref) => JustAudioAyahAudio.new);
