import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../books/books_data.dart' show BookFetcher, DiskTextCache, TextCache, bookFetcherProvider;

/// How a recording is read: the everyday murattal, the slower melodic
/// mujawwad, or the teaching mushaf (each ayah read, then a pause to repeat).
enum RecitationStyle { murattal, mujawwad, muallim, special }

/// mp3quran encodes the style in the last digit of `moshaf_type`.
RecitationStyle styleOf(int moshafType) => switch (moshafType % 10) {
      2 => RecitationStyle.mujawwad,
      3 => RecitationStyle.muallim,
      4 => RecitationStyle.special,
      _ => RecitationStyle.murattal,
    };

String styleName(RecitationStyle s, bool ar) => switch (s) {
      RecitationStyle.murattal => ar ? 'مرتّل' : 'Murattal',
      RecitationStyle.mujawwad => ar ? 'مجوّد' : 'Mujawwad',
      RecitationStyle.muallim => ar ? 'المصحف المعلّم' : 'Teaching mushaf',
      RecitationStyle.special => ar ? 'تلاوة مميزة' : 'Special recitation',
    };

/// One recording of the whole (or part of the) Quran by a reciter, in one riwaya.
@immutable
class Moshaf {
  const Moshaf({required this.id, required this.nameAr, required this.nameEn, required this.server, required this.surahs, required this.rewayaId, this.style = RecitationStyle.murattal});
  final int id;
  final String nameAr, nameEn;

  /// Folder URL; surah N is `${server}NNN.mp3`.
  final String server;
  final List<int> surahs;
  final int rewayaId;
  final RecitationStyle style;

  bool get complete => surahs.length == 114;
  Uri surahUrl(int surah) => Uri.parse('$server${surah.toString().padLeft(3, '0')}.mp3');
}

@immutable
class QuranReciter {
  const QuranReciter({required this.id, required this.nameAr, required this.nameEn, required this.moshaf});
  final int id;
  final String nameAr, nameEn;
  final List<Moshaf> moshaf;

  String name(bool ar) => ar ? nameAr : nameEn;
  Moshaf? moshafById(int? id) => moshaf.where((m) => m.id == id).firstOrNull ?? moshaf.firstOrNull;
  Set<int> get riwayat => {for (final m in moshaf) m.rewayaId};
}

/// What a radio station carries.
enum RadioKind {
  /// One reciter's recitations.
  reciter,

  /// General Quran streams: mixed reciters, a single surah, ruqyah, adhkar …
  quran,

  /// Lectures and series: tafsir, seerah, hadith collections, stories.
  lesson,

  /// Recited translations of the meanings.
  translation,
}

@immutable
class QuranRadio {
  const QuranRadio({required this.id, required this.nameAr, required this.nameEn, required this.url, this.kind = RadioKind.reciter});
  final int id;
  final String nameAr, nameEn, url;
  final RadioKind kind;

  bool get thematic => kind != RadioKind.reciter;
  String name(bool ar) => ar ? nameAr : nameEn;
}

/// One part of the audio tafsir: a whole surah or a range of its ayahs.
@immutable
class TafsirPart {
  const TafsirPart({required this.id, required this.surah, required this.from, required this.to, required this.url});
  final int id, surah;

  /// Ayah range; `to == 0` means the whole surah.
  final int from, to;
  final String url;

  bool get wholeSurah => to == 0;
  bool covers(int ayah) => wholeSurah || (ayah >= from && ayah <= to);
}

@immutable
class ReciterVideo {
  const ReciterVideo({required this.id, required this.reciterId, required this.reciterName, required this.type, required this.url, required this.thumb});
  final int id, reciterId, type;
  final String reciterName, url, thumb;
}

@immutable
class AudioCatalog {
  const AudioCatalog({required this.reciters, required this.radios, this.tafsirName = '', this.tafsir = const [], this.videos = const [], this.videoTypes = const {}});
  final List<QuranReciter> reciters;
  final List<QuranRadio> radios;

  /// Audio tafsir in reading order (surah, then ayah range).
  final String tafsirName;
  final List<TafsirPart> tafsir;
  final List<ReciterVideo> videos;

  /// Arabic names of the video categories by id.
  final Map<int, String> videoTypes;

  QuranReciter? reciter(int id) => reciters.where((r) => r.id == id).firstOrNull;
  QuranRadio? radio(int id) => radios.where((r) => r.id == id).firstOrNull;
  ReciterVideo? video(int id) => videos.where((v) => v.id == id).firstOrNull;
  List<TafsirPart> tafsirOf(int surah) => [for (final p in tafsir) if (p.surah == surah) p];

  /// Index in [tafsir] of the part that explains [ayah] of [surah].
  int tafsirIndexFor(int surah, int ayah) {
    final i = tafsir.indexWhere((p) => p.surah == surah && p.covers(ayah));
    return i >= 0 ? i : tafsir.indexWhere((p) => p.surah == surah);
  }

  /// Parses the mp3quran.net v3 responses (`reciters` / `radios`, Arabic and English;
  /// `tafsir` and `videos` optional).
  factory AudioCatalog.fromApi({
    required List<dynamic> recitersAr,
    required List<dynamic> recitersEn,
    required List<dynamic> radiosAr,
    required List<dynamic> radiosEn,
    Map<String, dynamic>? tafsir,
    List<dynamic> videos = const [],
    List<dynamic> videoTypes = const [],
  }) {
    final enReciters = {for (final r in recitersEn.cast<Map<String, dynamic>>()) r['id'] as int: r};
    final reciters = <QuranReciter>[];
    for (final r in recitersAr.cast<Map<String, dynamic>>()) {
      final id = r['id'] as int;
      final en = enReciters[id];
      final enMoshaf = {for (final m in ((en?['moshaf'] as List?) ?? const []).cast<Map<String, dynamic>>()) m['id'] as int: m};
      final moshaf = [
        for (final m in (r['moshaf'] as List).cast<Map<String, dynamic>>())
          Moshaf(
            id: m['id'] as int,
            nameAr: _clean(m['name'] as String),
            nameEn: _clean((enMoshaf[m['id']]?['name'] as String?) ?? m['name'] as String),
            server: m['server'] as String,
            surahs: _surahList(m['surah_list'] as String),
            rewayaId: (m['rewaya_id'] as num?)?.toInt() ?? 0,
            style: styleOf((m['moshaf_type'] as num?)?.toInt() ?? 11),
          ),
      ]..removeWhere((m) => m.surahs.isEmpty || !m.server.startsWith('https://'));
      if (moshaf.isEmpty) continue;
      // Complete murattal Hafs recordings first, so the default choice is the most useful one.
      int rank(Moshaf m) => (m.complete ? 0 : 4) + (m.style == RecitationStyle.murattal ? 0 : 2) + (m.rewayaId == 1 ? 0 : 1);
      moshaf.sort((a, b) => rank(a) - rank(b));
      reciters.add(QuranReciter(id: id, nameAr: _clean(r['name'] as String), nameEn: _clean((en?['name'] as String?) ?? r['name'] as String), moshaf: moshaf));
    }
    final enRadios = {for (final r in radiosEn.cast<Map<String, dynamic>>()) r['id'] as int: r};
    final radios = <QuranRadio>[
      for (final r in radiosAr.cast<Map<String, dynamic>>())
        if ((r['url'] as String? ?? '').startsWith('https://'))
          () {
            final ar = _clean(r['name'] as String);
            return QuranRadio(
              id: r['id'] as int,
              nameAr: ar,
              nameEn: _clean((enRadios[r['id']]?['name'] as String?) ?? ar).replaceFirst(RegExp(r'^Radio\s+'), ''),
              url: r['url'] as String,
              kind: radioKindOf(ar),
            );
          }(),
    ];
    final parts = <TafsirPart>[
      for (final p in ((tafsir?['soar'] as List?) ?? const []).cast<Map<String, dynamic>>())
        if (RegExp(r'/(\d{3})(?:-(\d+)-(\d+))?\.mp3$').firstMatch(p['url'] as String? ?? '') case final m? when (p['url'] as String).startsWith('https://'))
          TafsirPart(
            id: (p['id'] as num).toInt(),
            surah: int.parse(m[1]!),
            from: int.tryParse(m[2] ?? '') ?? 1,
            to: int.tryParse(m[3] ?? '') ?? 0,
            url: p['url'] as String,
          ),
    ]..sort((a, b) => a.surah != b.surah ? a.surah - b.surah : a.from - b.from);
    final vids = <ReciterVideo>[
      for (final r in videos.cast<Map<String, dynamic>>())
        for (final v in ((r['videos'] as List?) ?? const []).cast<Map<String, dynamic>>())
          if ((v['video_url'] as String? ?? '').startsWith('https://'))
            ReciterVideo(
              id: (v['id'] as num).toInt(),
              reciterId: (r['id'] as num).toInt(),
              reciterName: _clean(r['reciter_name'] as String? ?? ''),
              type: (v['video_type'] as num?)?.toInt() ?? 0,
              url: v['video_url'] as String,
              thumb: v['video_thumb_url'] as String? ?? '',
            ),
    ];
    return AudioCatalog(
      reciters: reciters,
      radios: radios,
      tafsirName: _clean(tafsir?['name'] as String? ?? ''),
      tafsir: parts,
      videos: vids,
      videoTypes: {for (final t in videoTypes.cast<Map<String, dynamic>>()) (t['id'] as num).toInt(): t['video_type'] as String},
    );
  }

  /// The bundled/cached file: `{"reciters": {"ar", "en"}, "radios": {"ar", "en"}, "tafsir", "videos": {"items", "types"}}`.
  factory AudioCatalog.fromSnapshot(Map<String, dynamic> j) {
    final rec = j['reciters'] as Map<String, dynamic>, rad = j['radios'] as Map<String, dynamic>;
    final vid = j['videos'] as Map<String, dynamic>?;
    return AudioCatalog.fromApi(
      recitersAr: rec['ar'] as List,
      recitersEn: rec['en'] as List,
      radiosAr: rad['ar'] as List,
      radiosEn: rad['en'] as List,
      tafsir: j['tafsir'] as Map<String, dynamic>?,
      videos: (vid?['items'] as List?) ?? const [],
      videoTypes: ((vid?['types'] as Map<String, dynamic>?)?['ar'] as List?) ?? const [],
    );
  }

  static List<int> _surahList(String s) {
    if (s == 'all') return [for (var i = 1; i <= 114; i++) i];
    return [
      for (final p in s.split(','))
        if (int.tryParse(p.trim()) case final n? when n >= 1 && n <= 114) n,
    ];
  }

  /// The API decorates some names with dashes and asterisks.
  static String _clean(String s) => s.replaceAll(RegExp(r'[-*]{2,}|^[-*\s]+|[-*\s]+$'), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

/// Classifies a station by words in its Arabic name; every other radio streams one reciter.
RadioKind radioKindOf(String nameAr) {
  if (nameAr.contains('ترجمة')) return RadioKind.translation;
  const lessons = ['تفسير', 'سيرة', 'السيرة', 'صحيح', 'رياض', 'الشمائل', 'قصص', 'حياة الصحابة', 'الفتاوى', 'كتاب', 'فضل', 'الاختيارات', 'غريب'];
  if (lessons.any(nameAr.contains)) return RadioKind.lesson;
  const quran = ['العامة', 'تلاوات', 'تكبيرات', 'الرقية', 'سورة', 'آيات', 'تراتيل', 'أذكار', 'القرآن الكريم'];
  if (quran.any(nameAr.contains)) return RadioKind.quran;
  return RadioKind.reciter;
}

/// English names for the video categories (the API only has Arabic).
String videoTypeName(int type, String arabic, bool ar) => ar
    ? arabic
    : switch (type) {
        2 => 'Blessings on the Prophet ﷺ',
        3 => 'Moments of faith',
        4 => 'Ramadan moments',
        _ => 'Recitation',
      };

/// Popular reciters shown first (mp3quran ids).
const featuredReciterIds = [123, 54, 31, 102, 118, 112, 51, 30, 5, 92, 86, 81, 20, 74];

/// Riwayat offered as filters (mp3quran `rewaya_id`), the rest fall under "other".
const riwayaFilters = <(int, String, String)>[
  (1, 'حفص عن عاصم', 'Hafs'),
  (2, 'ورش عن نافع', 'Warsh'),
  (5, 'قالون عن نافع', 'Qalun'),
];

const _api = 'https://www.mp3quran.net/api/v3';
const _cacheKey = 'audio-catalog-v2';

/// Cached copy (from an earlier refresh) first, the bundled snapshot otherwise.
/// A fresh copy is fetched in the background for the next launch, so the list
/// never changes under the person while they browse.
class AudioCatalogRepository {
  AudioCatalogRepository({required this.loader, required this.fetcher, required this.cache});
  final Future<String> Function(String path) loader;
  final BookFetcher fetcher;
  final TextCache cache;

  Future<AudioCatalog> load() async {
    final cached = await cache.read(_cacheKey);
    if (cached != null) {
      try {
        return AudioCatalog.fromSnapshot(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // A damaged cache falls back to the bundled file.
      }
    }
    return AudioCatalog.fromSnapshot(jsonDecode(await loader('assets/data/audio.json')) as Map<String, dynamic>);
  }

  /// Downloads the API lists and stores them if they parse.
  Future<void> refresh() async {
    try {
      Future<dynamic> get(String path, String key) async => (jsonDecode(await fetcher.get(Uri.parse('$_api/$path'))) as Map<String, dynamic>)[key];
      final snap = {
        'reciters': {'ar': await get('reciters?language=ar', 'reciters'), 'en': await get('reciters?language=eng', 'reciters')},
        'radios': {'ar': await get('radios?language=ar', 'radios'), 'en': await get('radios?language=eng', 'radios')},
        'tafsir': await get('tafsir?tafsir=1&language=ar', 'tafasir'),
        'videos': {'items': await get('videos?language=ar', 'videos'), 'types': {'ar': await get('video_types?language=ar', 'video_types')}},
      };
      final parsed = AudioCatalog.fromSnapshot(snap);
      // A partial answer is worse than the snapshot.
      if (parsed.reciters.length < 50 || parsed.tafsir.length < 114) return;
      await cache.write(_cacheKey, jsonEncode(snap));
    } catch (e) {
      debugPrint('Audio catalogue refresh failed: $e');
    }
  }
}

final audioCacheProvider = Provider<TextCache>((ref) => DiskTextCache(folder: 'audio'));

final audioCatalogRepositoryProvider = Provider<AudioCatalogRepository>(
  (ref) => AudioCatalogRepository(loader: ref.watch(contentLoaderProvider), fetcher: ref.watch(bookFetcherProvider), cache: ref.watch(audioCacheProvider)),
);

/// Set to false in tests so no network request starts.
final audioCatalogAutoRefreshProvider = Provider<bool>((ref) => true);

final audioCatalogProvider = FutureProvider<AudioCatalog>((ref) async {
  final repo = ref.watch(audioCatalogRepositoryProvider);
  final catalog = await repo.load();
  if (ref.read(audioCatalogAutoRefreshProvider)) unawaited(repo.refresh());
  return catalog;
});

/// Favourite reciters and radios, persisted as `r:<id>` / `radio:<id>`.
class AudioFavorites extends Notifier<Set<String>> {
  static const _k = 'audio.favorites';

  @override
  Set<String> build() => (ref.watch(sharedPreferencesProvider).getStringList(_k) ?? const <String>[]).toSet();

  bool toggle(String key) {
    final on = !state.contains(key);
    state = on ? {...state, key} : ({...state}..remove(key));
    ref.read(sharedPreferencesProvider).setStringList(_k, state.toList());
    return on;
  }
}

final audioFavoritesProvider = NotifierProvider<AudioFavorites, Set<String>>(AudioFavorites.new);
