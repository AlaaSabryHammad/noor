import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.ok(this.latitude, this.longitude) : failure = null;
  const LocationResult.fail(this.failure)
      : latitude = 0,
        longitude = 0;
  final double latitude, longitude;
  final LocationFailure? failure;
  bool get ok => failure == null;
}

/// Device position source, kept behind an interface so tests and platforms
/// without GPS can substitute it.
abstract interface class LocationService {
  /// A fresh fix. With [prompt] false the permission dialog is never shown:
  /// a location the person has not allowed yet just reports [LocationFailure.denied].
  Future<LocationResult> current({bool prompt = true});
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current({bool prompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationResult.fail(LocationFailure.serviceOff);
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && prompt) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return const LocationResult.fail(LocationFailure.deniedForever);
      if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) return const LocationResult.fail(LocationFailure.denied);
      try {
        // A precise fix: prayer times move by about a minute every 15–20 km.
        final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
        return LocationResult.ok(p.latitude, p.longitude);
      } on TimeoutException {
        // Indoors the GPS may not settle in time; the last known fix is close enough.
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? const LocationResult.fail(LocationFailure.unavailable) : LocationResult.ok(last.latitude, last.longitude);
      }
    } catch (_) {
      return const LocationResult.fail(LocationFailure.unavailable);
    }
  }
}
