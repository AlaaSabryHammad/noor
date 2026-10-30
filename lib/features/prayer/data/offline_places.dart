import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'place_names.dart';

/// Names any position with the nearest populated place, without internet.
///
/// The phone's own map service is missing on many devices (Huawei phones
/// without Google services, for one), and a name that is simply "the nearest
/// of the 29 listed cities" can be a different city. This list (about 50,000
/// places from GeoNames, `assets/data/places.json`, built by
/// `tool/build_places.py`) names the real town or city instead.
class OfflinePlaces {
  OfflinePlaces._(this._en, this._ar, this._cc, this._lat, this._lng, this._countries);

  final List<String> _en, _ar, _cc;
  final Float64List _lat, _lng;
  final Map<String, ({String en, String ar})> _countries;

  /// Places within this distance are named plainly; further ones as "Near …".
  static const exactKm = 25.0;

  /// Beyond this nothing is named (open desert, sea): the caller shows a generic label.
  static const maxKm = 120.0;

  int get length => _en.length;

  /// Decodes the JSON asset. CPU-bound (about 2 MB), so [load] runs it off the UI isolate.
  static OfflinePlaces parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rows = (data['places'] as List).cast<List<dynamic>>();
    final countries = {
      for (final e in (data['countries'] as Map<String, dynamic>).entries) e.key: (en: (e.value as List)[0] as String, ar: (e.value as List)[1] as String),
    };
    final lat = Float64List(rows.length), lng = Float64List(rows.length);
    final en = <String>[], ar = <String>[], cc = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      en.add(r[0] as String);
      ar.add(r[1] as String);
      lat[i] = (r[2] as num).toDouble();
      lng[i] = (r[3] as num).toDouble();
      cc.add(r[4] as String);
    }
    return OfflinePlaces._(en, ar, cc, lat, lng, countries);
  }

  static Future<OfflinePlaces> load(Future<String> Function(String path) loader) async {
    final raw = await loader('assets/data/places.json');
    return Isolate.run(() => parse(raw));
  }

  /// The nearest place and its distance in km, or null for an empty list.
  @visibleForTesting
  ({int index, double km})? nearest(double latitude, double longitude) {
    if (length == 0) return null;
    final cosLat = math.cos(latitude * math.pi / 180);
    var best = -1;
    var bestD2 = double.infinity;
    for (var i = 0; i < length; i++) {
      final dLat = _lat[i] - latitude;
      var dLng = (_lng[i] - longitude).abs();
      if (dLng > 180) dLng = 360 - dLng; // across the date line
      dLng *= cosLat;
      final d2 = dLat * dLat + dLng * dLng;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = i;
      }
    }
    return (index: best, km: math.sqrt(bestD2) * 111.32);
  }

  /// "Hafar Al-Batin, Saudi Arabia"; "Near Hafar Al-Batin, Saudi Arabia" when
  /// the nearest place is further than [exactKm]; null beyond [maxKm].
  PlaceName? nameOf(double latitude, double longitude) {
    final n = nearest(latitude, longitude);
    if (n == null || n.km > maxKm) return null;
    final i = n.index;
    final near = n.km > exactKm;
    final cityEn = _en[i], cityAr = _ar[i].isEmpty ? _en[i] : _ar[i];
    final country = _countries[_cc[i]];
    String compose(String city, String? countryName, {required bool arabic}) {
      final prefix = near ? (arabic ? 'قرب ' : 'Near ') : '';
      final withCountry = countryName == null || countryName.isEmpty || countryName == city ? city : (arabic ? '$city، $countryName' : '$city, $countryName');
      return '$prefix$withCountry';
    }

    final ccode = _cc[i].length == 2 ? _cc[i] : null;
    return (
      ar: compose(cityAr, country == null ? null : (country.ar.isEmpty ? country.en : country.ar), arabic: true),
      en: compose(cityEn, country?.en, arabic: false),
      country: ccode,
    );
  }
}
