import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override in main'));

/// Wall clock, ticking every second. Override in tests for a fixed time.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Convenience: the latest tick, or now while the stream warms up.
final nowProvider = Provider<DateTime>((ref) => ref.watch(clockProvider).value ?? DateTime.now());

/// Loads bundled content files (JSON). Overridable for tests and for a
/// future downloadable-content source.
final contentLoaderProvider = Provider<Future<String> Function(String path)>((ref) => rootBundle.loadString);
