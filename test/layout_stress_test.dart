// Every screen on a small phone (320 dp wide) with enlarged system text, in
// both languages and themes: any RenderFlex overflow or build error fails.
import 'dart:io';

import 'package:flutter/material.dart';
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

class _Noop implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

class _NoCompass implements CompassSource {
  @override
  Stream<CompassReading>? get readings => null;
}

const routes = [
  '/home', '/quran', '/prayer', '/adhkar', '/explore',
  '/quran/reader/1', '/quran/reader/2?ayah=255', '/adhkar/session/morning', '/qibla', '/tasbeeh',
  '/duas', '/names', '/planner', '/zakat', '/audio', '/hadith', '/seerah', '/academy', '/academy/prayer', '/academy/tajweed',
  '/stories', '/library', '/ask', '/calendar', '/ramadan', '/hajj', '/kids', '/mosques', '/books', '/books/bukhari', '/books/nawawi/1', '/about', '/account', '/privacy', '/hisn', '/adhkar/session/hisn_27',
  '/audio?tab=radio', '/audio?tab=favorites', '/audio/reciter/123', '/audio/player', '/khutab', '/khutab/taqwa', '/khutab/farewell',
  '/audio?tab=lessons', '/audio/reciter/118?moshaf=0', '/spotlights', '/spotlights/last-ten', '/spotlights/istighfar', '/search?q=%D8%A7%D9%84%D8%B5%D8%A8%D8%B1', '/qada', '/ask',
];

void main() {
  for (final (lang, theme, scale) in [('ar', 'light', 1.5), ('en', 'dark', 1.3)]) {
    for (final route in routes) {
      testWidgets('$route · $lang/$theme · text ×$scale · 320dp', (tester) async {
        SharedPreferences.setMockInitialValues({'settings.locale': lang, 'settings.theme': theme});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearAllTestValues();
        });
        // Collect every framework error with its widget path so a failure names the culprit.
        final errors = <FlutterErrorDetails>[];
        final original = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = original);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationSchedulerProvider.overrideWithValue(_Noop()),
            compassSourceProvider.overrideWithValue(_NoCompass()),
            nowProvider.overrideWithValue(DateTime(2026, 10, 23, 10, 42, 18)),
            contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
            audioCatalogAutoRefreshProvider.overrideWithValue(false),
          ],
          child: const NoorApp(),
        ));
        await tester.pumpAndSettle();
        // The app opens on /home; only judge it in its own test so every route reports its own overflows.
        if (route != '/home') errors.clear();
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        FlutterError.onError = original;
        expect(errors, isEmpty, reason: errors.map((e) => e.toString().split('\n').take(14).join('\n')).join('\n---\n'));
      });
    }
  }
}
