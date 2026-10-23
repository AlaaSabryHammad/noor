import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/library/favorites.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/quran/ayah_audio.dart';
import 'package:noor/features/services/calendar_screen.dart';
import 'package:noor/features/services/planner_screen.dart';
import 'package:noor/features/services/zakat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Map<String, dynamic> _json(String name) => jsonDecode(File('assets/data/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('zakat', () {
    test('below nisab → nothing due', () {
      final r = calculateZakat(const ZakatInput(cash: 1000, goldPrice: 60));
      expect(r.nisab, 85 * 60);
      expect(r.reachesNisab, isFalse);
      expect(r.due, 0);
    });

    test('2.5% of net wealth once the nisab is reached', () {
      final r = calculateZakat(const ZakatInput(cash: 10000, goldGrams: 10, goldPrice: 60, debts: 600, investments: 0));
      expect(r.assets, 10600);
      expect(r.net, 10000);
      expect(r.reachesNisab, isTrue);
      expect(r.due, closeTo(250, 1e-9));
    });

    test('silver nisab basis is lower; missing prices are flagged', () {
      final r = calculateZakat(const ZakatInput(cash: 5000, silverPrice: 1, basis: NisabBasis.silver));
      expect(r.nisab, 595);
      expect(r.due, closeTo(125, 1e-9));
      expect(calculateZakat(const ZakatInput(cash: 100)).priceMissing, isTrue);
      expect(calculateZakat(const ZakatInput(goldGrams: 10)).priceMissing, isTrue);
    });

    test('debts never make wealth negative; Arabic digits parse', () {
      expect(calculateZakat(const ZakatInput(cash: 10, debts: 50, goldPrice: 1)).net, 0);
      expect(parseAmount('١٢٣٫٥'), 123.5);
      expect(parseAmount('1,000'), 1000);
      expect(parseAmount('abc'), 0);
    });
  });

  group('planner', () {
    final today = DateTime(2026, 10, 23);
    const all = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

    test('streak counts consecutive complete days; incomplete today does not break it', () {
      final days = <DateTime, Set<String>>{
        DateTime(2026, 10, 22): all,
        DateTime(2026, 10, 21): all,
        DateTime(2026, 10, 20): {'fajr'},
      };
      Set<String> done(DateTime d) => days[d] ?? <String>{};
      expect(prayerStreak(today, done), 2);
      days[today] = all;
      expect(prayerStreak(today, done), 3);
    });

    test('empty history is a zero streak', () => expect(prayerStreak(today, (_) => <String>{}), 0));
  });

  group('calendar', () {
    test('known occasions fall in the right Hijri months', () {
      expect(eventsOfMonth(9).any((e) => e.day == 1), isTrue); // Ramadan
      expect(eventsOfMonth(10).first.day, 1); // Eid al-Fitr
      expect(eventsOfMonth(12).map((e) => e.day), containsAll([8, 9, 10, 11]));
    });

    test('white days are listed except in Ramadan and Dhul-Hijjah', () {
      expect(eventsOfMonth(1).any((e) => e.day == 13), isTrue);
      expect(eventsOfMonth(9).any((e) => e.day == 13), isFalse);
      expect(eventsOfMonth(12).any((e) => e.day == 13), isFalse);
    });
  });

  group('content files', () {
    test('adhkar: every category is non-empty, ids unique, repeats positive', () {
      final j = _json('adhkar');
      final ids = <String>{};
      for (final cat in ['morning', 'evening', 'sleep', 'waking', 'after_prayer', 'wudu', 'mosque', 'travel', 'food', 'home', 'quran_duas', 'sunnah_duas']) {
        final list = (j[cat] as List).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty, reason: cat);
        for (final d in list) {
          expect(ids.add(d['id'] as String), isTrue, reason: 'duplicate id ${d['id']}');
          expect(d['repeat'] as int, greaterThan(0));
          expect((d['ar'] as String).trim(), isNotEmpty);
          expect((d['en'] as String).trim(), isNotEmpty);
          expect((d['sourceAr'] as String).trim(), isNotEmpty);
        }
      }
    });

    test('Quranic adhkar match the dataset verbatim', () {
      final q = _json('quran');
      final kursi = ((q['text'] as Map)['2'] as List)[254]['ar'];
      final kursiInAdhkar = ((_json('adhkar')['evening'] as List).first as Map)['ar'];
      expect(kursiInAdhkar, kursi);
    });

    test('99 names, numbered in order', () {
      final names = (_json('names')['names'] as List).cast<Map<String, dynamic>>();
      expect(names.length, 99);
      expect(names.map((n) => n['n']), List.generate(99, (i) => i + 1));
    });

    test('hadith, seerah, stories, academy, faq, hajj, kids are populated and consistent', () {
      final hadith = _json('hadith');
      final topics = (hadith['topics'] as Map).keys.toSet();
      for (final h in (hadith['items'] as List).cast<Map<String, dynamic>>()) {
        expect(topics, contains(h['topic']));
        expect((h['sourceAr'] as String), isNotEmpty);
      }
      expect((_json('seerah')['events'] as List).length, greaterThanOrEqualTo(15));
      expect((_json('stories')['items'] as List).length, greaterThanOrEqualTo(10));
      final courses = (_json('academy')['courses'] as List).cast<Map<String, dynamic>>();
      expect(courses.map((c) => c['id']), containsAll(['wudu', 'prayer', 'pillars', 'iman']));
      final faq = _json('faq');
      final cats = (faq['categories'] as Map).keys.toSet();
      expect((faq['items'] as List).every((f) => cats.contains(f['cat'])), isTrue);
      final kinds = (_json('hajj')['steps'] as List).map((s) => s['kind']).toSet();
      expect(kinds, {'hajj', 'umrah'});
      for (final q in (_json('kids')['quiz'] as List).cast<Map<String, dynamic>>()) {
        expect(q['answer'] as int, inInclusiveRange(0, (q['options'] as List).length - 1));
      }
    });

    test('reciter audio URLs follow the SSSAAA.mp3 pattern', () {
      expect(ayahAudioUrl('Alafasy_128kbps', 2, 255), 'https://everyayah.com/data/Alafasy_128kbps/002255.mp3');
      expect(ayahAudioUrl('Husary_128kbps', 114, 6), 'https://everyayah.com/data/Husary_128kbps/114006.mp3');
      expect(reciters.map((r) => r.id).toSet().length, reciters.length);
    });
  });

  test('favorites toggle, persist and survive bad data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    const item = SavedItem(key: 'hadith:h1', kind: 'hadith', title: 't', body: 'نص', translation: 'text', source: 'src');
    expect(c.read(favoritesProvider.notifier).toggle(item), isTrue);
    expect(c.read(favoritesProvider.notifier).toggle(item), isFalse);
    c.read(favoritesProvider.notifier).toggle(item);

    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(favoritesProvider).single.key, 'hadith:h1');

    SharedPreferences.setMockInitialValues({'library.saved': 'not json'});
    final bad = await SharedPreferences.getInstance();
    final c3 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(bad)]);
    addTearDown(c3.dispose);
    expect(c3.read(favoritesProvider), isEmpty);
  });

  // Every service route builds and shows its title without throwing.
  const routes = {
    '/duas': 'الأدعية',
    '/names': 'الأسماء الحسنى',
    '/planner': 'مخطط العبادات',
    '/zakat': 'الزكاة',
    '/audio': 'الصوتيات',
    '/hadith': 'مكتبة الحديث',
    '/seerah': 'السيرة النبوية',
    '/academy': 'الأكاديمية',
    '/academy/wudu': 'الوضوء',
    '/stories': 'قصص الأنبياء',
    '/library': 'المكتبة',
    '/ask': 'اسأل وتعلّم',
    '/calendar': 'التقويم الهجري',
    '/ramadan': 'رمضان',
    '/hajj': 'الحج والعمرة',
    '/kids': 'ركن الأطفال',
    '/mosques': 'المساجد القريبة',
    '/adhkar/session/evening': 'أذكار المساء',
    '/adhkar/session/quran_duas': 'أدعية من القرآن',
  };
  for (final e in routes.entries) {
    testWidgets('route ${e.key} renders', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
          nowProvider.overrideWithValue(DateTime(2026, 10, 23, 10, 42, 18)),
          contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
        ],
        child: const NoorApp(),
      ));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(e.key);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.text(e.value), findsWidgets);
    });
  }
}
