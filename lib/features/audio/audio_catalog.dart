import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../books/books_data.dart' show BookFetcher, DiskTextCache, TextCache, bookFetcherProvider;

/// One recording of the whole (or part of the) Quran by a reciter, in one riwaya.
@immutable
class Moshaf {
  const Moshaf({required this.id, required this.nameAr, required this.nameEn, required this.server, required this.surahs, required this.rewayaId});
  final int id;
  final String nameAr, nameEn;

  /// Folder URL; surah N is `${server}NNN.mp3`.
  final String server;
  final List<int> surahs;
  final int rewayaId;

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

@immutable
class QuranRadio {
  const QuranRadio({required this.id, required this.nameAr, required this.nameEn, required this.url, required this.thematic});
  final int id;
  final String nameAr, nameEn, url;

  /// Topic stations (tafsir, seerah, adhkar, translations …) rather than one reciter.
  final bool thematic;

  String name(bool ar) => ar ? nameAr : nameEn;
}

@immutable
class AudioCatalog {
  const AudioCatalog({required this.reciters, required this.radios});
  final List<QuranReciter> reciters;
  final List<QuranRadio> radios;

  QuranReciter? reciter(int id) => reciters.where((r) => r.id == id).firstOrNull;
  QuranRadio? radio(int id) => radios.where((r) => r.id == id).firstOrNull;

  /// Parses the mp3quran.net v3 responses (`reciters` / `radios`, Arabic and English).
  factory AudioCatalog.fromApi({required List<dynamic> recitersAr, required List<dynamic> recitersEn, required List<dynamic> radiosAr, required List<dynamic> radiosEn}) {
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
          ),
      ]..removeWhere((m) => m.surahs.isEmpty || !m.server.startsWith('https://'));
      if (moshaf.isEmpty) continue;
      // Complete recordings first, then Hafs, so the default choice is the most useful one.
      moshaf.sort((a, b) {
        final c = (b.complete ? 1 : 0) - (a.complete ? 1 : 0);
        return c != 0 ? c : (a.rewayaId == 1 ? 0 : 1) - (b.rewayaId == 1 ? 0 : 1);
      });
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
              thematic: _topics.any(ar.contains),
            );
          }(),
    ];
    return AudioCatalog(reciters: reciters, radios: radios);
  }

  /// The bundled/cached file: `{"reciters": {"ar": [...], "en": [...]}, "radios": {...}}`.
  factory AudioCatalog.fromSnapshot(Map<String, dynamic> j) {
    final rec = j['reciters'] as Map<String, dynamic>, rad = j['radios'] as Map<String, dynamic>;
    return AudioCatalog.fromApi(recitersAr: rec['ar'] as List, recitersEn: rec['en'] as List, radiosAr: rad['ar'] as List, radiosEn: rad['en'] as List);
  }

  static List<int> _surahList(String s) {
    if (s == 'all') return [for (var i = 1; i <= 114; i++) i];
    return [
      for (final p in s.split(','))
        if (int.tryParse(p.trim()) case final n? when n >= 1 && n <= 114) n,
    ];
  }

  /// Words that mark a topic station; every other radio streams one reciter.
  static const _topics = ['تفسير', 'ترجمة', 'سيرة', 'السيرة', 'أذكار', 'الرقية', 'الفتاوى', 'قصص', 'حياة الصحابة', 'تكبيرات', 'تلاوات', 'تراتيل', 'العامة', 'سورة', 'آيات', 'صحيح', 'رياض', 'الشمائل', 'فضل', 'كتاب', 'القرآن الكريم'];

  /// The API decorates some names with dashes and asterisks.
  static String _clean(String s) => s.replaceAll(RegExp(r'[-*]{2,}|^[-*\s]+|[-*\s]+$'), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

/// Popular reciters shown first (mp3quran ids).
const featuredReciterIds = [123, 54, 31, 102, 118, 112, 51, 30, 5, 92, 86, 81, 20, 74];

/// Riwayat offered as filters (mp3quran `rewaya_id`), the rest fall under "other".
const riwayaFilters = <(int, String, String)>[
  (1, 'حفص عن عاصم', 'Hafs'),
  (2, 'ورش عن نافع', 'Warsh'),
  (5, 'قالون عن نافع', 'Qalun'),
];

const _api = 'https://www.mp3quran.net/api/v3';
const _cacheKey = 'audio-catalog';

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

  /// Downloads the four API lists and stores them if they parse.
  Future<void> refresh() async {
    try {
      Future<List<dynamic>> get(String path, String key) async => (jsonDecode(await fetcher.get(Uri.parse('$_api/$path'))) as Map<String, dynamic>)[key] as List;
      final snap = {
        'reciters': {'ar': await get('reciters?language=ar', 'reciters'), 'en': await get('reciters?language=eng', 'reciters')},
        'radios': {'ar': await get('radios?language=ar', 'radios'), 'en': await get('radios?language=eng', 'radios')},
      };
      final parsed = AudioCatalog.fromSnapshot(snap);
      if (parsed.reciters.length < 50) return; // a partial answer is worse than the snapshot
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
