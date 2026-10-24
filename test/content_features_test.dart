import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/core/theme/noor_theme.dart';
import 'package:noor/features/khutab/khutab_data.dart';
import 'package:noor/features/library/favorites.dart';
import 'package:noor/features/library/share_image.dart';
import 'package:noor/features/prayer/domain/prayer_models.dart';
import 'package:noor/features/search/search.dart';
import 'package:noor/features/services/qada_screen.dart';
import 'package:noor/features/spotlights/spotlights.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Spotlight> _spotlights() => [for (final s in (jsonDecode(File('assets/data/spotlights.json').readAsStringSync())['spotlights'] as List)) Spotlight.fromJson(s as Map<String, dynamic>)];

String _bare(String s) => s.replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '').replaceAll('ٱ', 'ا').replaceAll(RegExp(r'\s+'), ' ');

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('spotlights', () {
    final all = _spotlights();

    test('the season decides; outside every season a year-round topic rotates weekly', () {
      String at(DateTime d) => spotlightFor(all, d)!.id;
      expect(at(DateTime(2027, 3, 1)), 'last-ten'); // ~22 Ramadan 1448
      expect(at(DateTime(2027, 2, 12)), 'ramadan'); // ~5 Ramadan
      expect(at(DateTime(2027, 3, 15)), 'shawwal');
      expect(at(DateTime(2027, 1, 20)), 'shaban');
      expect(at(DateTime(2026, 5, 22)), 'dhulhijjah'); // ~5 Dhul-Hijjah 1447
      expect(at(DateTime(2026, 6, 20)), 'muharram'); // ~5 Muharram 1448
      expect(at(DateTime(2026, 12, 20)), 'sacred-months'); // ~10 Rajab 1448
      expect(at(DateTime(2026, 10, 25)), 'white-days'); // ~14 Jumada al-Ula
      final quiet = spotlightFor(all, DateTime(2026, 10, 18))!;
      expect(quiet.yearRound, isTrue);
      expect(spotlightFor(all, DateTime(2026, 10, 19))!.id, quiet.id); // same week
      expect(spotlightFor(all, DateTime(2026, 11, 2))!.id, isNot(quiet.id));
      expect(spotlightFor(const [], DateTime(2026)), isNull);
    });

    test('every spotlight is complete and links inside the app', () {
      expect(all.length, greaterThanOrEqualTo(10));
      for (final s in all) {
        expect(s.blocks, isNotEmpty, reason: s.id);
        expect(s.actions.every((a) => a.route.startsWith('/')), isTrue, reason: s.id);
        for (final b in s.blocks) {
          expect(b.en, isNotEmpty, reason: s.id);
          if (b.kind != KhutbaBlockKind.paragraph) expect(b.refAr, isNotEmpty, reason: s.id);
        }
      }
    });

    test('Quranic quotations are verbatim from the bundled mushaf', () {
      final names = {for (final s in (jsonDecode(File('assets/data/quran/index.json').readAsStringSync())['surahs'] as List)) (s['nameAr'] as String): s['number'] as int};
      const digits = '٠١٢٣٤٥٦٧٨٩';
      int n(String s) => int.parse(s.split('').map((c) => digits.contains(c) ? '${digits.indexOf(c)}' : c).join());
      for (final b in all.expand((s) => s.blocks).where((b) => b.kind == KhutbaBlockKind.ayah)) {
        final m = RegExp(r'^سورة (.+): ([٠-٩]+)(?:–([٠-٩]+))?$').firstMatch(b.refAr)!;
        final rows = jsonDecode(File('assets/data/quran/${names[m[1]]!.toString().padLeft(3, '0')}.json').readAsStringSync()) as List;
        final from = n(m[2]!), to = m[3] == null ? from : n(m[3]!);
        expect(_bare(rows.sublist(from - 1, to).map((r) => r['ar']).join(' ')).contains(_bare(b.ar)), isTrue, reason: b.refAr);
      }
    });
  });

  group('search', () {
    test('finds content across sections, ignoring diacritics, title matches first', () async {
      final c = await _container();
      final entries = await c.read(searchIndexProvider.future);
      expect(entries.length, greaterThan(400));
      final r = searchEntries(entries, 'الصبر');
      expect(r[SearchKind.khutba]!.first.titleAr, contains('الصبر'));
      expect(r.length, greaterThan(1)); // more than one section mentions patience
      // Diacritics and alef forms in the query do not matter.
      expect(searchEntries(entries, 'التَّقوَى')[SearchKind.khutba]!.first.route, '/khutab/taqwa');
      expect(searchEntries(entries, 'Laylat al-Qadr').values.expand((l) => l), isNotEmpty);
      expect(searchEntries(entries, 'ا'), isEmpty);
      expect(searchEntries(entries, 'zzzzqq'), isEmpty);
      final hisn = searchEntries(entries, 'السلام من الصلاة')[SearchKind.hisn];
      expect(hisn!.first.route, startsWith('/adhkar/session/hisn_'));
    });

    test('at most perKind results per section', () async {
      final c = await _container();
      final r = searchEntries(await c.read(searchIndexProvider.future), 'الله', perKind: 3);
      expect(r.values.every((l) => l.length <= 3), isTrue);
    });
  });

  group('qada tracker', () {
    test('whole days add five prayers each; making up moves to the tally; persists', () async {
      final c = await _container();
      final q = c.read(qadaProvider.notifier);
      q.addDays(3);
      expect(c.read(qadaProvider).prayersLeft, 15);
      q.madeUp(PrayerKind.fajr);
      q.madeUp(PrayerKind.fajr);
      expect(c.read(qadaProvider).owed(PrayerKind.fajr), 1);
      expect(c.read(qadaProvider).prayersDone, 2);
      q.adjust(PrayerKind.isha, -10);
      expect(c.read(qadaProvider).owed(PrayerKind.isha), 0);
      q.madeUp(PrayerKind.isha); // nothing owed: no change
      expect(c.read(qadaProvider).prayersDone, 2);
      q.adjustFasts(4);
      q.fastMadeUp();
      expect((c.read(qadaProvider).fasts, c.read(qadaProvider).fastsDone), (3, 1));
      final saved = QadaState.fromJson(jsonDecode(c.read(sharedPreferencesProvider).getString('qada.v1')!) as Map<String, dynamic>);
      expect(saved.prayersLeft, c.read(qadaProvider).prayersLeft);
      q.reset();
      expect(c.read(qadaProvider).prayersLeft, 0);
    });

    test('damaged storage starts empty', () {
      expect(QadaState.fromJson({'p': 'x'}).prayersLeft, 0);
      expect(QadaState.fromJson({'p': {'fajr': -4}, 'f': 2}).owed(PrayerKind.fajr), 0);
    });
  });

  group('Q&A', () {
    test('every question has both languages and a known category', () {
      final d = jsonDecode(File('assets/data/faq.json').readAsStringSync()) as Map<String, dynamic>;
      final cats = (d['categories'] as Map).keys.toSet();
      expect(cats, containsAll(['transactions', 'family', 'women', 'manners']));
      final items = (d['items'] as List).cast<Map<String, dynamic>>();
      expect(items.length, greaterThanOrEqualTo(70));
      expect(items.map((i) => i['id']).toSet().length, items.length);
      for (final i in items) {
        expect(cats, contains(i['cat']));
        for (final k in ['qAr', 'qEn', 'aAr', 'aEn']) {
          expect((i[k] as String).trim(), isNotEmpty, reason: '${i['id']} $k');
        }
      }
    });
  });

  testWidgets('share card renders long text in every style without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final long = SavedItem(key: 'k', kind: 'hadith', title: 't', body: 'نص طويل ' * 120, translation: 'long text ' * 60, source: 'رواه مسلم');
    for (final style in ShareCardStyle.values) {
      await tester.pumpWidget(MaterialApp(theme: NoorTheme.light(const Locale('ar')), home: Scaffold(body: SizedBox(width: 300, child: ShareCard(item: long, style: style, translation: true)))));
      expect(tester.takeException(), isNull);
      expect(find.text('نور · NOOR'), findsOneWidget);
    }
  });
}
