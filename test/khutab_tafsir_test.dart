import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/features/books/books_data.dart';
import 'package:noor/features/khutab/khutab_data.dart';
import 'package:noor/features/quran/tafsir.dart';

class _MemoryCache implements TextCache {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

class _Fetcher implements BookFetcher {
  _Fetcher(this.body);
  final String body;
  int calls = 0;
  @override
  Future<String> get(Uri url) async {
    calls++;
    if (body.isEmpty) throw const SocketException('offline');
    return body;
  }
}

/// Drops diacritics so an excerpt can be found in the full ayah text.
String _bare(String s) => s.replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '').replaceAll('ٱ', 'ا').replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('tafsir', () {
    test('parses the list format and the {ayahs} format', () {
      expect(parseTafsirSurah([
        {'text': ' a '},
        {'text': ''},
        {'x': 1},
      ]), ['a', '', '']);
      expect(parseTafsirSurah({
        'ayahs': [
          {'ayah': 2, 'surah': 1, 'text': 'b'},
          {'ayah': 1, 'surah': 1, 'text': 'a'},
        ],
      }), ['a', 'b']);
      expect(() => parseTafsirSurah('nope'), throwsFormatException);
    });

    test('an ayah explained with the one before points back to it', () {
      final s = ['one', '', '', 'four'];
      expect(tafsirFor(s, 1), (text: 'one', fromAyah: null));
      expect(tafsirFor(s, 3), (text: 'one', fromAyah: 1));
      expect(tafsirFor(s, 4), (text: 'four', fromAyah: null));
      expect(tafsirFor(const [''], 1), (text: '', fromAyah: null));
    });

    test('a surah is fetched once, then served from the cache; offline fails clearly', () async {
      final cache = _MemoryCache();
      final fetcher = _Fetcher(jsonEncode([
        {'text': 'x'},
        {'text': 'y'},
      ]));
      final repo = TafsirRepository(fetcher: fetcher, cache: cache);
      expect(await repo.surah('ar-tafsir-muyassar', 112), ['x', 'y']);
      expect(await repo.surah('ar-tafsir-muyassar', 112), ['x', 'y']);
      expect(fetcher.calls, 1);
      final offline = TafsirRepository(fetcher: _Fetcher(''), cache: _MemoryCache());
      expect(offline.surah('ar-tafsir-muyassar', 1), throwsA(isA<TafsirUnavailable>()));
    });

    test('editions are unique and Arabic ones come first', () {
      expect(tafsirEditions.map((e) => e.slug).toSet().length, tafsirEditions.length);
      expect(tafsirEditions.first.english, isFalse);
    });
  });

  group('khutab', () {
    final lib = KhutabLibrary.fromJson(jsonDecode(File('assets/data/khutab.json').readAsStringSync()) as Map<String, dynamic>);

    test('every sermon is complete in both languages', () {
      expect(lib.khutab.length, greaterThanOrEqualTo(15));
      expect(lib.khutab.map((k) => k.id).toSet().length, lib.khutab.length);
      for (final k in lib.khutab) {
        expect(lib.category(k.category), isNotNull, reason: k.id);
        expect(k.parts.length, greaterThanOrEqualTo(2), reason: k.id);
        for (final b in k.parts.expand((p) => p.blocks)) {
          expect(b.ar.trim(), isNotEmpty, reason: k.id);
          expect(b.en.trim(), isNotEmpty, reason: k.id);
          if (b.kind != KhutbaBlockKind.paragraph) expect(b.refAr, isNotEmpty, reason: '${k.id}: ${b.ar}');
        }
      }
    });

    test('every Quranic quotation appears verbatim in the bundled mushaf', () {
      final names = {
        for (final s in (jsonDecode(File('assets/data/quran/index.json').readAsStringSync())['surahs'] as List)) (s['nameAr'] as String): s['number'] as int,
      };
      final arDigits = '٠١٢٣٤٥٦٧٨٩';
      int n(String s) => int.parse(s.split('').map((c) => arDigits.contains(c) ? '${arDigits.indexOf(c)}' : c).join());
      for (final k in lib.khutab) {
        for (final b in k.parts.expand((p) => p.blocks).where((b) => b.kind == KhutbaBlockKind.ayah)) {
          final m = RegExp(r'^سورة (.+): ([٠-٩]+)(?:–([٠-٩]+))?$').firstMatch(b.refAr)!;
          final surah = names[m[1]]!;
          final from = n(m[2]!), to = m[3] == null ? from : n(m[3]!);
          final rows = jsonDecode(File('assets/data/quran/${surah.toString().padLeft(3, '0')}.json').readAsStringSync()) as List;
          final full = rows.sublist(from - 1, to).map((r) => r['ar'] as String).join(' ');
          expect(full.contains(b.ar), isTrue, reason: '${k.id} ${b.refAr}');
          expect(_bare(full).contains(_bare(b.ar)), isTrue);
        }
      }
    });

    test('weekly sermon follows the season, otherwise rotates each week', () {
      // 20 Sha‘ban 1448 ≈ 2027-01-29; 5 Dhul-Hijjah 1447 ≈ 2026-05-22.
      expect(lib.weekly(DateTime(2027, 1, 29)).id, 'ramadan');
      expect(lib.weekly(DateTime(2026, 5, 22)).id, 'dhulhijjah');
      final a = lib.weekly(DateTime(2026, 10, 23)), b = lib.weekly(DateTime(2026, 10, 30));
      expect(a.id, isNot(b.id));
      expect(lib.weekly(DateTime(2026, 10, 24)).id, a.id); // same week
      expect({'seasons', 'prophetic'}, isNot(contains(a.category)));
    });

    test('plain text keeps titles, sections and sources', () {
      final t = lib.byId('taqwa')!.plainText(true);
      expect(t, startsWith('التقوى'));
      expect(t, contains('— الخطبة الثانية —'));
      expect(t, contains('[سورة الطلاق: ٢–٣]'));
      expect(lib.byId('taqwa')!.plainText(false), contains('Second khutbah'));
    });
  });
}
