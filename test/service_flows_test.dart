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
import 'package:shared_preferences/shared_preferences.dart';

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Future<ProviderContainer> _open(WidgetTester tester, String route) async {
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
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
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

  testWidgets('quran duas come straight from the dataset', (tester) async {
    await _open(tester, '/adhkar/session/quran_duas');
    expect(find.textContaining('سورة'), findsWidgets);
  });
}
