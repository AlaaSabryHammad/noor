import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

/// Vertical timeline of the Prophet's life ﷺ.
class SeerahScreen extends ConsumerWidget {
  const SeerahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('seerah'));
    return ServiceScaffold(title: l.svcSeerah, children: [
      contentBody(data, (d) {
        final events = (d['events'] as List).cast<Map<String, dynamic>>();
        return Column(children: [
          for (var i = 0; i < events.length; i++)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
                SizedBox(
                  width: 18,
                  child: Column(children: [
                    Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 20), decoration: BoxDecoration(color: t.gold, shape: BoxShape.circle, border: Border.all(color: t.background, width: 3))),
                    if (i < events.length - 1) Expanded(child: Container(width: 2, color: t.goldLine)),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoorCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
                        Text(pick(events[i], 'year', ar), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.goldText)),
                        Text(pick(events[i], 'title', ar), style: NoorText.display(context, size: 21)),
                        Text(pick(events[i], 'body', ar), style: const TextStyle(height: 1.8, fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 4),
          Text(NoorFormat.tr(context, 'التواريخ تقريبية وفق الروايات المشهورة.', 'Dates are approximate, following the well-known accounts.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]);
      }),
    ]);
  }
}
