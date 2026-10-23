import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'domain/prayer_method.dart';
import 'domain/prayer_models.dart';
import 'prayer_providers.dart';

Future<void> showCalcSheet(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const CalcSheet());

class CalcSheet extends ConsumerWidget {
  const CalcSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final calc = ref.watch(prayerCalcProvider);
    final ctrl = ref.read(prayerCalcProvider.notifier);
    final effective = ref.watch(effectiveMethodProvider);

    Widget tile({required String title, String? subtitle, required bool selected, required VoidCallback onTap}) => ListTile(
          minTileHeight: 52,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          selected: selected,
          selectedColor: t.primary,
          title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          subtitle: subtitle == null ? null : Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          trailing: selected ? Icon(Icons.check_rounded, color: t.primary) : null,
          onTap: onTap,
        );

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          children: [
            Text(l.calcSheetTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.calcMethod, style: Theme.of(context).textTheme.bodySmall),
            tile(title: l.methodAuto, subtitle: l.methodAutoUsing(methodName(l, effective)), selected: calc.method == null, onTap: () => ctrl.setMethod(null)),
            for (final m in PrayerMethod.values) tile(title: methodName(l, m), selected: calc.method == m, onTap: () => ctrl.setMethod(m)),
            const SizedBox(height: 14),
            Text(l.asrRuleTitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            NoorSegmented<AsrMadhab>(values: AsrMadhab.values, labels: [l.asrRuleStandard, l.asrRuleHanafi], selected: calc.madhab, onChanged: ctrl.setMadhab),
            const SizedBox(height: 14),
            Text(l.calcSheetNote, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
