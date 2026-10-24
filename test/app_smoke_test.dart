import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/home/home_screen.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/tasbeeh/tasbeeh_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

Future<void> pumpApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size * 3;
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
}

void main() {
  testWidgets('home opens in Arabic, RTL, light mode, Friday greeting', (tester) async {
    await pumpApp(tester);
    expect(find.text('جمعة مباركة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('جمعة مباركة'))), TextDirection.rtl);
    expect(Theme.of(tester.element(find.text('جمعة مباركة'))).brightness, Brightness.light);
    expect(find.text('الصلاة القادمة · وقت الضحى'), findsOneWidget);
  });

  testWidgets('language toggle switches to English LTR', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Jumu‘ah Mubarak'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Jumu‘ah Mubarak'))), TextDirection.ltr);
  });

  testWidgets('bottom nav reaches every tab', (tester) async {
    await pumpApp(tester);
    expect(tester.getRect(find.bySemanticsLabel('الرئيسية').last).top, greaterThan(844 - 100)); // a bottom bar on phones
    for (final (tab, title) in [('القرآن', 'القرآن الكريم'), ('الصلاة', 'مواقيت الصلاة'), ('الأذكار', 'الأذكار'), ('استكشف', 'استكشف')]) {
      await tester.tap(find.bySemanticsLabel(tab).last);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
    }
  });

  testWidgets('tablet: a side rail on the start edge reaches every tab; content is a centred column', (tester) async {
    await pumpApp(tester, size: const Size(1180, 820));
    // Arabic reads right to left, so the rail sits on the right.
    final home = tester.getRect(find.bySemanticsLabel('الرئيسية').last);
    expect(home.left, greaterThan(1180 - 110));
    expect(home.bottom, lessThan(820 - 100));
    final hero = tester.getRect(find.byType(NextPrayerHero));
    expect(hero.width, lessThanOrEqualTo(760));
    expect(hero.left, greaterThan(100)); // centred, not stretched from the edge
    for (final (tab, title) in [('القرآن', 'القرآن الكريم'), ('الصلاة', 'مواقيت الصلاة'), ('الأذكار', 'الأذكار'), ('استكشف', 'استكشف')]) {
      await tester.tap(find.bySemanticsLabel(tab).last);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
    }
  });

  testWidgets('tasbeeh tap increments and persists', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(NoorApp)));
    container.read(tasbeehProvider.notifier).tap();
    container.read(tasbeehProvider.notifier).tap();
    expect(container.read(tasbeehProvider).count, 2);
    expect(container.read(sharedPreferencesProvider).getInt('tasbeeh.count'), 2);
  });
}
