import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

/// "Ask & learn": answers to the most common basic questions, offline.
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});
  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  String _cat = 'all';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('faq'));
    return ServiceScaffold(title: l.svcAsk, children: [
      NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في الأسئلة', 'Search questions'), onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
      const SizedBox(height: 12),
      contentBody(data, (d) {
        final cats = (d['categories'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
        final items = (d['items'] as List)
            .cast<Map<String, dynamic>>()
            .where((f) => (_cat == 'all' || f['cat'] == _cat) && (_q.isEmpty || pick(f, 'q', true).contains(_q) || pick(f, 'q', false).toLowerCase().contains(_q)))
            .toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final k in ['all', ...cats.keys])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(k == 'all' ? NoorFormat.tr(context, 'الكل', 'All') : (ar ? cats[k]!['ar'] : cats[k]!['en']) as String),
                    selected: _cat == k,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _cat = k),
                    selectedColor: t.primary,
                    labelStyle: TextStyle(color: _cat == k ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 13),
                    backgroundColor: t.surface,
                    side: BorderSide(color: _cat == k ? t.primary : t.border),
                    shape: const StadiumBorder(),
                  ),
                ),
            ]),
          ),
          for (final f in items)
            NoorCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  iconColor: t.primary,
                  title: Text(pick(f, 'q', ar), style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5)),
                  children: [Text(pick(f, 'a', ar), style: TextStyle(height: 1.8, color: t.text))],
                ),
              ),
            ),
          if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(NoorFormat.tr(context, 'لا توجد نتائج', 'No results'), style: TextStyle(color: t.textSecondary)))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.goldLine)),
            child: Text(
              NoorFormat.tr(context, 'هذه إجابات تعليمية مختصرة في الأساسيات وليست فتاوى. للمسائل الخاصة راجع أهل العلم الموثوقين في بلدك.', 'These are brief educational answers on the basics, not fatwas. For personal rulings consult trusted scholars in your community.'),
              style: TextStyle(fontSize: 12.5, height: 1.7, color: t.goldText),
            ),
          ),
        ]);
      }),
    ]);
  }
}
