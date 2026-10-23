import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('stories'));
    return ServiceScaffold(title: l.svcStories, children: [
      contentBody(data, (d) {
        final items = (d['items'] as List).cast<Map<String, dynamic>>();
        return Column(spacing: 10, children: [
          for (var i = 0; i < items.length; i++)
            NoorCard(
              padding: const EdgeInsets.all(14),
              onTap: () => _open(context, items[i]),
              child: Row(spacing: 14, children: [
                EightPointStar(size: 46, color: t.gold, child: Text(NoorFormat.digits(context, i + 1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.primary))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
                    Text(pick(items[i], 'name', ar), style: NoorText.display(context, size: 20)),
                    Text(pick(items[i], 'ref', ar), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textSecondary),
              ]),
            ),
        ]);
      }),
    ]);
  }

  void _open(BuildContext context, Map<String, dynamic> s) {
    final ar = NoorFormat.isAr(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final t = ctx.noor;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .8),
            child: ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 24), shrinkWrap: true, children: [
              Text(pick(s, 'name', ar), textAlign: TextAlign.center, style: NoorText.display(ctx, size: 30)),
              const SizedBox(height: 4),
              Text(pick(s, 'ref', ar), textAlign: TextAlign.center, style: TextStyle(color: t.goldText, fontWeight: FontWeight.w600, fontSize: 12.5)),
              const SizedBox(height: 16),
              Text(pick(s, 'body', ar), style: const TextStyle(fontSize: 15, height: 1.9)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Icon(Icons.lightbulb_outline_rounded, color: t.primary, size: 20),
                  Expanded(child: Text(pick(s, 'lesson', ar), style: TextStyle(color: t.primary, fontWeight: FontWeight.w600, height: 1.7))),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
