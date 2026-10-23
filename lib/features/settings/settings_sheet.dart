import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(context: context, builder: (_) => const SettingsSheet());

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final t = context.noor;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
          Text(l.settings, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.language, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          NoorSegmented<String>(values: const ['ar', 'en'], labels: const ['العربية', 'English'], selected: s.locale.languageCode, onChanged: (v) => ctrl.setLocale(Locale(v))),
          const SizedBox(height: 6),
          Text(l.appearance, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          NoorSegmented<ThemeMode>(
            values: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
            labels: [l.themeLight, l.themeDark, l.themeSystem],
            selected: s.themeMode,
            onChanged: ctrl.setThemeMode,
          ),
          const SizedBox(height: 6),
          Text(l.hijriAdjust, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          NoorSegmented<int>(
            values: const [-1, 0, 1],
            labels: [for (final n in const ['-1', '0', '+1']) NoorFormat.digits(context, n)],
            selected: s.hijriOffset,
            onChanged: ctrl.setHijriOffset,
          ),
          const SizedBox(height: 4),
          Text(l.settingsNote, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
