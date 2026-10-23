import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One compass reading: [heading] is degrees clockwise from magnetic north;
/// [accuracy] is the ± error in degrees when the platform reports it.
@immutable
class CompassReading {
  const CompassReading(this.heading, {this.accuracy});
  final double heading;
  final double? accuracy;

  /// iOS reports a trustworthy error; a big or negative value means the sensor
  /// needs the figure-eight calibration.
  bool get needsCalibration => accuracy != null && (accuracy! < 0 || accuracy! > 25);
}

/// Device heading source. A null stream means the device has no compass.
abstract interface class CompassSource {
  Stream<CompassReading>? get readings;
}

class SensorCompassSource implements CompassSource {
  const SensorCompassSource();

  @override
  Stream<CompassReading>? get readings => FlutterCompass.events?.where((e) => e.heading != null).map((e) => CompassReading(normalizeDegrees(e.heading!), accuracy: e.accuracy));
}

final compassSourceProvider = Provider<CompassSource>((ref) => const SensorCompassSource());

/// Live readings; stays in the `loading` state until the first one and emits
/// an error when there is no sensor, which the screen turns into the manual mode.
final compassProvider = StreamProvider<CompassReading>((ref) {
  final s = ref.watch(compassSourceProvider).readings;
  return s ?? Stream.error(const CompassUnavailable());
});

class CompassUnavailable implements Exception {
  const CompassUnavailable();
  @override
  String toString() => 'No compass sensor';
}

double normalizeDegrees(double d) => ((d % 360) + 360) % 360;

/// Signed shortest rotation from [from] to [to], in (-180, 180].
double angleDelta(double from, double to) {
  final d = normalizeDegrees(to - from);
  return d > 180 ? d - 360 : d;
}

/// Low-pass filter on a circle: moves [previous] a fraction [alpha] of the way
/// to [next] along the shortest arc, so 359° → 1° never swings through 180°.
double smoothAngle(double previous, double next, {double alpha = .25}) => normalizeDegrees(previous + angleDelta(previous, next) * alpha);

/// Heading used when there is no sensor (or for previewing): set by the slider.
class ManualHeadingController extends Notifier<double> {
  @override
  double build() => 0;
  void set(double v) => state = normalizeDegrees(v);
}

final manualHeadingProvider = NotifierProvider<ManualHeadingController, double>(ManualHeadingController.new);
