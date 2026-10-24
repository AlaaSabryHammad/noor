import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geo;

/// A place's display name in both app languages, and its ISO country code
/// ("SA") when the map service knows it: the country decides the regional
/// calculation method.
typedef PlaceName = ({String ar, String en, String? country});

/// A place found by searching its name.
typedef PlaceHit = ({PlaceName name, double latitude, double longitude});

/// Names coordinates and finds places by name, using the phone's own map
/// service (Apple Maps / Google). Behind an interface so tests and devices
/// without a geocoder can substitute it.
abstract interface class PlaceNamer {
  /// "Hafar Al-Batin, Saudi Arabia", or null when offline / unknown.
  Future<PlaceName?> nameOf(double latitude, double longitude);

  /// Places matching [query] (a city name in any language), best first.
  Future<List<PlaceHit>> search(String query);
}

/// "City, Country" from a placemark: the most specific populated level the
/// map service knows (locality, then district, then region).
@visibleForTesting
String? composePlaceName(geo.Placemark p, {required bool arabic}) {
  String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
  final city = clean(p.locality) ?? clean(p.subAdministrativeArea) ?? clean(p.administrativeArea) ?? clean(p.name);
  final country = clean(p.country);
  if (city == null) return country;
  if (country == null || country == city) return city;
  return arabic ? '$city، $country' : '$city, $country';
}

class PlatformPlaceNamer implements PlaceNamer {
  PlatformPlaceNamer();

  final _geo = geo.Geocoding();
  static const _ar = Locale('ar', 'SA'), _en = Locale('en', 'US');

  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async {
    try {
      final ar = await _geo.placemarkFromCoordinates(latitude, longitude, locale: _ar);
      final en = await _geo.placemarkFromCoordinates(latitude, longitude, locale: _en);
      final nameAr = ar.isEmpty ? null : composePlaceName(ar.first, arabic: true);
      final nameEn = en.isEmpty ? null : composePlaceName(en.first, arabic: false);
      if (nameAr == null && nameEn == null) return null;
      final country = [...en, ...ar].map((p) => p.isoCountryCode?.trim().toUpperCase() ?? '').where((c) => c.length == 2).firstOrNull;
      return (ar: nameAr ?? nameEn!, en: nameEn ?? nameAr!, country: country);
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      return null;
    }
  }

  @override
  Future<List<PlaceHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final found = await _geo.locationFromAddress(q);
      final hits = <PlaceHit>[];
      // The same city often comes back several times; keep places at least ~5 km apart.
      for (final l in found.take(5)) {
        if (hits.any((h) => (h.latitude - l.latitude).abs() < .05 && (h.longitude - l.longitude).abs() < .05)) continue;
        final name = await nameOf(l.latitude, l.longitude);
        hits.add((name: name ?? (ar: q, en: q, country: null), latitude: l.latitude, longitude: l.longitude));
      }
      return hits;
    } catch (e) {
      debugPrint('Place search failed: $e');
      return const [];
    }
  }
}
