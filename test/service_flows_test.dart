import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/core/widgets/noor_widgets.dart';
import 'package:noor/features/library/favorites.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/quran/quran_data.dart';
import 'package:noor/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Future<ProviderContainer> _open(WidgetTester tester, String route, {bool keepPrefs = false}) async {
  if (!keepPrefs) SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
      nowProvider.overrideWithValue(fridayMorning),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
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

void main() {
  testWidgets('saving a hadith puts it in the library', (tester) async {
    final c = await _open(tester, '/hadith');
    final save = find.byIcon(Icons.favorite_border_rounded).first;
    await tester.ensureVisible(save); // the books banner above the list may push the first card below the fold
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(c.read(favoritesProvider), hasLength(1));
    expect(c.read(favoritesProvider).single.kind, 'hadith');

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/library');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    // Un-saving from the library empties it.
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(c.read(favoritesProvider), isEmpty);
    expect(find.text('لا توجد عناصر محفوظة بعد'), findsOneWidget);
  });

  testWidgets('zakat result updates as the user types', (tester) async {
    await _open(tester, '/zakat');
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '60'); // gold price
    await tester.enterText(fields.at(2), '١٠٠٠٠'); // cash (Arabic digits)
    await tester.pump();
    expect(find.text('250'), findsOneWidget); // 2.5% of 10,000, shown in the Latin numerals face
  });

  testWidgets('planner ticking a task persists for the day', (tester) async {
    final c = await _open(tester, '/planner');
    await tester.tap(find.text('صلاة الفجر'));
    await tester.pump();
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('planner.2026-10-23'), ['fajr']);
  });

  testWidgets('kids quiz scores a correct answer', (tester) async {
    await _open(tester, '/kids');
    await tester.tap(find.text('٥').first); // "How many pillars?" → 5
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // let the auto-advance timer finish
  });

  testWidgets('kids quiz offers a fresh set of questions after a finished round', (tester) async {
    await _open(tester, '/kids');
    expect(find.text('كم عدد أركان الإسلام؟'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(NoorCard).first); // the first answer card
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // auto-advance timer
    }
    expect(find.text('أحسنت!'), findsOneWidget);
    await tester.tap(find.text('البدء من جديد'));
    await tester.pump();
    expect(find.text('كم عدد أركان الإسلام؟'), findsNothing, reason: 'the next round must not start with the same question');
    expect(find.text('ما اسم أول سورة نزلت من القرآن؟'), findsOneWidget);
  });

  testWidgets('hajj screen has a basics tab with the miqats', (tester) async {
    await _open(tester, '/hajj');
    expect(find.text('المواقيت'), findsNothing);
    await tester.tap(find.text('أساسيات'));
    await tester.pump();
    expect(find.text('المواقيت'), findsOneWidget);
    expect(find.text('أنواع النسك'), findsOneWidget);
  });

  testWidgets('hadith screen links to the books library', (tester) async {
    await _open(tester, '/hadith');
    await tester.tap(find.text('مكتبة كتب الحديث'));
    await tester.pumpAndSettle();
    expect(find.text('الأربعون النووية'), findsWidgets);
  });

  testWidgets('reader opens at the requested ayah deep inside a long surah', (tester) async {
    await _open(tester, '/quran/reader/2?ayah=255');
    // Ayat al-Kursi is ayah 255 of 286; the lazy list must have jumped there.
    Finder rich(String word) => find.byWidgetPredicate((w) => w is RichText && normalizeArabic(w.text.toPlainText()).contains(word));
    expect(rich('القيوم'), findsWidgets);
    expect(rich('ذلك الكتاب لا ريب'), findsNothing); // ayah 2 (first paragraph) is far above
  });

  testWidgets('reader resumes the saved bookmark and records pages read', (tester) async {
    SharedPreferences.setMockInitialValues({'quran.lastSurah': 18, 'quran.lastAyah': 60});
    final c = await _open(tester, '/quran/reader/18', keepPrefs: true);
    await tester.pump(const Duration(seconds: 1)); // bookmark debounce
    final p = c.read(readingProgressProvider);
    expect(p.surah, 18);
    expect(p.ayah, greaterThanOrEqualTo(55)); // near where we left off, not ayah 1
    expect(p.pagesRead, greaterThan(0));
  });

  testWidgets('translation mode shows one card per ayah and can be switched back', (tester) async {
    await _open(tester, '/quran/reader/1');
    await tester.tap(find.text('ترجمة المعاني'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entirely Merciful'), findsWidgets);
    await tester.tap(find.text('مصحف'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entirely Merciful'), findsNothing);
  });

  testWidgets('quran search finds ayahs by plain-letter words and jumps by reference', (tester) async {
    await _open(tester, '/quran');
    await tester.enterText(find.byType(TextField), 'كرسيه'); // plain letters, no harakat
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('البقرة', findRichText: true), findsWidgets);

    await tester.enterText(find.byType(TextField), '2:255');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('اذهب إلى السورة'), findsOneWidget);
  });

  testWidgets('settings sheet scrolls, changes Quran text size, and links to the credits screen', (tester) async {
    final c = await _open(tester, '/home');
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('حجم خط القرآن'), findsOneWidget);
    final before = c.read(settingsProvider).quranFontSize;
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();
    expect(c.read(settingsProvider).quranFontSize, isNot(before));

    await tester.ensureVisible(find.text('حول التطبيق والإسناد'));
    await tester.tap(find.text('حول التطبيق والإسناد'));
    await tester.pumpAndSettle();
    expect(find.text('المصادر والإسناد'), findsOneWidget);
    expect(find.text('CC BY 3.0'), findsOneWidget);
  });

  testWidgets('quran duas come straight from the dataset', (tester) async {
    await _open(tester, '/adhkar/session/quran_duas');
    expect(find.textContaining('سورة'), findsWidgets);
  });
}
