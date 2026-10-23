import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/books/books_data.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Noop implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

class _MemoryCache implements TextCache {
  final store = <String, String>{};
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> write(String key, String value) async => store[key] = value;
}

class _FakeFetcher implements BookFetcher {
  _FakeFetcher({this.fail = false});
  bool fail;
  final urls = <String>[];

  @override
  Future<String> get(Uri url) async {
    urls.add(url.toString());
    if (fail) throw const SocketException('offline');
    final ar = url.path.contains('/ara-');
    return jsonEncode({
      'metadata': {'name': 'x'},
      'hadiths': [
        {'hadithnumber': 59, 'text': ar ? 'نص عربي' : 'English text', 'grades': ar ? [] : [{'name': 'Darussalam', 'grade': 'Sahih'}]},
        {'hadithnumber': 60, 'text': ar ? 'نص ثان' : 'Second', 'grades': []},
      ],
    });
  }
}

Future<String> _load(String p) async => File(p).readAsStringSync();

DatasetBooksRepository _repo({_FakeFetcher? fetcher, _MemoryCache? cache}) => DatasetBooksRepository(loader: _load, fetcher: fetcher ?? _FakeFetcher(), cache: cache ?? _MemoryCache());

void main() {
  test('catalog lists bundled and online books with section indexes', () async {
    final books = await _repo().catalog();
    expect(books.map((b) => b.id), containsAll(['nawawi', 'qudsi', 'dehlawi', 'bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah', 'malik']));
    expect(books.where((b) => b.bundled).map((b) => b.id).toSet(), {'nawawi', 'qudsi', 'dehlawi'});
    final bukhari = books.firstWhere((b) => b.id == 'bukhari');
    expect(bukhari.sections.length, 97);
    expect(bukhari.sections.first.title, 'Revelation');
  });

  test('bundled books read offline: forty hadith of an-Nawawi, Arabic and English', () async {
    final repo = _repo(fetcher: _FakeFetcher(fail: true)); // any network use would throw
    final nawawi = (await repo.catalog()).firstWhere((b) => b.id == 'nawawi');
    final list = await repo.section(nawawi, 1);
    expect(list.length, 42);
    expect(list.first.n, 1);
    expect(list.first.ar, contains('إنَّمَا الْأَعْمَالُ'));
    expect(list.first.en.toLowerCase(), contains('motives'));
    expect(await repo.isAvailableOffline(nawawi, 1), isTrue);
  });

  test('every bundled hadith has Arabic text and belongs to a real section', () async {
    final repo = _repo();
    for (final b in (await repo.catalog()).where((b) => b.bundled)) {
      var total = 0;
      for (final s in b.sections) {
        for (final h in await repo.section(b, s.n)) {
          expect(h.ar.trim(), isNotEmpty, reason: '${b.id} ${h.n}');
          total++;
        }
      }
      expect(total, b.count, reason: b.id);
    }
  });

  test('online sections are fetched once (Arabic + English), merged, then served from the cache', () async {
    final fetcher = _FakeFetcher();
    final cache = _MemoryCache();
    final repo = _repo(fetcher: fetcher, cache: cache);
    final bukhari = (await repo.catalog()).firstWhere((b) => b.id == 'bukhari');
    expect(await repo.isAvailableOffline(bukhari, 3), isFalse);

    final first = await repo.section(bukhari, 3);
    expect(first.map((h) => h.n), [59, 60]);
    expect(first.first.ar, 'نص عربي');
    expect(first.first.en, 'English text');
    expect(first.first.grade, 'Sahih');
    expect(fetcher.urls.length, 2);
    expect(fetcher.urls.first, endsWith('/editions/ara-bukhari/sections/3.json'));

    final second = await repo.section(bukhari, 3);
    expect(second.length, 2);
    expect(fetcher.urls.length, 2, reason: 'second read must come from the cache');
    expect(await repo.isAvailableOffline(bukhari, 3), isTrue);
  });

  test('offline with nothing cached → BookUnavailable; nothing is cached on failure', () async {
    final cache = _MemoryCache();
    final repo = _repo(fetcher: _FakeFetcher(fail: true), cache: cache);
    final muslim = (await repo.catalog()).firstWhere((b) => b.id == 'muslim');
    await expectLater(repo.section(muslim, 1), throwsA(isA<BookUnavailable>()));
    expect(cache.store, isEmpty);
  });

  Future<ProviderContainer> open(WidgetTester tester, String route, {BookFetcher? fetcher}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(_Noop()),
        nowProvider.overrideWithValue(DateTime(2026, 10, 23, 10, 42, 18)),
        contentLoaderProvider.overrideWithValue(_load),
        bookFetcherProvider.overrideWithValue(fetcher ?? _FakeFetcher()),
        textCacheProvider.overrideWithValue(_MemoryCache()),
      ],
      child: const NoorApp(),
    ));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    return ProviderScope.containerOf(tester.element(find.byType(NoorApp)));
  }

  testWidgets('books screen lists the collections and opens a bundled book straight to its hadith', (tester) async {
    await open(tester, '/books');
    expect(find.text('الأربعون النووية'), findsOneWidget);
    expect(find.text('صحيح البخاري'), findsOneWidget);
    await tester.tap(find.text('الأربعون النووية'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('إنَّمَا الْأَعْمَالُ', findRichText: true), findsWidgets);
  });

  testWidgets('an online book lists its sections', (tester) async {
    await open(tester, '/books/bukhari');
    expect(find.text('Revelation'), findsOneWidget);
    expect(find.text('Belief'), findsOneWidget);
  });

  testWidgets('an unreachable section offers a retry instead of crashing', (tester) async {
    await open(tester, '/books/bukhari/3', fetcher: _FakeFetcher(fail: true));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('a reachable online section shows its hadith with the grade', (tester) async {
    await open(tester, '/books/bukhari/3');
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('نص عربي'), findsOneWidget);
    expect(find.text('Sahih'), findsOneWidget);
  });

  testWidgets('the Library tab switches between saved items and books', (tester) async {
    await open(tester, '/library');
    expect(find.text('لا توجد عناصر محفوظة بعد'), findsOneWidget);
    await tester.tap(find.text('الكتب'));
    await tester.pumpAndSettle();
    expect(find.text('الأربعون النووية'), findsOneWidget);
  });
}
