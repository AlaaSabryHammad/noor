import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/noor_format.dart';

enum KhutbaBlockKind { paragraph, ayah, hadith }

@immutable
class KhutbaBlock {
  const KhutbaBlock({required this.kind, required this.ar, required this.en, this.refAr = '', this.refEn = ''});
  final KhutbaBlockKind kind;
  final String ar, en, refAr, refEn;

  factory KhutbaBlock.fromJson(Map<String, dynamic> j) => KhutbaBlock(
        kind: switch (j['t']) {
          'ayah' => KhutbaBlockKind.ayah,
          'hadith' => KhutbaBlockKind.hadith,
          _ => KhutbaBlockKind.paragraph,
        },
        ar: j['ar'] as String,
        en: j['en'] as String? ?? '',
        refAr: j['refAr'] as String? ?? '',
        refEn: j['refEn'] as String? ?? '',
      );

  String text(bool ar) => ar || en.isEmpty ? this.ar : en;
  String ref(bool ar) => ar ? refAr : refEn;
}

@immutable
class KhutbaPart {
  const KhutbaPart({required this.titleAr, required this.titleEn, required this.blocks});
  final String titleAr, titleEn;
  final List<KhutbaBlock> blocks;

  String title(bool ar) => ar ? titleAr : titleEn;
}

@immutable
class Khutba {
  const Khutba({required this.id, required this.category, required this.titleAr, required this.titleEn, required this.summaryAr, required this.summaryEn, required this.minutes, required this.parts});
  final String id, category, titleAr, titleEn, summaryAr, summaryEn;
  final int minutes;
  final List<KhutbaPart> parts;

  String title(bool ar) => ar ? titleAr : titleEn;
  String summary(bool ar) => ar ? summaryAr : summaryEn;

  factory Khutba.fromJson(Map<String, dynamic> j) => Khutba(
        id: j['id'] as String,
        category: j['cat'] as String,
        titleAr: j['titleAr'] as String,
        titleEn: j['titleEn'] as String,
        summaryAr: j['summaryAr'] as String,
        summaryEn: j['summaryEn'] as String,
        minutes: (j['minutes'] as num?)?.toInt() ?? 5,
        parts: [
          for (final p in (j['parts'] as List).cast<Map<String, dynamic>>())
            KhutbaPart(titleAr: p['titleAr'] as String, titleEn: p['titleEn'] as String, blocks: [for (final b in (p['blocks'] as List)) KhutbaBlock.fromJson(b as Map<String, dynamic>)]),
        ],
      );

  /// The whole sermon as plain text, for copying and sharing.
  String plainText(bool ar) {
    final out = StringBuffer(title(ar));
    for (final p in parts) {
      out.write('\n\n— ${p.title(ar)} —');
      for (final b in p.blocks) {
        out.write('\n\n${b.text(ar)}');
        if (b.ref(ar).isNotEmpty) out.write(' [${b.ref(ar)}]');
      }
    }
    return out.toString();
  }
}

@immutable
class KhutbaCategory {
  const KhutbaCategory({required this.id, required this.ar, required this.en});
  final String id, ar, en;
  String name(bool isAr) => isAr ? ar : en;
}

@immutable
class KhutabLibrary {
  const KhutabLibrary({required this.categories, required this.khutab});
  final List<KhutbaCategory> categories;
  final List<Khutba> khutab;

  Khutba? byId(String id) => khutab.where((k) => k.id == id).firstOrNull;
  KhutbaCategory? category(String id) => categories.where((c) => c.id == id).firstOrNull;

  factory KhutabLibrary.fromJson(Map<String, dynamic> j) => KhutabLibrary(
        categories: [for (final c in (j['categories'] as List).cast<Map<String, dynamic>>()) KhutbaCategory(id: c['id'] as String, ar: c['ar'] as String, en: c['en'] as String)],
        khutab: [for (final k in (j['khutab'] as List)) Khutba.fromJson(k as Map<String, dynamic>)],
      );

  /// This week's sermon: the season's own before Ramadan and in early
  /// Dhul-Hijjah, otherwise a weekly rotation through the general topics.
  Khutba weekly(DateTime date, {int hijriOffset = 0}) {
    final h = NoorFormat.hijri(date, offsetDays: hijriOffset);
    final seasonal = switch ((h.hMonth, h.hDay)) {
      (8, >= 15) || (9, <= 10) => 'ramadan',
      (11, >= 20) || (12, <= 10) => 'dhulhijjah',
      _ => null,
    };
    if (seasonal != null && byId(seasonal) != null) return byId(seasonal)!;
    final pool = khutab.where((k) => k.category != 'seasons' && k.category != 'prophetic').toList();
    if (pool.isEmpty) return khutab.first;
    final week = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(2024, 1, 5)).inDays ~/ 7;
    return pool[week % pool.length];
  }
}

final khutabProvider = FutureProvider<KhutabLibrary>((ref) async {
  final raw = await ref.watch(contentLoaderProvider)('assets/data/khutab.json');
  return KhutabLibrary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Reading size for sermons, persisted separately from the Quran font size.
class KhutbaFontSize extends Notifier<double> {
  static const _k = 'khutab.fontSize';
  static const min = 14.0, max = 32.0;

  @override
  double build() => (ref.watch(sharedPreferencesProvider).getDouble(_k) ?? 18).clamp(min, max);

  void set(double v) {
    state = v.clamp(min, max);
    ref.read(sharedPreferencesProvider).setDouble(_k, state);
  }
}

final khutbaFontSizeProvider = NotifierProvider<KhutbaFontSize, double>(KhutbaFontSize.new);
