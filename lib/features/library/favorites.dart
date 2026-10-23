import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_tokens.dart';

/// Something the user saved: an ayah, hadith, dua, name or daily item.
@immutable
class SavedItem {
  const SavedItem({required this.key, required this.kind, required this.title, required this.body, this.translation = '', this.source = ''});

  /// Unique, e.g. `hadith:h3`.
  final String key;
  final String kind; // ayah | hadith | dua | name | daily
  final String title;
  final String body; // Arabic text
  final String translation;
  final String source;

  Map<String, Object?> toJson() => {'key': key, 'kind': kind, 'title': title, 'body': body, 'tr': translation, 'src': source};

  static SavedItem? fromJson(Map<String, dynamic> j) {
    final key = j['key'], kind = j['kind'], body = j['body'];
    if (key is! String || kind is! String || body is! String) return null;
    return SavedItem(key: key, kind: kind, title: j['title'] as String? ?? '', body: body, translation: j['tr'] as String? ?? '', source: j['src'] as String? ?? '');
  }

  String get shareText => [body, if (source.isNotEmpty) '— $source'].join('\n');
}

class FavoritesController extends Notifier<List<SavedItem>> {
  static const _k = 'library.saved';

  @override
  List<SavedItem> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_k);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => SavedItem.fromJson(e as Map<String, dynamic>)).whereType<SavedItem>().toList();
    } catch (_) {
      return const [];
    }
  }

  bool isSaved(String key) => state.any((e) => e.key == key);

  /// Returns true when the item is now saved.
  bool toggle(SavedItem item) {
    final saved = !isSaved(item.key);
    state = saved ? [item, ...state] : state.where((e) => e.key != item.key).toList();
    ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(state.map((e) => e.toJson()).toList()));
    return saved;
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, List<SavedItem>>(FavoritesController.new);

/// Heart toggle that saves/removes [item] in the library.
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.item, required this.tooltip, this.size = 19});
  final SavedItem item;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final saved = ref.watch(favoritesProvider.select((l) => l.any((e) => e.key == item.key)));
    return IconButton(
      tooltip: tooltip,
      isSelected: saved,
      icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: size, color: saved ? t.gold : t.textSecondary),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(item),
    );
  }
}
