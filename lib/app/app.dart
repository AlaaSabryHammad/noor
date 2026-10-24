import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/noor_theme.dart';
import '../features/prayer/alert_sync.dart';
import '../features/prayer/prayer_providers.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class NoorApp extends ConsumerWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    ref.watch(alertSyncProvider);
    // Locate the person on first launch; follow them later if they use their location.
    ref.watch(locationBootstrapProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: NoorTheme.light(settings.locale),
      darkTheme: NoorTheme.dark(settings.locale),
      themeAnimationDuration: const Duration(milliseconds: 500),
    );
  }
}
