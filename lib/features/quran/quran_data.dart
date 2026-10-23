import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

enum Revelation { meccan, medinan }

@immutable
class Surah {
  const Surah({required this.number, required this.nameAr, required this.nameEn, required this.revelation, required this.ayahCount, required this.startPage});
  final int number;
  final String nameAr;
  final String nameEn;
  final Revelation revelation;
  final int ayahCount;
  final int startPage;

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        number: j['number'] as int,
        nameAr: j['nameAr'] as String,
        nameEn: j['nameEn'] as String,
        revelation: Revelation.values.byName(j['revelation'] as String),
        ayahCount: j['ayahCount'] as int,
        startPage: j['startPage'] as int,
      );
}

@immutable
class Ayah {
  const Ayah({required this.number, required this.ar, required this.en});
  final int number;
  final String ar; // Uthmani text — never altered by UI language
  final String en; // translation layer
}

@immutable
class JuzInfo {
  const JuzInfo({required this.number, required this.surah, required this.ayah, required this.page});
  final int number, surah, ayah, page;
}

@immutable
class QuranIndex {
  const QuranIndex({required this.surahs, required this.juz, this.pages = const []});
  final List<Surah> surahs;
  final List<JuzInfo> juz;

  /// First (surah, ayah) of each mushaf page; index 0 is page 1.
  final List<(int, int)> pages;
}

extension QuranIndexX on QuranIndex {
  /// Mushaf page of [ayah] inside [surah]: exact when page data is loaded,
  /// otherwise a linear estimate from the surah start pages.
  int estimatePage(int surah, int ayah) {
    if (pages.isNotEmpty) {
      var page = 1;
      for (var i = 0; i < pages.length; i++) {
        final (s, a) = pages[i];
        if (s < surah || (s == surah && a <= ayah)) page = i + 1;
      }
      return page;
    }
    final i = surahs.indexWhere((s) => s.number == surah);
    if (i < 0) return 1;
    final s = surahs[i];
    final end = i + 1 < surahs.length ? surahs[i + 1].startPage : 604;
    return (s.startPage + (end - s.startPage) * ayah / s.ayahCount).floor().clamp(s.startPage, 604);
  }
}

/// One full-text search result.
@immutable
class SearchHit {
  const SearchHit({required this.surah, required this.ayah, required this.ar, required this.en});
  final int surah, ayah;
  final String ar, en;
}

/// Folds Arabic text for matching: drops harakat, Quranic marks and tatweel,
/// and unifies alef / ya / ta-marbuta / hamza carriers, so a plain-keyboard
/// query finds fully vowelled Uthmani text.
String normalizeArabic(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    // Harakat, tanween, shadda, sukun, superscript alef and Quranic annotation signs.
    if ((r >= 0x064B && r <= 0x065F) || r == 0x0670 || (r >= 0x06D6 && r <= 0x06ED) || r == 0x0640 || r == 0x08D4) continue;
    switch (r) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        out.writeCharCode(0x0627); // ا
      case 0x0649: // ى
      case 0x0626: // ئ
        out.writeCharCode(0x064A); // ي
      case 0x0629: // ة
        out.writeCharCode(0x0647); // ه
      case 0x0624: // ؤ
        out.writeCharCode(0x0648); // و
      default:
        out.writeCharCode(r);
    }
  }
  return out.toString();
}

abstract interface class QuranRepository {
  Future<QuranIndex> index();

  /// Returns null when the surah isn't available locally.
  Future<List<Ayah>?> ayahs(int surah);

  /// Full-text search over the Arabic text (diacritics-insensitive) and the
  /// English translation. Phrase matches rank first.
  Future<List<SearchHit>> search(String query, {int limit = 60});
}

/// Reads the bundled Tanzil Uthmani text: `assets/data/quran/index.json`
/// (surahs, juz, page starts; attribution lives in its `_note`) plus one small
/// file per surah (`NNN.json`), so opening a surah parses a few KB, never the
/// whole mushaf. Full-text search loads the remaining surahs once, lazily.
class AssetQuranRepository implements QuranRepository {
  AssetQuranRepository({Future<String> Function(String path)? loader}) : _loader = loader ?? rootBundle.loadString;
  final Future<String> Function(String path) _loader;
  Future<Map<String, dynamic>>? _index;
  final _surahs = <int, Future<List<dynamic>?>>{};
  Future<List<_Row>>? _rows;

  Future<Map<String, dynamic>> _loadIndex() => _index ??= _loader('assets/data/quran/index.json').then((raw) => jsonDecode(raw) as Map<String, dynamic>);

  Future<List<dynamic>?> _loadSurah(int n) {
    if (n < 1 || n > 114) return Future.value(null);
    return _surahs[n] ??= _loader('assets/data/quran/${n.toString().padLeft(3, '0')}.json').then((raw) => jsonDecode(raw) as List<dynamic>);
  }

  @override
  Future<QuranIndex> index() async {
    final j = await _loadIndex();
    return QuranIndex(
      surahs: (j['surahs'] as List).map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList(),
      juz: (j['juz'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return JuzInfo(number: m['number'] as int, surah: m['surah'] as int, ayah: m['ayah'] as int, page: m['page'] as int);
      }).toList(),
      pages: ((j['pages'] as List?) ?? const []).map((e) => ((e as List)[0] as int, e[1] as int)).toList(),
    );
  }

  @override
  Future<List<Ayah>?> ayahs(int surah) async {
    final list = await _loadSurah(surah);
    return list?.map((e) {
      final m = e as Map<String, dynamic>;
      return Ayah(number: m['number'] as int, ar: m['ar'] as String, en: m['en'] as String);
    }).toList();
  }

  /// Normalised search rows, built once on first search (awaiting one small
  /// file at a time keeps the UI responsive).
  Future<List<_Row>> _searchRows() => _rows ??= () async {
        final rows = <_Row>[];
        for (var s = 1; s <= 114; s++) {
          for (final e in (await _loadSurah(s))!) {
            final m = e as Map<String, dynamic>;
            rows.add(_Row(s, m['number'] as int, m['ar'] as String, m['en'] as String, normalizeArabic(m['ar'] as String), (m['en'] as String).toLowerCase()));
          }
        }
        return rows;
      }();

  @override
  Future<List<SearchHit>> search(String query, {int limit = 60}) async {
    final q = normalizeArabic(query.trim()).toLowerCase();
    if (q.runes.length < 2) return const [];
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final phrase = <SearchHit>[], loose = <SearchHit>[];
    for (final r in await _searchRows()) {
      final hay = '${r.arNorm} ${r.enLower}';
      if (!words.every(hay.contains)) continue;
      final hit = SearchHit(surah: r.surah, ayah: r.ayah, ar: r.ar, en: r.en);
      (r.arNorm.contains(q) || r.enLower.contains(q) ? phrase : loose).add(hit);
      if (phrase.length >= limit) break;
    }
    return [...phrase, ...loose].take(limit).toList();
  }
}

class _Row {
  const _Row(this.surah, this.ayah, this.ar, this.en, this.arNorm, this.enLower);
  final int surah, ayah;
  final String ar, en, arNorm, enLower;
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) => AssetQuranRepository(loader: ref.watch(contentLoaderProvider)));
final quranIndexProvider = FutureProvider<QuranIndex>((ref) => ref.watch(quranRepositoryProvider).index());
final ayahsProvider = FutureProvider.family<List<Ayah>?, int>((ref, surah) => ref.watch(quranRepositoryProvider).ayahs(surah));
final quranSearchProvider = FutureProvider.family<List<SearchHit>, String>((ref, query) => ref.watch(quranRepositoryProvider).search(query));

/// Last reading position and the set of mushaf pages read in the current
/// khatma (of 604), stored locally.
@immutable
class ReadingProgress {
  const ReadingProgress({required this.surah, required this.ayah, this.readPages = const {}});
  final int surah, ayah;
  final Set<int> readPages;
  int get pagesRead => readPages.length;
  double get khatma => pagesRead / 604;
}

class ReadingProgressController extends Notifier<ReadingProgress> {
  static const _kSurah = 'quran.lastSurah', _kAyah = 'quran.lastAyah', _kPages = 'quran.readPages';

  @override
  ReadingProgress build() {
    final p = ref.watch(sharedPreferencesProvider);
    final pages = (p.getString(_kPages) ?? '').split(',').map(int.tryParse).whereType<int>().where((e) => e >= 1 && e <= 604).toSet();
    return ReadingProgress(surah: p.getInt(_kSurah) ?? 1, ayah: p.getInt(_kAyah) ?? 1, readPages: pages);
  }

  /// Saves the position and adds the pages in [pages] to the khatma.
  /// Pages only accumulate: jumping around never un-reads anything.
  void markRead(int surah, int ayah, {Iterable<int> pages = const []}) {
    final next = {...state.readPages, ...pages.where((e) => e >= 1 && e <= 604)};
    state = ReadingProgress(surah: surah, ayah: ayah, readPages: next);
    ref.read(sharedPreferencesProvider)
      ..setInt(_kSurah, surah)
      ..setInt(_kAyah, ayah)
      ..setString(_kPages, (next.toList()..sort()).join(','));
  }

  /// Starts a new khatma, keeping the bookmark.
  void resetKhatma() {
    state = ReadingProgress(surah: state.surah, ayah: state.ayah);
    ref.read(sharedPreferencesProvider).remove(_kPages);
  }
}

final readingProgressProvider = NotifierProvider<ReadingProgressController, ReadingProgress>(ReadingProgressController.new);
