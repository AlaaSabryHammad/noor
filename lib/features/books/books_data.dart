import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';

@immutable
class BookSection {
  const BookSection({required this.n, required this.title, this.first, this.last});
  final int n;
  final String title; // English, as published by the dataset
  final num? first, last;

  factory BookSection.fromJson(Map<String, dynamic> j) => BookSection(n: j['n'] as int, title: j['title'] as String, first: j['first'] as num?, last: j['last'] as num?);
}

@immutable
class Book {
  const Book({required this.id, required this.titleAr, required this.titleEn, required this.authorAr, required this.authorEn, required this.blurbAr, required this.blurbEn, required this.bundled, required this.count, required this.sections});
  final String id, titleAr, titleEn, authorAr, authorEn, blurbAr, blurbEn;

  /// Bundled books work offline; the others are fetched per section and cached.
  final bool bundled;
  final int count;
  final List<BookSection> sections;

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as String,
        titleAr: j['titleAr'] as String,
        titleEn: j['titleEn'] as String,
        authorAr: j['authorAr'] as String,
        authorEn: j['authorEn'] as String,
        blurbAr: j['blurbAr'] as String,
        blurbEn: j['blurbEn'] as String,
        bundled: j['bundled'] as bool,
        count: j['count'] as int? ?? 0,
        sections: (j['sections'] as List).map((e) => BookSection.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

@immutable
class BookHadith {
  const BookHadith({required this.n, required this.ar, required this.en, this.grade = ''});
  final int n;
  final String ar, en, grade;

  Map<String, Object?> toJson() => {'n': n, 'ar': ar, 'en': en, 'g': grade};
  factory BookHadith.fromJson(Map<String, dynamic> j) => BookHadith(n: (j['n'] as num).toInt(), ar: j['ar'] as String? ?? '', en: j['en'] as String? ?? '', grade: j['g'] as String? ?? '');
}

/// Raised when a section is neither cached nor reachable.
class BookUnavailable implements Exception {
  const BookUnavailable(this.reason);
  final Object reason;
  @override
  String toString() => 'Book text unavailable: $reason';
}

abstract interface class BookFetcher {
  Future<String> get(Uri url);
}

class HttpBookFetcher implements BookFetcher {
  const HttpBookFetcher();
  @override
  Future<String> get(Uri url) async {
    final r = await http.get(url).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}', uri: url);
    return utf8.decode(r.bodyBytes);
  }
}

abstract interface class TextCache {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Files in the app's private support directory; falls back to memory when the
/// platform has no such directory (tests, web).
class DiskTextCache implements TextCache {
  final _memory = <String, String>{};
  Directory? _dir;

  Future<Directory?> _root() async {
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationSupportDirectory();
      return _dir = await Directory('${base.path}/books').create(recursive: true);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> read(String key) async {
    final d = await _root();
    if (d == null) return _memory[key];
    final f = File('${d.path}/$key.json');
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    final d = await _root();
    if (d == null) {
      _memory[key] = value;
      return;
    }
    await File('${d.path}/$key.json').writeAsString(value, flush: true);
  }
}

abstract interface class BooksRepository {
  Future<List<Book>> catalog();

  /// Hadith of one section. Online books hit the network once, then the cache.
  Future<List<BookHadith>> section(Book book, int section);

  /// Whether [section] can be read without a connection.
  Future<bool> isAvailableOffline(Book book, int section);
}

class DatasetBooksRepository implements BooksRepository {
  DatasetBooksRepository({required this.loader, required this.fetcher, required this.cache});
  final Future<String> Function(String path) loader;
  final BookFetcher fetcher;
  final TextCache cache;
  Future<Map<String, dynamic>>? _catalog;
  final _bundled = <String, Future<List<Map<String, dynamic>>>>{};

  Future<Map<String, dynamic>> _catalogJson() => _catalog ??= loader('assets/data/books/catalog.json').then((r) => jsonDecode(r) as Map<String, dynamic>);

  @override
  Future<List<Book>> catalog() async => ((await _catalogJson())['books'] as List).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();

  Future<String> _base() async => (await _catalogJson())['base'] as String;

  @override
  Future<List<BookHadith>> section(Book book, int section) async {
    if (book.bundled) {
      // Bundled files keep each hadith's section in `s`; the books are small, so filter in memory.
      final raw = await (_bundled[book.id] ??= loader('assets/data/books/${book.id}.json').then((r) => (jsonDecode(r) as List).cast<Map<String, dynamic>>()));
      return [for (final e in raw) if (e['s'] == section) BookHadith.fromJson(e)];
    }
    final key = '${book.id}-$section';
    final cached = await cache.read(key);
    if (cached != null) return _decode(cached);
    try {
      final base = await _base();
      final ar = jsonDecode(await fetcher.get(Uri.parse('$base/editions/ara-${book.id}/sections/$section.json'))) as Map<String, dynamic>;
      final en = jsonDecode(await fetcher.get(Uri.parse('$base/editions/eng-${book.id}/sections/$section.json'))) as Map<String, dynamic>;
      final enByNumber = {for (final h in (en['hadiths'] as List)) (h['hadithnumber'] as num).toInt(): h as Map<String, dynamic>};
      final list = [
        for (final h in (ar['hadiths'] as List))
          () {
            final n = (h['hadithnumber'] as num).toInt();
            final e = enByNumber[n];
            return BookHadith(n: n, ar: (h['text'] as String).trim(), en: ((e?['text'] as String?) ?? '').trim(), grade: _grade(h as Map<String, dynamic>) ?? _grade(e ?? const {}) ?? '');
          }(),
      ];
      await cache.write(key, jsonEncode(list.map((e) => e.toJson()).toList()));
      return list;
    } catch (e) {
      throw BookUnavailable(e);
    }
  }

  String? _grade(Map<String, dynamic> h) {
    final g = h['grades'];
    if (g is List && g.isNotEmpty && g.first is Map) return (g.first as Map)['grade'] as String?;
    return null;
  }

  List<BookHadith> _decode(String s) => (jsonDecode(s) as List).map((e) => BookHadith.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<bool> isAvailableOffline(Book book, int section) async => book.bundled || await cache.read('${book.id}-$section') != null;
}

final bookFetcherProvider = Provider<BookFetcher>((ref) => const HttpBookFetcher());
final textCacheProvider = Provider<TextCache>((ref) => DiskTextCache());
final booksRepositoryProvider = Provider<BooksRepository>((ref) => DatasetBooksRepository(loader: ref.watch(contentLoaderProvider), fetcher: ref.watch(bookFetcherProvider), cache: ref.watch(textCacheProvider)));
final booksCatalogProvider = FutureProvider<List<Book>>((ref) => ref.watch(booksRepositoryProvider).catalog());
final bookProvider = FutureProvider.family<Book?, String>((ref, id) async => (await ref.watch(booksCatalogProvider.future)).where((b) => b.id == id).firstOrNull);

typedef SectionKey = (String bookId, int section);
final bookSectionProvider = FutureProvider.family<List<BookHadith>, SectionKey>((ref, key) async {
  final book = await ref.watch(bookProvider(key.$1).future);
  if (book == null) return const [];
  return ref.watch(booksRepositoryProvider).section(book, key.$2);
});
