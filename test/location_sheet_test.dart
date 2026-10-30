import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/location_service.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/data/place_names.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/prayer/prayer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _Scheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

class _NoMap implements PlaceNamer {
  const _NoMap();
  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async => null;
  @override
  Future<List<PlaceHit>> search(String query) async => const [];
}

class _Gps implements LocationService {
  _Gps(this.result);
  LocationResult result;
  int calls = 0;
  @override
  Future<LocationResult> current({bool prompt = true}) async {
    calls++;
    return result;
  }
}

Future<(_Gps, List<LocationFailure>)> _open(WidgetTester tester, LocationResult first) async {
  SharedPreferences.setMockInitialValues({'prayer.location.asked': true}); // skip the automatic first-launch request
  final prefs = await SharedPreferences.getInstance();
  final gps = _Gps(first);
  final opened = <LocationFailure>[];
  tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_Scheduler()),
      locationServiceProvider.overrideWithValue(gps),
      placeNamerProvider.overrideWithValue(const _NoMap()), // no map service in tests (the real one would load the bundled list in an isolate)
      openLocationSettingsProvider.overrideWithValue((f) async {
        opened.add(f);
        return true;
      }),
      nowProvider.overrideWithValue(fridayMorning),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
    ],
    child: const NoorApp(),
  ));
  await tester.pumpAndSettle();
  // The home screen asks to set the location while times are for the default city.
  await tester.tap(find.text('حدّد موقعي'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('استخدام موقعي الحالي'));
  await tester.pumpAndSettle();
  return (gps, opened);
}

void main() {
  testWidgets('a remembered position says how old it is and what to do', (tester) async {
    await _open(tester, const LocationResult.ok(28.4328, 45.9708, age: Duration(minutes: 70), accuracyMeters: 20));
    expect(find.textContaining('من آخر موقع معروف قبل ٧٠ دقيقة'), findsOneWidget);
    expect(find.textContaining('اخرج إلى مكان مفتوح'), findsOneWidget);
    expect(find.text('حدّد موقعي'), findsNothing, reason: 'the default-city card is gone: a location is now chosen');
  });

  testWidgets('a new fix reports its accuracy', (tester) async {
    await _open(tester, const LocationResult.ok(28.4328, 45.9708, accuracyMeters: 20));
    expect(find.textContaining('دقة ±٢٠ م'), findsOneWidget);
  });

  testWidgets('permission refused for good: the message offers the app’s settings page', (tester) async {
    final (_, opened) = await _open(tester, const LocationResult.fail(LocationFailure.deniedForever));
    expect(find.textContaining('الإذن مرفوض نهائيًا'), findsOneWidget);
    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pump();
    expect(opened, [LocationFailure.deniedForever]);
  });

  testWidgets('location switched off: the message offers the location settings', (tester) async {
    final (_, opened) = await _open(tester, const LocationResult.fail(LocationFailure.serviceOff));
    expect(find.textContaining('خدمة الموقع متوقفة'), findsOneWidget);
    await tester.tap(find.text('تفعيل الموقع'));
    await tester.pump();
    expect(opened, [LocationFailure.serviceOff]);
  });

  testWidgets('no fix: “try again” asks the GPS again and then succeeds', (tester) async {
    final (gps, _) = await _open(tester, const LocationResult.fail(LocationFailure.unavailable));
    final before = gps.calls;
    expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
    gps.result = const LocationResult.ok(26.2794, 50.2083);
    await tester.tap(find.text('حاول مجددًا'));
    await tester.pumpAndSettle();
    expect(gps.calls, before + 1);
    // Success closes the sheet; the home card asking for a location is gone.
    expect(find.text('حدّد موقعي'), findsNothing);
  });
}
