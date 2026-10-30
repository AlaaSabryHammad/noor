import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/features/prayer/data/offline_places.dart';
import 'package:noor/features/prayer/data/place_names.dart';

void main() {
  late OfflinePlaces places;
  setUpAll(() => places = OfflinePlaces.parse(File('assets/data/places.json').readAsStringSync()));

  group('the bundled list of towns', () {
    test('is large, and every entry is usable', () {
      expect(places.length, greaterThan(40000));
      final data = jsonDecode(File('assets/data/places.json').readAsStringSync()) as Map<String, dynamic>;
      final countries = (data['countries'] as Map).keys.toSet();
      for (final r in (data['places'] as List).cast<List<dynamic>>()) {
        expect((r[0] as String).trim(), isNotEmpty);
        expect((r[2] as num).abs() <= 90 && (r[3] as num).abs() <= 180, isTrue, reason: r[0] as String);
        expect(countries, contains(r[4]), reason: r[0] as String);
        // GeoNames leaves invisible direction marks after some Arabic names; they must be gone.
        expect(RegExp(r'[\u200e\u200f\u202a-\u202e]').hasMatch(r[1] as String), isFalse, reason: r[0] as String);
      }
    });

    test('Saudi cities are named in Arabic', () {
      for (final (lat, lng, ar) in [(26.4207, 50.0888, 'الدمام'), (28.4328, 45.9708, 'حفر الباطن'), (21.4225, 39.8262, 'مكة المكرمة'), (27.0046, 49.646, 'الجبيل')]) {
        expect(places.nameOf(lat, lng)!.ar, startsWith(ar), reason: ar);
      }
    });
  });

  group('naming a position', () {
    test('a city centre gets its country too, and the country code that picks the calculation method', () {
      final dammam = places.nameOf(26.4207, 50.0888)!;
      expect((dammam.ar, dammam.en, dammam.country), ('الدمام، المملكة العربية السعودية', 'Dammam, Saudi Arabia', 'SA'));
    });

    test('a neighbouring city is not mistaken for the big one (Khobar is not Dammam)', () {
      expect(places.nameOf(26.2794, 50.2083)!.en, startsWith('Khobar'));
      expect(places.nameOf(26.2361, 50.0393)!.en, startsWith('Dhahran').or(startsWith('Dammam')), reason: 'Dhahran/Dammam area');
    });

    test('city districts are skipped in favour of the city (Paris, Cairo)', () {
      expect(places.nameOf(48.8566, 2.3522)!.en, startsWith('Paris,'));
      expect(places.nameOf(30.0444, 31.2357)!.en, startsWith('Cairo'));
    });

    test('a place far from any town is called "near" the closest one; open desert gets no name', () {
      // About 40 km east of Hafar Al-Batin: nearer to it than to anything else, but not in it.
      final near = places.nameOf(28.43, 46.45)!;
      expect(near.en, startsWith('Near '));
      expect(near.ar, startsWith('قرب '));
      expect(places.nameOf(19.5, 50.5), isNull); // the Empty Quarter
    });

    test('works across the date line', () {
      final tiny = OfflinePlaces.parse(jsonEncode({
        'countries': {
          'FJ': ['Fiji', ''],
        },
        'places': [
          ['East Side', '', 10.0, 179.9, 'FJ'],
          ['West Side', '', 10.0, -179.9, 'FJ'],
        ],
      }));
      expect(tiny.nameOf(10.0, -179.95)!.en, startsWith('West Side'));
      expect(tiny.nameOf(10.0, 179.95)!.en, startsWith('East Side'));
      expect(tiny.nameOf(10.0, 180.0), isNotNull);
    });

    test('an empty list names nothing', () {
      expect(OfflinePlaces.parse('{"countries":{},"places":[]}').nameOf(0, 0), isNull);
    });
  });

  group('FallbackPlaceNamer', () {
    const hafar = (ar: 'حفر الباطن', en: 'Hafar Al-Batin', country: 'SA');

    test('uses the phone’s map service when it answers', () async {
      var offlineCalls = 0;
      final namer = FallbackPlaceNamer(_Primary(hafar), (_, _) async {
        offlineCalls++;
        return null;
      });
      expect((await namer.nameOf(1, 2))!.en, 'Hafar Al-Batin');
      expect(offlineCalls, 0);
    });

    test('falls back to the bundled list when the map service has nothing', () async {
      final namer = FallbackPlaceNamer(_Primary(null), (lat, lng) async => places.nameOf(lat, lng));
      expect((await namer.nameOf(26.4207, 50.0888))!.en, 'Dammam, Saudi Arabia');
    });

    test('a failing lookup is just "no name"', () async {
      final namer = FallbackPlaceNamer(_Primary(null), (_, _) async => throw StateError('asset missing'));
      expect(await namer.nameOf(1, 2), isNull);
    });

    test('searching goes to the map service', () async {
      final namer = FallbackPlaceNamer(_Primary(null, hits: [(name: hafar, latitude: 28.43, longitude: 45.97)]), (_, _) async => null);
      expect((await namer.search('حفر')).single.name.en, 'Hafar Al-Batin');
    });
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}

class _Primary implements PlaceNamer {
  _Primary(this.name, {this.hits = const []});
  final PlaceName? name;
  final List<PlaceHit> hits;
  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async => name;
  @override
  Future<List<PlaceHit>> search(String query) async => hits;
}
