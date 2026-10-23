import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/features/quran/quran_data.dart';

void main() {
  final repo = AssetQuranRepository(loader: (p) async => File(p).readAsStringSync());

  test('full mushaf: 114 surahs, 6236 ayahs, 30 juz, 604 pages', () async {
    final index = await repo.index();
    expect(index.surahs.length, 114);
    expect(index.juz.length, 30);
    expect(index.pages.length, 604);
    var total = 0;
    for (final s in index.surahs) {
      final ayahs = await repo.ayahs(s.number);
      expect(ayahs!.length, s.ayahCount, reason: 'surah ${s.number}');
      expect(ayahs.every((a) => a.ar.isNotEmpty && a.en.isNotEmpty), isTrue, reason: 'surah ${s.number}');
      total += ayahs.length;
    }
    expect(total, 6236);
  });

  test('basmala is only inside ayah 1 of Al-Fatihah', () async {
    final fatiha = (await repo.ayahs(1))!;
    final baqara = (await repo.ayahs(2))!;
    final basmala = fatiha.first.ar;
    expect(basmala.split(' ').length, 4);
    expect(baqara.first.ar.contains(basmala.split(' ')[1]), isFalse);
    for (final s in [2, 3, 114]) {
      expect((await repo.ayahs(s))!.first.ar.startsWith(basmala), isFalse, reason: 'surah $s');
    }
  });

  test('page lookup is exact', () async {
    final index = await repo.index();
    expect(index.estimatePage(1, 1), 1);
    expect(index.estimatePage(2, 1), 2);
    expect(index.estimatePage(18, 1), 293);
    expect(index.estimatePage(114, 6), 604);
  });
}
