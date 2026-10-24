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

/// Category keys that start with this prefix are chapters of the full Hisn
/// al-Muslim (hisn_27 = chapter 27), loaded from assets/data/hisn.json.
const hisnPrefix = 'hisn_';

@immutable
class HisnGroup {
  const HisnGroup({required this.id, required this.titleAr, required this.titleEn});
  final int id;
  final String titleAr, titleEn;
}

@immutable
class HisnChapter {
  const HisnChapter({required this.id, required this.group, required this.titleAr, required this.titleEn, required this.items});
  final int id, group;
  final String titleAr, titleEn;
  final List<Dhikr> items;
  String get key => '$hisnPrefix$id';
}

@immutable
class HisnBook {
  const HisnBook({required this.groups, required this.chapters});
  final List<HisnGroup> groups;
  final List<HisnChapter> chapters;
}

final hisnProvider = FutureProvider<HisnBook>((ref) async {
  final j = jsonDecode(await ref.watch(contentLoaderProvider)('assets/data/hisn.json')) as Map<String, dynamic>;
  return HisnBook(
    groups: [for (final g in (j['groups'] as List).cast<Map<String, dynamic>>()) HisnGroup(id: g['id'] as int, titleAr: g['titleAr'] as String, titleEn: g['titleEn'] as String)],
    chapters: [
      for (final c in (j['categories'] as List).cast<Map<String, dynamic>>())
        HisnChapter(
          id: c['id'] as int,
          group: c['group'] as int,
          titleAr: c['titleAr'] as String,
          titleEn: c['titleEn'] as String,
          items: [
            for (final i in (c['items'] as List).cast<Map<String, dynamic>>())
              Dhikr(
                id: 'hisn${c['id']}.${i['id']}',
                ar: i['ar'] as String,
                en: i['en'] as String,
                sourceAr: 'حصن المسلم · سعيد بن علي القحطاني',
                sourceEn: 'Hisn al-Muslim · Sa‘id al-Qahtani',
                repeat: i['repeat'] as int,
              ),
          ],
        ),
    ],
  );
});

final adhkarProvider = FutureProvider.family<List<Dhikr>, String>((ref, category) async {
  if (category.startsWith(hisnPrefix)) {
    final id = int.tryParse(category.substring(hisnPrefix.length));
    final book = await ref.watch(hisnProvider.future);
    return book.chapters.where((c) => c.id == id).firstOrNull?.items ?? const [];
  }
  final j = jsonDecode(await ref.watch(contentLoaderProvider)('assets/data/adhkar.json')) as Map<String, dynamic>;
  return ((j[category] as List?) ?? const []).map((e) => Dhikr.fromJson(e as Map<String, dynamic>)).toList();
});

/// Rotating pools for the home screen's "Daily light", keyed ayah / hadith / dua.
final dailyContentProvider = FutureProvider<Map<String, List<DailyItem>>>((ref) async {
  final j = jsonDecode(await ref.watch(contentLoaderProvider)('assets/data/daily.json')) as Map<String, dynamic>;
  return {
    for (final k in const ['ayah', 'hadith', 'dua']) k: [for (final e in (j[k] as List).cast<Map<String, dynamic>>()) DailyItem.fromJson(e)],
  };
});

/// The item shown on [date] for [kind]: one per day, cycling through the pool;
/// each kind starts at a different offset so the three tabs never line up.
DailyItem? dailyItemFor(Map<String, List<DailyItem>>? pools, String kind, DateTime date) {
  final pool = pools?[kind];
  if (pool == null || pool.isEmpty) return null;
  final dayOfYear = date.difference(DateTime(date.year)).inDays;
  final offset = switch (kind) {
    'hadith' => 7,
    'dua' => 13,
    _ => 0,
  };
  return pool[(dayOfYear + offset) % pool.length];
}

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
