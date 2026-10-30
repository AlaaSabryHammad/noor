import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.ok(this.latitude, this.longitude, {this.accuracyMeters, this.age = Duration.zero}) : failure = null;
  const LocationResult.fail(this.failure)
      : latitude = 0,
        longitude = 0,
        accuracyMeters = null,
        age = Duration.zero;
  final double latitude, longitude;

  /// How far off the fix may be, when the device says.
  final double? accuracyMeters;

  /// How old the fix is: zero for a fresh one, longer for the phone's last known position (used when the
  /// signal is too weak for a new one, e.g. indoors).
  final Duration age;
  final LocationFailure? failure;
  bool get ok => failure == null;

  /// True when this is a remembered position rather than a new fix.
  bool get stale => age > GeolocatorLocationService.maxFixAge;
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

  /// A remembered fix up to this old counts as current.
  static const maxFixAge = Duration(minutes: 10);

  /// Older than this the phone may have travelled to another city, so the
  /// remembered fix is not used at all. Between the two it is used only when no
  /// new fix can be had, and flagged as [LocationResult.stale].
  static const maxStaleAge = Duration(hours: 48);

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// [plainManager] asks Android's own location manager (GPS + network) instead
  /// of Google's fused provider, which is missing or silent on some phones.
  static LocationSettings _settings(LocationAccuracy accuracy, Duration limit, {bool plainManager = false}) =>
      _android ? AndroidSettings(accuracy: accuracy, timeLimit: limit, forceLocationManager: plainManager) : LocationSettings(accuracy: accuracy, timeLimit: limit);

  static bool _isDisabledError(Object e) => e is LocationServiceDisabledException || (e is PlatformException && e.code == 'LOCATION_SERVICES_DISABLED');

  /// One attempt at a fix; null when it timed out or failed ([onDisabled] hears when the plugin says location is off).
  static Future<Position?> _fix(LocationSettings settings, {required void Function() onDisabled}) async {
    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } on TimeoutException {
      return null;
    } catch (e) {
      if (_isDisabledError(e)) onDisabled();
      debugPrint('Location fix failed: $e');
      return null;
    }
  }

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition(forceAndroidLocationManager: _android);
    } catch (e) {
      debugPrint('Last known location failed: $e');
      return null;
    }
  }

  @override
  Future<LocationResult> current({bool prompt = true}) async {
    try {
      // The plugin's "is location on?" check goes through Google's location-settings service. On phones whose Google
      // services are only partly there (Huawei) it raises LOCATION_SERVICES_DISABLED instead of answering, although
      // location is on: then the fused provider is skipped and Android's own location manager does the work.
      var fusedUsable = true;
      try {
        if (!await Geolocator.isLocationServiceEnabled()) return const LocationResult.fail(LocationFailure.serviceOff);
      } on PlatformException catch (e) {
        if (!_android || !_isDisabledError(e)) rethrow;
        fusedUsable = false;
        debugPrint('Location: the Google location check is unusable on this phone, using Android’s own manager');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && prompt) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return const LocationResult.fail(LocationFailure.deniedForever);
      if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) return const LocationResult.fail(LocationFailure.denied);

      var disabledSeen = false;
      void sawDisabled() => disabledSeen = true;

      // A precise fix first: prayer times move by about a minute every 15–20 km.
      Position? p;
      if (fusedUsable) p = await _fix(_settings(LocationAccuracy.high, const Duration(seconds: 20)), onDisabled: sawDisabled);
      // Phones without a working Google location service: Android's own manager.
      if (p == null && _android) p = await _fix(_settings(LocationAccuracy.high, const Duration(seconds: 20), plainManager: true), onDisabled: sawDisabled);
      // Indoors the GPS may not settle: a recent fix is close enough.
      final last = p == null ? await _lastKnown() : null;
      final lastAge = last == null ? null : DateTime.now().difference(last.timestamp);
      if (last != null && lastAge! <= maxFixAge) p = last;
      // Then a quick, coarse network fix.
      p ??= await _fix(_settings(LocationAccuracy.low, const Duration(seconds: 10), plainManager: _android), onDisabled: sawDisabled);
      if (p != null) return LocationResult.ok(p.latitude, p.longitude, accuracyMeters: p.accuracy, age: identical(p, last) ? lastAge! : Duration.zero);
      // Still nothing: the phone's older remembered position is far better than the default city, as long as it
      // cannot be from another trip. The caller tells the person it is old.
      if (last != null && lastAge! <= maxStaleAge) return LocationResult.ok(last.latitude, last.longitude, accuracyMeters: last.accuracy, age: lastAge);
      return LocationResult.fail(disabledSeen ? LocationFailure.serviceOff : LocationFailure.unavailable);
    } catch (e, stack) {
      debugPrint('Location lookup failed: $e\n$stack');
      return const LocationResult.fail(LocationFailure.unavailable);
    }
  }
}

/// Opens the system screen where the person can fix [failure]: the app's
/// permission page when it was refused for good, the location switch when it is off.
Future<bool> openLocationSettingsFor(LocationFailure failure) => failure == LocationFailure.deniedForever ? Geolocator.openAppSettings() : Geolocator.openLocationSettings();
