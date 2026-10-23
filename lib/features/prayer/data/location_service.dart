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
  Future<LocationResult> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationResult.fail(LocationFailure.serviceOff);
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return const LocationResult.fail(LocationFailure.deniedForever);
      if (perm == LocationPermission.denied) return const LocationResult.fail(LocationFailure.denied);
      // City-level accuracy is plenty for prayer times and saves battery.
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)));
      return LocationResult.ok(p.latitude, p.longitude);
    } catch (_) {
      return const LocationResult.fail(LocationFailure.unavailable);
    }
  }
}
