import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../quran/quran_data.dart' show normalizeArabic;
import '../services/service_widgets.dart';
import 'adhkar_data.dart';

/// All 132 chapters of Hisn al-Muslim, grouped by theme, with search.
class HisnScreen extends ConsumerStatefulWidget {
  const HisnScreen({super.key});
  @override
  ConsumerState<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends ConsumerState<HisnScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final book = ref.watch(hisnProvider);
    return ServiceScaffold(title: NoorFormat.tr(context, 'حصن المسلم', 'Hisn al-Muslim'), children: [
      NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في أبواب حصن المسلم', 'Search the chapters'), onChanged: (v) => setState(() => _q = v.trim())),
      const SizedBox(height: 12),
      contentView(book, (b) {
        final plain = normalizeArabic(_q), lower = _q.toLowerCase();
        bool match(HisnChapter c) => _q.isEmpty || normalizeArabic(c.titleAr).contains(plain) || c.titleEn.toLowerCase().contains(lower) || '${c.id}' == _q;
        final shown = b.chapters.where(match).toList();
        if (shown.isEmpty) {
          return Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(NoorFormat.tr(context, 'لا توجد نتائج', 'No results'), style: TextStyle(color: t.textSecondary))));
        }
        final groups = _q.isEmpty ? b.groups : [const HisnGroup(id: 0, titleAr: '', titleEn: '')];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          for (final g in groups) ...[
            if (_q.isEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(ar ? g.titleAr : g.titleEn, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.goldText, height: 1.5))),
            NoorCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (i, c) in shown.where((c) => _q.isNotEmpty || c.group == g.id).indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    minTileHeight: 56,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () => context.push('/adhkar/session/${c.key}'),
                    title: Text(ar ? c.titleAr : c.titleEn, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, height: 1.5)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: t.sunk, borderRadius: BorderRadius.circular(99)),
                        child: Text(NoorFormat.digits(context, c.items.length), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: t.textSecondary)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: t.textSecondary),
                    ]),
                  ),
                ],
              ]),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(NoorFormat.tr(context, 'كتاب «حصن المسلم» للشيخ سعيد بن علي بن وهف القحطاني. البيانات مفتوحة المصدر (MIT).', '“Hisn al-Muslim” by Sheikh Sa‘id al-Qahtani. Open data (MIT).'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
        ]);
      }),
    ]);
  }
}

/// Loading / error wrapper for a plain [AsyncValue].
Widget contentView<T>(AsyncValue<T> v, Widget Function(T data) builder) => v.when(
      loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('$e'))),
      data: builder,
    );
