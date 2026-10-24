import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../books/books_data.dart' show BookFetcher, DiskTextCache, TextCache, bookFetcherProvider;

@immutable
class TafsirEdition {
  const TafsirEdition(this.slug, this.nameAr, this.nameEn, {this.english = false});

  /// Folder in the spa5k/tafsir_api dataset.
  final String slug;
  final String nameAr, nameEn;
  final bool english;

  String name(bool ar) => ar ? nameAr : nameEn;
}

/// Editions offered in the reader. Al-Muyassar is short and loads fast, so it is the default.
const tafsirEditions = <TafsirEdition>[
  TafsirEdition('ar-tafsir-muyassar', 'التفسير الميسّر', 'Al-Muyassar (Arabic)'),
  TafsirEdition('ar-tafsir-al-mukhtasar', 'المختصر في التفسير', 'Al-Mukhtasar (Arabic)'),
  TafsirEdition('ar-tafseer-al-saddi', 'تفسير السعدي', 'As-Sa‘di (Arabic)'),
  TafsirEdition('ar-tafsir-al-jalalayn', 'تفسير الجلالين', 'Al-Jalalayn (Arabic)'),
  TafsirEdition('ar-tafsir-ibn-kathir', 'تفسير ابن كثير', 'Ibn Kathir (Arabic)'),
  TafsirEdition('ar-tafsir-al-baghawi', 'تفسير البغوي', 'Al-Baghawi (Arabic)'),
  TafsirEdition('ar-tafseer-al-qurtubi', 'تفسير القرطبي', 'Al-Qurtubi (Arabic)'),
  TafsirEdition('ar-tafsir-al-tabari', 'تفسير الطبري', 'At-Tabari (Arabic)'),
  TafsirEdition('ar-tafsir-al-wasit', 'التفسير الوسيط', 'Al-Wasit (Arabic)'),
  TafsirEdition('en-tafsir-al-mukhtasar', 'المختصر (إنجليزي)', 'Al-Mukhtasar', english: true),
  TafsirEdition('en-tafisr-ibn-kathir', 'ابن كثير (إنجليزي)', 'Ibn Kathir (abridged)', english: true),
  TafsirEdition('en-tafsir-maarif-ul-quran', 'معارف القرآن (إنجليزي)', 'Ma‘arif al-Qur’an', english: true),
];

/// Pinned release of the dataset (MIT), as its authors recommend for apps.
const _base = 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.1/tafsir';

/// Raised when a surah's tafsir is neither cached nor reachable.
class TafsirUnavailable implements Exception {
  const TafsirUnavailable(this.reason);
  final Object reason;
  @override
  String toString() => 'Tafsir unavailable: $reason';
}

/// Commentary for one ayah. [fromAyah] is set when the edition explains a
/// group of ayahs together and this text was written under an earlier one.
typedef AyahTafsir = ({String text, int? fromAyah});

/// The per-ayah texts of one surah, index 0 = ayah 1.
@visibleForTesting
List<String> parseTafsirSurah(Object? json) {
  if (json is List) return [for (final e in json) e is Map ? (e['text'] as String? ?? '').trim() : ''];
  if (json is Map && json['ayahs'] is List) {
    final rows = (json['ayahs'] as List).whereType<Map>().toList();
    final last = rows.fold<int>(0, (m, r) => ((r['ayah'] as num?)?.toInt() ?? 0) > m ? (r['ayah'] as num).toInt() : m);
    final out = List.filled(last, '');
    for (final r in rows) {
      final a = (r['ayah'] as num?)?.toInt() ?? 0;
      if (a >= 1) out[a - 1] = (r['text'] as String? ?? '').trim();
    }
    return out;
  }
  throw const FormatException('Unknown tafsir format');
}

/// Text for [ayah]; walks back to the ayah whose text covers it when the
/// edition comments on several ayahs at once.
AyahTafsir tafsirFor(List<String> surah, int ayah) {
  for (var a = ayah.clamp(1, surah.length); a >= 1; a--) {
    final text = surah[a - 1];
    if (text.isNotEmpty) return (text: text, fromAyah: a == ayah ? null : a);
  }
  return (text: '', fromAyah: null);
}

/// Fetches one surah at a time from the CDN and keeps it on disk, so a surah
/// read once is available offline afterwards.
class TafsirRepository {
  TafsirRepository({required this.fetcher, required this.cache});
  final BookFetcher fetcher;
  final TextCache cache;

  Future<List<String>> surah(String slug, int surah) async {
    final key = '$slug-$surah';
    final cached = await cache.read(key);
    if (cached != null) return (jsonDecode(cached) as List).cast<String>();
    try {
      final list = parseTafsirSurah(jsonDecode(await fetcher.get(Uri.parse('$_base/$slug/$surah.json'))));
      await cache.write(key, jsonEncode(list));
      return list;
    } catch (e) {
      throw TafsirUnavailable(e);
    }
  }
}

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) => TafsirRepository(fetcher: ref.watch(bookFetcherProvider), cache: DiskTextCache(folder: 'tafsir')));

/// No automatic retries: the sheet offers its own "try again".
final tafsirSurahProvider = FutureProvider.family<List<String>, (String, int)>((ref, key) => ref.watch(tafsirRepositoryProvider).surah(key.$1, key.$2), retry: (_, _) => null);

class TafsirEditionController extends Notifier<TafsirEdition> {
  static const _k = 'quran.tafsir';

  @override
  TafsirEdition build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_k);
    return tafsirEditions.where((e) => e.slug == saved).firstOrNull ?? tafsirEditions.first;
  }

  void select(TafsirEdition e) {
    state = e;
    ref.read(sharedPreferencesProvider).setString(_k, e.slug);
  }
}

final tafsirEditionProvider = NotifierProvider<TafsirEditionController, TafsirEdition>(TafsirEditionController.new);
