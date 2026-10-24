import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../library/favorites.dart';
import 'service_widgets.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});
  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _q = '';
  String _topic = 'all';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('hadith'));
    return ServiceScaffold(title: l.svcHadith, children: [
      NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في الأحاديث', 'Search hadith'), onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
      const SizedBox(height: 12),
      NoorCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/books'),
        child: Row(spacing: 14, children: [
          const IconBadge(icon: Icons.menu_book_outlined, gold: true, size: 44),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
              Text(NoorFormat.tr(context, 'مكتبة كتب الحديث', 'Hadith books library'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(NoorFormat.tr(context, 'الأربعون النووية والأحاديث القدسية وصحيح البخاري وغيرها', 'The Forty Hadith, Hadith Qudsi, Sahih al-Bukhari and more'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textSecondary),
        ]),
      ),
      const SizedBox(height: 12),
      contentBody(data, (d) {
        final topics = (d['topics'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
        final items = (d['items'] as List)
            .cast<Map<String, dynamic>>()
            .where((h) => (_topic == 'all' || h['topic'] == _topic) && (_q.isEmpty || (h['ar'] as String).contains(_q) || (h['en'] as String).toLowerCase().contains(_q)))
            .toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final k in ['all', ...topics.keys])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(k == 'all' ? NoorFormat.tr(context, 'الكل', 'All') : (ar ? topics[k]!['ar'] : topics[k]!['en']) as String),
                    selected: _topic == k,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _topic = k),
                    selectedColor: t.primary,
                    labelStyle: TextStyle(color: _topic == k ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 13),
                    backgroundColor: t.surface,
                    side: BorderSide(color: _topic == k ? t.primary : t.border),
                    shape: const StadiumBorder(),
                  ),
                ),
            ]),
          ),
          for (final h in items) _HadithCard(h: h),
          if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(NoorFormat.tr(context, 'لا توجد نتائج', 'No results'), style: TextStyle(color: t.textSecondary)))),
          Text(NoorFormat.tr(context, 'مختارات من الأحاديث الصحيحة. راجع الطبعات المحققة للتوثق.', 'A selection of authentic hadith. Check verified editions for study.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]);
      }),
    ]);
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.h});
  final Map<String, dynamic> h;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final source = pick(h, 'source', ar);
    final item = SavedItem(key: 'hadith:${h['id']}', kind: 'hadith', title: source, body: h['ar'] as String, translation: h['en'] as String, source: source);
    return NoorCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
        Text(h['ar'] as String, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: NoorText.display(context, size: 20).copyWith(height: 2, fontWeight: FontWeight.w400)),
        Text(h['en'] as String, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13, height: 1.6, color: t.textSecondary)),
        const Divider(),
        Row(children: [
          Expanded(child: Text(source, style: TextStyle(fontSize: 11.5, color: t.goldText, height: 1.5, fontWeight: FontWeight.w600))),
          IconButton(
            tooltip: l.copy,
            icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.shareText));
              showNoorSnack(context, l.copied);
            },
          ),
          SaveButton(item: item, tooltip: l.save),
        ]),
      ]),
    );
  }
}
