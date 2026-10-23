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

abstract interface class QuranRepository {
  Future<QuranIndex> index();

  /// Returns null when the surah isn't available locally (e.g. sample build).
  Future<List<Ayah>?> ayahs(int surah);
}

/// Reads the bundled Tanzil Uthmani text (assets/data/quran.json, built from
/// tanzil.net; attribution is kept in the file's `_note`). Swap for an
/// SQLite/Isar repository if load time on low-end devices becomes an issue.
class AssetQuranRepository implements QuranRepository {
  AssetQuranRepository({Future<String> Function(String path)? loader}) : _loader = loader ?? rootBundle.loadString;
  final Future<String> Function(String path) _loader;
  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async => _cache ??= jsonDecode(await _loader('assets/data/quran.json')) as Map<String, dynamic>;

  @override
  Future<QuranIndex> index() async {
    final j = await _load();
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
    final text = (await _load())['text'] as Map<String, dynamic>;
    final list = text['$surah'] as List?;
    return list?.map((e) {
      final m = e as Map<String, dynamic>;
      return Ayah(number: m['number'] as int, ar: m['ar'] as String, en: m['en'] as String);
    }).toList();
  }
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) => AssetQuranRepository(loader: ref.watch(contentLoaderProvider)));
final quranIndexProvider = FutureProvider<QuranIndex>((ref) => ref.watch(quranRepositoryProvider).index());
final ayahsProvider = FutureProvider.family<List<Ayah>?, int>((ref, surah) => ref.watch(quranRepositoryProvider).ayahs(surah));

/// Last reading position and khatma progress (pages read of 604), stored locally.
@immutable
class ReadingProgress {
  const ReadingProgress({required this.surah, required this.ayah, required this.pagesRead});
  final int surah, ayah, pagesRead;
  double get khatma => pagesRead / 604;
}

class ReadingProgressController extends Notifier<ReadingProgress> {
  @override
  ReadingProgress build() {
    final p = ref.watch(sharedPreferencesProvider);
    return ReadingProgress(surah: p.getInt('quran.lastSurah') ?? 1, ayah: p.getInt('quran.lastAyah') ?? 1, pagesRead: p.getInt('quran.pagesRead') ?? 0);
  }

  /// Saves the position. [page] is the estimated mushaf page reached; the
  /// khatma only ever moves forward.
  void markRead(int surah, int ayah, {int? page}) {
    final pages = page == null ? state.pagesRead : page.clamp(state.pagesRead, 604);
    state = ReadingProgress(surah: surah, ayah: ayah, pagesRead: pages);
    ref.read(sharedPreferencesProvider)
      ..setInt('quran.lastSurah', surah)
      ..setInt('quran.lastAyah', ayah)
      ..setInt('quran.pagesRead', pages);
  }
}

final readingProgressProvider = NotifierProvider<ReadingProgressController, ReadingProgress>(ReadingProgressController.new);
