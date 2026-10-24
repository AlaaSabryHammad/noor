// Renders each main screen to PNG for visual review:
//   flutter test test/screens --update-goldens
//
// Tagged `golden`: the PNGs are rendered on Windows, so Linux CI skips this
// file (`--exclude-tags golden`) and a Windows job runs it separately.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/audio/audio_catalog.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/compass.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_clock.dart';

class _NoCompass implements CompassSource {
  @override
  Stream<CompassReading>? get readings => null;
}

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Future<void> _loadFonts() async {
  final fams = {
    'AmiriQuran': ['AmiriQuran-Regular'],
    'Amiri': ['Amiri-Regular', 'Amiri-Bold'],
    'IBMPlexSansArabic': ['IBMPlexSansArabic-Regular', 'IBMPlexSansArabic-Medium', 'IBMPlexSansArabic-SemiBold', 'IBMPlexSansArabic-Bold'],
    'PlusJakartaSans': ['PlusJakartaSans-Regular', 'PlusJakartaSans-Medium', 'PlusJakartaSans-SemiBold', 'PlusJakartaSans-Bold'],
  };
  for (final e in fams.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await loader.load();
  }
  // Material icons
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);
  final cases = [
    ('home_ar_light', '/home', 'ar', 'light'),
    ('home_en_dark', '/home', 'en', 'dark'),
    ('quran_ar_light', '/quran', 'ar', 'light'),
    ('reader_ar_light', '/quran/reader/1', 'ar', 'light'),
    ('reader_ar_dark_tr', '/quran/reader/1', 'ar', 'dark'),
    ('prayer_ar_light', '/prayer', 'ar', 'light'),
    ('qibla_ar_light', '/qibla', 'ar', 'light'),
    ('adhkar_ar_light', '/adhkar', 'ar', 'light'),
    ('dhikr_ar_light', '/adhkar/session/morning', 'ar', 'light'),
    ('explore_en_light', '/explore', 'en', 'light'),
    ('tasbeeh_ar_dark', '/tasbeeh', 'ar', 'dark'),
    ('duas_ar_light', '/duas', 'ar', 'light'),
    ('dhikr_evening_ar_light', '/adhkar/session/evening', 'ar', 'light'),
    ('names_ar_light', '/names', 'ar', 'light'),
    ('hadith_ar_light', '/hadith', 'ar', 'light'),
    ('library_ar_light', '/library', 'ar', 'light'),
    ('seerah_ar_light', '/seerah', 'ar', 'light'),
    ('stories_ar_dark', '/stories', 'ar', 'dark'),
    ('academy_ar_light', '/academy', 'ar', 'light'),
    ('course_prayer_en_light', '/academy/prayer', 'en', 'light'),
    ('ask_ar_light', '/ask', 'ar', 'light'),
    ('calendar_ar_light', '/calendar', 'ar', 'light'),
    ('calendar_en_dark', '/calendar', 'en', 'dark'),
    ('ramadan_ar_light', '/ramadan', 'ar', 'light'),
    ('hajj_ar_light', '/hajj', 'ar', 'light'),
    ('kids_ar_light', '/kids', 'ar', 'light'),
    ('zakat_ar_light', '/zakat', 'ar', 'light'),
    ('planner_ar_dark', '/planner', 'ar', 'dark'),
    ('mosques_ar_light', '/mosques', 'ar', 'light'),
    ('audio_ar_light', '/audio', 'ar', 'light'),
    ('audio_radio_en_dark', '/audio?tab=radio', 'en', 'dark'),
    ('reciter_ar_light', '/audio/reciter/123', 'ar', 'light'),
    ('khutab_ar_light', '/khutab', 'ar', 'light'),
    ('khutba_ar_light', '/khutab/taqwa', 'ar', 'light'),
    ('khutba_en_dark', '/khutab/farewell', 'en', 'dark'),
    ('audio_lessons_ar_light', '/audio?tab=lessons', 'ar', 'light'),
    ('spotlight_ar_light', '/spotlights/white-days', 'ar', 'light'),
    ('spotlights_en_dark', '/spotlights', 'en', 'dark'),
    ('search_ar_light', '/search?q=%D8%A7%D9%84%D8%B5%D8%A8%D8%B1', 'ar', 'light'),
    ('qada_ar_light', '/qada', 'ar', 'light'),
    ('books_ar_light', '/books', 'ar', 'light'),
    ('book_sections_en_light', '/books/bukhari', 'en', 'light'),
    ('book_nawawi_ar_light', '/books/nawawi/1', 'ar', 'light'),
    ('reader_deep_ar_light', '/quran/reader/2?ayah=255', 'ar', 'light'),
    ('about_ar_light', '/about', 'ar', 'light'),
    ('account_ar_light', '/account', 'ar', 'light'),
  ];
  for (final (name, route, lang, theme) in cases) {
    testWidgets(name, (tester) async {
      SharedPreferences.setMockInitialValues({'settings.locale': lang, 'settings.theme': theme});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
          compassSourceProvider.overrideWithValue(_NoCompass()),
          nowProvider.overrideWithValue(fridayMorning),
          contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
          audioCatalogAutoRefreshProvider.overrideWithValue(false),
        ],
        child: const NoorApp(),
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx).go(route);
      // Asset-backed FutureProviders resolve on real async; let them finish.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
      if (name == 'reader_ar_dark_tr') {
        await tester.tap(find.text('ترجمة المعاني'));
        await tester.pump(const Duration(seconds: 1));
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
    });
  }
}
