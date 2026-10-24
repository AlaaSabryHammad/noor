import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/audio/audio_catalog.dart';
import 'package:noor/features/audio/audio_widgets.dart';
import 'package:noor/features/audio/quran_player.dart';
import 'package:noor/features/books/books_data.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

/// Records calls and lets the test drive the streams a real player would emit.
class FakeBackend implements AudioBackend {
  final playingC = StreamController<bool>.broadcast(), indexC = StreamController<int>.broadcast(), errorsC = StreamController<Object>.broadcast(), completedC = StreamController<void>.broadcast();
  List<Uri> loaded = const [];
  int loadIndex = -1;
  Duration loadPosition = Duration.zero, pos = Duration.zero;
  double speed = 1;
  ListenRepeat repeat = ListenRepeat.off;
  final seeks = <(Duration, int?)>[];
  int plays = 0, pauses = 0;
  bool failLoad = false;

  @override
  Stream<bool> get playing => playingC.stream;
  @override
  Stream<int> get index => indexC.stream;
  @override
  Stream<bool> get loading => const Stream.empty();
  @override
  Stream<void> get completed => completedC.stream;
  @override
  Stream<Object> get errors => errorsC.stream;
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration?> get duration => const Stream.empty();
  @override
  Duration get currentPosition => pos;

  bool? arabic;

  @override
  Future<void> load(List<AudioTrack> tracks, {int index = 0, Duration position = Duration.zero, bool arabic = true}) async {
    if (failLoad) throw const SocketException('offline');
    loaded = [for (final t in tracks) t.url];
    this.arabic = arabic;
    loadIndex = index;
    loadPosition = position;
    indexC.add(index);
  }

  @override
  Future<void> play() async {
    plays++;
    playingC.add(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    playingC.add(false);
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    seeks.add((position, index));
    if (index != null) indexC.add(index);
  }

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;
  @override
  Future<void> setRepeat(ListenRepeat mode) async => repeat = mode;
  @override
  Future<void> dispose() async {}
}

class _MemoryCache implements TextCache {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

class _Fetcher implements BookFetcher {
  _Fetcher(this.respond);
  final String Function(Uri) respond;
  final asked = <Uri>[];
  @override
  Future<String> get(Uri url) async {
    asked.add(url);
    return respond(url);
  }
}

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Map<String, dynamic> _snapshot() => jsonDecode(File('assets/data/audio.json').readAsStringSync()) as Map<String, dynamic>;

AudioTrack _track(int n) => AudioTrack(key: 's:1:1:$n', titleAr: 'سورة $n', titleEn: 'Surah $n', subtitleAr: 'قارئ', subtitleEn: 'Reciter', url: Uri.parse('https://example.com/${n.toString().padLeft(3, '0')}.mp3'), surah: n, reciterId: 1, moshafId: 1);

Future<(ProviderContainer, FakeBackend)> _player() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final backend = FakeBackend();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioBackendFactoryProvider.overrideWithValue(() => backend),
  ]);
  addTearDown(c.dispose);
  return (c, backend);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('catalogue', () {
    final catalog = AudioCatalog.fromSnapshot(_snapshot());

    test('bundled snapshot has the reciters and radios with clean names', () {
      expect(catalog.reciters.length, greaterThan(200));
      expect(catalog.radios.length, greaterThan(100));
      for (final r in [...catalog.reciters.map((e) => e.nameAr), ...catalog.radios.map((e) => e.nameAr)]) {
        expect(r, isNot(contains('--')), reason: r);
        expect(r.trim(), r);
      }
      for (final id in featuredReciterIds) {
        expect(catalog.reciter(id), isNotNull, reason: 'featured reciter $id');
      }
    });

    test('Alafasy: complete Hafs mushaf first, surah URLs are NNN.mp3', () {
      final r = catalog.reciter(123)!;
      expect(r.nameEn, contains('Alafasi'));
      final m = r.moshaf.first;
      expect(m.complete, isTrue);
      expect(m.surahs, [for (var i = 1; i <= 114; i++) i]);
      expect(m.surahUrl(2).toString(), endsWith('/002.mp3'));
      expect(m.surahUrl(2).scheme, 'https');
    });

    test('topic stations are told apart from reciter stations', () {
      expect(catalog.radio(116)!.thematic, isTrue); // tafsir
      expect(catalog.radio(10906)!.thematic, isTrue); // morning adhkar
      expect(catalog.radio(3)!.thematic, isFalse); // Ahmad al-Ajmy
      expect(catalog.radio(91)!.thematic, isFalse); // Ibrahim al-Dosari
      expect(catalog.radio(116)!.nameEn, isNot(startsWith('Radio ')));
      expect(catalog.radio(116)!.kind, RadioKind.lesson); // tafsir series
      expect(catalog.radio(10906)!.kind, RadioKind.quran); // morning adhkar
      expect(catalog.radio(109046)!.kind, RadioKind.translation);
      expect(catalog.radio(3)!.kind, RadioKind.reciter);
    });

    test('recording styles come from moshaf_type; murattal is the default recording', () {
      final styles = {for (final r in catalog.reciters) for (final m in r.moshaf) m.style};
      expect(styles, containsAll(RecitationStyle.values));
      expect(styleOf(11), RecitationStyle.murattal);
      expect(styleOf(12), RecitationStyle.mujawwad);
      expect(styleOf(213), RecitationStyle.muallim);
      // Husary has five recordings; the complete murattal Hafs one comes first.
      final husary = catalog.reciter(118)!;
      expect(husary.moshaf.first.style, RecitationStyle.murattal);
      expect(husary.moshaf.first.rewayaId, 1);
      expect(husary.moshaf.first.complete, isTrue);
      expect(husary.moshaf.any((m) => m.style == RecitationStyle.mujawwad), isTrue);
    });

    test('audio tafsir covers every surah in order and finds the part for an ayah', () {
      expect({for (final p in catalog.tafsir) p.surah}, hasLength(114));
      expect(catalog.tafsirName, contains('الطبري'));
      final baqara = catalog.tafsirOf(2);
      expect(baqara.length, greaterThan(5));
      expect(baqara.first.from, 1);
      final i = catalog.tafsirIndexFor(2, 255);
      expect(catalog.tafsir[i].surah, 2);
      expect(catalog.tafsir[i].covers(255), isTrue);
      expect(catalog.tafsir[catalog.tafsirIndexFor(1, 3)].wholeSurah, isTrue);
      expect(catalog.tafsirIndexFor(200, 1), -1);
    });

    test('videos parse with their category', () {
      expect(catalog.videos.length, greaterThan(40));
      expect(catalog.videos.every((v) => v.url.startsWith('https://')), isTrue);
      expect(catalog.videoTypes[2], isNotEmpty);
      expect(videoTypeName(2, catalog.videoTypes[2]!, false), contains('Prophet'));
      expect(catalog.video(catalog.videos.first.id), isNotNull);
    });

    test('continue-listening labels for a surah, a radio and the tafsir', () {
      final surahs = [const Surah(number: 2, nameAr: 'البقرة', nameEn: 'Al-Baqara', revelation: Revelation.medinan, ayahCount: 286, startPage: 2)];
      expect(describeLastListen(const LastListen(reciterId: 123, surah: 2), catalog, surahs, true)!.title, 'سورة البقرة');
      expect(describeLastListen(const LastListen(radioId: 116), catalog, surahs, false)!.subtitle, 'Live');
      final part = catalog.tafsirOf(2).first;
      expect(describeLastListen(LastListen(tafsirId: part.id), catalog, surahs, true)!.title, 'تفسير سورة البقرة');
      expect(describeLastListen(const LastListen(reciterId: 999999, surah: 2), catalog, surahs, true), isNull);
      expect(LastListen.fromJson({'t': part.id})!.tafsirId, part.id);
    });

    test('partial surah lists parse; empty recordings are dropped', () {
      final c = AudioCatalog.fromApi(
        recitersAr: [
          {'id': 1, 'name': 'أ', 'moshaf': [{'id': 9, 'name': 'ورش - مرتل', 'server': 'https://s/', 'surah_list': '1, 2,115,x', 'rewaya_id': 2}]},
          {'id': 2, 'name': 'ب', 'moshaf': [{'id': 8, 'name': 'x', 'server': 'https://s/', 'surah_list': '', 'rewaya_id': 1}]},
        ],
        recitersEn: const [],
        radiosAr: const [],
        radiosEn: const [],
      );
      expect(c.reciters.single.moshaf.single.surahs, [1, 2]);
      expect(c.reciters.single.nameEn, 'أ'); // falls back to Arabic
    });

    test('repository prefers the cached refresh, and refresh keeps only complete answers', () async {
      final cache = _MemoryCache();
      final snap = _snapshot();
      final fetcher = _Fetcher((u) {
        final q = u.toString();
        final lang = q.contains('language=ar') ? 'ar' : 'en';
        if (q.contains('/reciters')) return jsonEncode({'reciters': (snap['reciters'] as Map)[lang]});
        if (q.contains('/radios')) return jsonEncode({'radios': (snap['radios'] as Map)[lang]});
        if (q.contains('/tafsir')) return jsonEncode({'tafasir': snap['tafsir']});
        if (q.contains('/video_types')) return jsonEncode({'video_types': ((snap['videos'] as Map)['types'] as Map)['ar']});
        return jsonEncode({'videos': (snap['videos'] as Map)['items']});
      });
      final repo = AudioCatalogRepository(loader: (p) async => File(p).readAsStringSync(), fetcher: fetcher, cache: cache);
      expect((await repo.load()).reciters.length, greaterThan(200));
      await repo.refresh();
      expect(fetcher.asked, hasLength(7));
      expect(cache.m.keys, contains('audio-catalog-v2'));

      // A tiny answer is ignored rather than replacing the cached catalogue.
      final small = _MemoryCache();
      final bad = AudioCatalogRepository(loader: (p) async => File(p).readAsStringSync(), fetcher: _Fetcher((u) => jsonEncode({'reciters': [], 'radios': [], 'tafasir': {'soar': []}, 'videos': [], 'video_types': []})), cache: small);
      await bad.refresh();
      expect(small.m, isEmpty);

      // A broken cache falls back to the bundled file.
      cache.m['audio-catalog-v2'] = '{nope';
      expect((await repo.load()).reciters, isNotEmpty);
    });
  });

  group('player', () {
    test('plays a queue from the chosen track with saved speed and repeat', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      p.cycleSpeed(); // 1.25
      p.cycleRepeat(); // one
      await p.playQueue([_track(1), _track(2), _track(3)], start: 1);
      await _settle();
      final s = c.read(quranPlayerProvider);
      expect(b.loaded, hasLength(3));
      expect(b.loadIndex, 1);
      expect(b.arabic, isTrue); // lock-screen titles follow the app language
      expect(b.speed, 1.25);
      expect(b.repeat, ListenRepeat.one);
      expect(s.current!.surah, 2);
      expect(s.playing, isTrue);
      expect(c.read(lastListenProvider)!.surah, 2);
      expect(c.read(sharedPreferencesProvider).getDouble('audio.listenSpeed'), 1.25);
    });

    test('next, previous restarts the track after 3 s, skipTo', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      await p.playQueue([_track(1), _track(2), _track(3)]);
      await p.next();
      await _settle();
      expect(c.read(quranPlayerProvider).index, 1);
      b.pos = const Duration(seconds: 10);
      await p.previous();
      expect(b.seeks.last, (Duration.zero, null));
      b.pos = const Duration(seconds: 1);
      await p.previous();
      await _settle();
      expect(c.read(quranPlayerProvider).index, 0);
      await p.skipTo(2);
      await _settle();
      expect(c.read(quranPlayerProvider).current!.surah, 3);
    });

    test('"end of surah" pauses when the next track starts', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      await p.playQueue([_track(1), _track(2)]);
      p.sleepAtEndOfTrack();
      expect(c.read(quranPlayerProvider).stopAfterTrack, isTrue);
      b.indexC.add(1);
      await _settle();
      expect(b.pauses, 1);
      expect(c.read(quranPlayerProvider).stopAfterTrack, isFalse);
    });

    test('sleep timer pauses after the delay and can be cancelled', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      await p.playQueue([_track(1)]);
      p.setSleepTimer(const Duration(milliseconds: 20));
      expect(c.read(quranPlayerProvider).sleepAt, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(b.pauses, 1);
      expect(c.read(quranPlayerProvider).sleepAt, isNull);
      p.setSleepTimer(const Duration(milliseconds: 20));
      p.setSleepTimer(null);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(b.pauses, 1);
    });

    test('a failed load is reported and retried by play', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      b.failLoad = true;
      await p.playQueue([_track(1)]);
      expect(c.read(quranPlayerProvider).failed, isTrue);
      b.failLoad = false;
      await p.toggle();
      await _settle();
      expect(c.read(quranPlayerProvider).failed, isFalse);
      expect(c.read(quranPlayerProvider).playing, isTrue);
    });

    test('radio ignores speed/repeat/seek; close clears the queue', () async {
      final (c, b) = await _player();
      final p = c.read(quranPlayerProvider.notifier);
      p.cycleSpeed();
      final radio = radioTrack(const QuranRadio(id: 5, nameAr: 'إذاعة', nameEn: 'Radio', url: 'https://r/x', kind: RadioKind.lesson));
      await p.playQueue([radio]);
      expect(b.speed, 1);
      await p.seek(const Duration(seconds: 30));
      expect(b.seeks, isEmpty);
      expect(c.read(lastListenProvider)!.radioId, 5);
      await p.close();
      expect(c.read(quranPlayerProvider).current, isNull);
    });

    test('LastListen survives a round trip and rejects incomplete data', () {
      const l = LastListen(reciterId: 1, moshafId: 2, surah: 3, position: Duration(seconds: 4));
      final back = LastListen.fromJson(jsonDecode(jsonEncode(l.toJson())))!;
      expect((back.reciterId, back.moshafId, back.surah, back.position), (1, 2, 3, const Duration(seconds: 4)));
      expect(LastListen.fromJson({'r': 1}), isNull);
      expect(LastListen.fromJson('x'), isNull);
    });
  });

  group('screens', () {
    Future<(ProviderContainer, FakeBackend)> pump(WidgetTester tester, {double width = 390, double scale = 1}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backend = FakeBackend();
      tester.view.physicalSize = Size(width * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
          nowProvider.overrideWithValue(fridayMorning),
          contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
          audioCatalogAutoRefreshProvider.overrideWithValue(false),
          audioBackendFactoryProvider.overrideWithValue(() => backend),
        ],
        child: const NoorApp(),
      ));
      await tester.pumpAndSettle();
      return (ProviderScope.containerOf(tester.element(find.byType(NoorApp))), backend);
    }

    Future<void> go(WidgetTester tester, String route) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('tapping a surah on a reciter page plays it; the mini player appears in the tabs', (tester) async {
      final (c, backend) = await pump(tester);
      await go(tester, '/audio/reciter/123');
      expect(find.text('مشاري العفاسي'), findsWidgets);
      await tester.tap(find.text('سورة البقرة'));
      await tester.pump();
      expect(backend.loaded, hasLength(114));
      expect(backend.loadIndex, 1);
      expect(c.read(quranPlayerProvider).current!.titleAr, 'سورة البقرة');
      await go(tester, '/home');
      expect(find.byType(MiniPlayer), findsOneWidget);
      // The pause button in the mini player pauses the backend.
      await tester.tap(find.descendant(of: find.byType(MiniPlayer), matching: find.byIcon(Icons.pause_rounded)));
      await tester.pump();
      expect(backend.pauses, 1);
    });

    testWidgets('radio tab plays a live station; the full player shows LIVE', (tester) async {
      final (c, backend) = await pump(tester);
      await go(tester, '/audio?tab=radio');
      await tester.tap(find.text('العامة - متنوعة لمختلف القراء'));
      await tester.pump();
      expect(c.read(quranPlayerProvider).current!.live, isTrue);
      expect(backend.loaded.single.host, 'backup.qurango.net');
      await go(tester, '/audio/player');
      expect(find.text('مباشر'), findsOneWidget);
    });

    testWidgets('lessons tab plays the audio tafsir from a surah onwards', (tester) async {
      final (c, backend) = await pump(tester);
      await go(tester, '/audio?tab=lessons');
      expect(find.text('التفسير الصوتي'), findsOneWidget);
      await tester.ensureVisible(find.text('تفسير سورة البقرة'));
      await tester.tap(find.text('تفسير سورة البقرة'));
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
      }
      final current = c.read(quranPlayerProvider).current!;
      expect(current.tafsirId, isNotNull);
      expect(current.surah, 2);
      expect(backend.loaded.length, greaterThan(300)); // the whole tafsir, starting at al-Baqarah
      expect(c.read(lastListenProvider)!.tafsirId, current.tafsirId);
    });

    testWidgets('home and player fit a 320 dp phone with large text while audio plays', (tester) async {
      final (c, _) = await pump(tester, width: 320, scale: 1.5);
      final errors = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = original);
      final index = await tester.runAsync(() => c.read(quranIndexProvider.future));
      final catalog = await tester.runAsync(() => c.read(audioCatalogProvider.future));
      final r = catalog!.reciter(118)!;
      await c.read(quranPlayerProvider.notifier).playQueue(surahTracks(r, r.moshaf.first, index!.surahs), start: 113);
      await go(tester, '/home');
      await go(tester, '/audio/player');
      FlutterError.onError = original;
      expect(errors, isEmpty, reason: errors.map((e) => e.toString().split('\n').take(12).join('\n')).join('\n---\n'));
    });
  });
}
