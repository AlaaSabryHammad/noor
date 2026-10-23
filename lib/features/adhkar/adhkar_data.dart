import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

@immutable
class Dhikr {
  const Dhikr({required this.id, required this.ar, required this.en, required this.sourceAr, required this.sourceEn, required this.repeat});
  final String id, ar, en, sourceAr, sourceEn;
  final int repeat;

  factory Dhikr.fromJson(Map<String, dynamic> j) => Dhikr(
        id: j['id'] as String,
        ar: j['ar'] as String,
        en: j['en'] as String,
        sourceAr: j['sourceAr'] as String,
        sourceEn: j['sourceEn'] as String,
        repeat: j['repeat'] as int,
      );
}

@immutable
class DailyItem {
  const DailyItem({required this.ar, required this.en, required this.refAr, required this.refEn, required this.quranic});
  final String ar, en, refAr, refEn;
  final bool quranic; // render in the Quran face

  factory DailyItem.fromJson(Map<String, dynamic> j) =>
      DailyItem(ar: j['ar'] as String, en: j['en'] as String, refAr: j['refAr'] as String, refEn: j['refEn'] as String, quranic: j['quranic'] as bool);
}

final adhkarProvider = FutureProvider.family<List<Dhikr>, String>((ref, category) async {
  final j = jsonDecode(await ref.watch(contentLoaderProvider)('assets/data/adhkar.json')) as Map<String, dynamic>;
  return ((j[category] as List?) ?? const []).map((e) => Dhikr.fromJson(e as Map<String, dynamic>)).toList();
});

final dailyContentProvider = FutureProvider<Map<String, DailyItem>>((ref) async {
  final j = jsonDecode(await ref.watch(contentLoaderProvider)('assets/data/daily.json')) as Map<String, dynamic>;
  return j.map((k, v) => MapEntry(k, DailyItem.fromJson(v as Map<String, dynamic>)));
});

/// Remaining repetitions per dhikr for *today*; resets automatically each day.
class DhikrSessionController extends Notifier<Map<String, int>> {
  DhikrSessionController(this.category);
  final String category;

  String get _key {
    final d = ref.read(nowProvider);
    return 'adhkar.$category.${d.year}-${d.month}-${d.day}';
  }

  @override
  Map<String, int> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }

  int remaining(Dhikr d) => state[d.id] ?? d.repeat;

  void count(Dhikr d) {
    final r = remaining(d);
    if (r == 0) return;
    state = {...state, d.id: r - 1};
    _persist();
  }

  void reset() {
    state = {};
    _persist();
  }

  void _persist() => ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state));
}

final dhikrSessionProvider = NotifierProvider.family<DhikrSessionController, Map<String, int>, String>(DhikrSessionController.new);
