import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const SettingsSheet());

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final t = context.noor;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        child: SingleChildScrollView(
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
            Text(NoorFormat.tr(context, 'حجم خط القرآن', 'Quran text size'), style: TextStyle(fontSize: 13, color: t.textSecondary)),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              decoration: BoxDecoration(color: t.sunk, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textDirection: TextDirection.rtl, style: NoorText.quran(context, size: s.quranFontSize).copyWith(height: 1.9)),
                Slider(value: s.quranFontSize.clamp(20, 40), min: 20, max: 40, divisions: 10, label: NoorFormat.digits(context, s.quranFontSize.round()), onChanged: ctrl.setQuranFontSize),
              ]),
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
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const IconBadge(icon: Icons.info_outline_rounded, size: 40),
              title: Text(NoorFormat.tr(context, 'حول التطبيق والإسناد', 'About and credits'), style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded, color: t.textSecondary),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/about');
              },
            ),
          ]),
        ),
      ),
    );
  }
}
