import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../library/favorites.dart';
import 'service_widgets.dart';

class NamesScreen extends ConsumerStatefulWidget {
  const NamesScreen({super.key});
  @override
  ConsumerState<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends ConsumerState<NamesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('names'));
    return ServiceScaffold(title: l.svcNames, children: [
      NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في الأسماء الحسنى', 'Search the names'), onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
      const SizedBox(height: 14),
      contentBody(data, (d) {
        final all = (d['names'] as List).cast<Map<String, dynamic>>();
        final list = all
            .where((n) => _q.isEmpty || (n['ar'] as String).contains(_q) || (n['en'] as String).toLowerCase().contains(_q) || (n['tr'] as String).toLowerCase().contains(_q) || '${n['n']}' == _q)
            .toList();
        return Column(children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .8,
            children: [
              for (final n in list)
                NoorCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  onTap: () => _open(context, n),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 4, children: [
                    Text(NoorFormat.digits(context, n['n']), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.goldText)),
                    Text(n['ar'] as String, textAlign: TextAlign.center, maxLines: 2, style: NoorText.display(context, size: 19).copyWith(height: 1.4)),
                    Text(ar ? (n['en'] as String) : (n['tr'] as String), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
                  ]),
                ),
            ],
          ),
          if (list.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(NoorFormat.tr(context, 'لا توجد نتائج', 'No results'), style: TextStyle(color: t.textSecondary))),
          const SizedBox(height: 16),
          Text(NoorFormat.tr(context, 'ادعُ الله بأسمائه الحسنى · الأعراف ١٨٠', '“To Allah belong the best names, so invoke Him by them.” · Al-A‘raf 7:180'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]);
      }),
    ]);
  }

  void _open(BuildContext context, Map<String, dynamic> n) {
    final l = AppLocalizations.of(context);
    final item = SavedItem(
      key: 'name:${n['n']}',
      kind: 'name',
      title: n['ar'] as String,
      body: n['ar'] as String,
      translation: '${n['en']} — ${n['meaningAr']}',
      source: NoorFormat.tr(context, 'من أسماء الله الحسنى (${NoorFormat.digits(context, n['n'])})', 'Names of Allah (${n['n']})'),
    );
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final t = ctx.noor;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              Center(child: EightPointStar(size: 44, color: t.gold, child: Text(NoorFormat.digits(ctx, n['n']), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.primary)))),
              Text(n['ar'] as String, textAlign: TextAlign.center, style: NoorText.display(ctx, size: 38)),
              Text('${n['tr']} · ${n['en']}', textAlign: TextAlign.center, style: TextStyle(fontFamily: NoorFonts.latinUi, fontWeight: FontWeight.w600, color: t.goldText)),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(18)),
                child: Text(n['meaningAr'] as String, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(height: 1.8)),
              ),
              Row(spacing: 8, children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${n['ar']} — ${n['meaningAr']}'));
                      showNoorSnack(ctx, l.copied);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l.copy),
                  ),
                ),
                SaveButton(item: item, tooltip: l.save),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
