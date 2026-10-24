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

    test('Hisn al-Muslim: 132 chapters / 267 adhkar, Arabic + English, sane counts, every chapter in a group', () {
      final h = _json('hisn');
      final cats = (h['categories'] as List).cast<Map<String, dynamic>>();
      final groups = (h['groups'] as List).map((g) => g['id']).toSet();
      expect(cats.length, 132);
      expect(cats.fold<int>(0, (n, c) => n + (c['items'] as List).length), 267);
      expect(cats.map((c) => c['id']).toSet().length, 132);
      for (final c in cats) {
        expect(groups, contains(c['group']), reason: 'chapter ${c['id']}');
        expect((c['titleAr'] as String).trim(), isNotEmpty);
        for (final i in (c['items'] as List).cast<Map<String, dynamic>>()) {
          expect((i['ar'] as String).trim(), isNotEmpty);
          expect((i['en'] as String).trim(), isNotEmpty);
          expect(i['repeat'] as int, inInclusiveRange(1, 100));
          // presentation-form glyphs were folded to plain letters (the ornate Quran brackets U+FD3E/F are legitimate)
          expect(RegExp('[\u{FB50}-\u{FD3D}\u{FD40}-\u{FDFF}\u{FE70}-\u{FEFF}]').hasMatch(i['ar'] as String), isFalse);
        }
      }
      final morning = cats.firstWhere((c) => c['id'] == 27);
      final nine = (morning['items'] as List).firstWhere((i) => i['id'] == 9);
      expect(nine['repeat'], 7, reason: 'the text says seven times');
    });

    test('Quranic adhkar match the dataset verbatim', () {
      final baqarah = jsonDecode(File('assets/data/quran/002.json').readAsStringSync()) as List;
      final kursi = (baqarah[254] as Map)['ar'];
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
      final hadithItems = (hadith['items'] as List).cast<Map<String, dynamic>>();
      expect(hadithItems.length, greaterThanOrEqualTo(60));
      expect(hadithItems.map((h) => h['id']).toSet().length, hadithItems.length);
      expect(hadithItems.map((h) => h['topic']).toSet(), topics, reason: 'every topic has hadith');
      for (final h in hadithItems) {
        expect((h['en'] as String).trim(), isNotEmpty, reason: h['id'] as String);
      }

      final events = (_json('seerah')['events'] as List).cast<Map<String, dynamic>>();
      expect(events.length, greaterThanOrEqualTo(30));
      expect(events.map((e) => e['titleAr']).toSet().length, events.length, reason: 'no duplicated seerah events');
      final titles = events.map((e) => e['titleAr']).toList();
      expect(titles.indexOf('الهجرة إلى المدينة'), lessThan(titles.indexOf('غزوة بدر')));
      expect(titles.indexOf('غزوة مؤتة'), lessThan(titles.indexOf('فتح مكة')));
      expect(titles.indexOf('غزوة تبوك'), lessThan(titles.indexOf('عام الوفود')));

      final stories = (_json('stories')['items'] as List).cast<Map<String, dynamic>>();
      expect(stories.length, greaterThanOrEqualTo(25));
      expect(stories.map((s) => s['nameAr']).toSet().length, stories.length);
      for (final s in stories) {
        expect((s['refAr'] as String).trim(), isNotEmpty, reason: s['nameAr'] as String);
      }

      final courses = (_json('academy')['courses'] as List).cast<Map<String, dynamic>>();
      expect(courses.length, greaterThanOrEqualTo(15));
      expect(courses.map((c) => c['id']), containsAll(['wudu', 'ghusl', 'prayer', 'pillars', 'iman', 'fasting', 'zakat', 'tajweed']));
      expect(courses.map((c) => c['id']).toSet().length, courses.length);
      for (final c in courses) {
        expect((c['lessons'] as List).length, greaterThanOrEqualTo(4), reason: c['id'] as String);
      }

      final faq = _json('faq');
      final cats = (faq['categories'] as Map).keys.toSet();
      final faqItems = (faq['items'] as List).cast<Map<String, dynamic>>();
      expect(faqItems.length, greaterThanOrEqualTo(40));
      expect(faqItems.every((f) => cats.contains(f['cat'])), isTrue);
      expect(cats, containsAll(['purity', 'quran']));
      expect(faqItems.map((f) => f['cat']).toSet(), cats, reason: 'every category has questions');

      final steps = (_json('hajj')['steps'] as List).cast<Map<String, dynamic>>();
      expect(steps.map((s) => s['kind']).toSet(), {'hajj', 'umrah', 'guide'});

      final quiz = (_json('kids')['quiz'] as List).cast<Map<String, dynamic>>();
      expect(quiz.length, greaterThanOrEqualTo(40));
      expect(quiz.map((q) => q['qAr']).toSet().length, quiz.length, reason: 'no repeated question');
      for (final q in quiz) {
        final options = (q['options'] as List).cast<Map<String, dynamic>>();
        expect(options.length, inInclusiveRange(2, 3));
        expect(options.map((o) => o['ar']).toSet().length, options.length, reason: q['qAr'] as String);
        expect(q['answer'] as int, inInclusiveRange(0, options.length - 1));
      }
      expect((_json('kids')['manners'] as List).length, greaterThanOrEqualTo(12));
    });

    test('daily light pools are rich enough to rotate for weeks without repeating', () {
      final d = _json('daily');
      expect((d['ayah'] as List).length, greaterThanOrEqualTo(40));
      expect((d['hadith'] as List).length, greaterThanOrEqualTo(60));
      expect((d['dua'] as List).length, greaterThanOrEqualTo(50));
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
    '/hisn': 'حصن المسلم',
    '/adhkar/session/hisn_27': 'أذكار الصباح والمساء',
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
