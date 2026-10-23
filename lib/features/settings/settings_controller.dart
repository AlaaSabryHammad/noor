import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

@immutable
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.light, this.locale = const Locale('ar'), this.quranFontSize = 26, this.hijriOffset = 0});

  /// Light is the default on first launch (product requirement), not System.
  final ThemeMode themeMode;
  final Locale locale;
  final double quranFontSize;
  final int hijriOffset;

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale, double? quranFontSize, int? hijriOffset}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        quranFontSize: quranFontSize ?? this.quranFontSize,
        hijriOffset: hijriOffset ?? this.hijriOffset,
      );
}

class SettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings.theme', _kLocale = 'settings.locale', _kFont = 'settings.quranFont', _kHijri = 'settings.hijriOffset';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values.byName(p.getString(_kTheme) ?? ThemeMode.light.name),
      locale: Locale(p.getString(_kLocale) ?? 'ar'),
      quranFontSize: p.getDouble(_kFont) ?? 26,
      hijriOffset: p.getInt(_kHijri) ?? 0,
    );
  }

  void setThemeMode(ThemeMode m) {
    state = state.copyWith(themeMode: m);
    ref.read(sharedPreferencesProvider).setString(_kTheme, m.name);
  }

  void setLocale(Locale l) {
    state = state.copyWith(locale: l);
    ref.read(sharedPreferencesProvider).setString(_kLocale, l.languageCode);
  }

  void toggleLocale() => setLocale(Locale(state.locale.languageCode == 'ar' ? 'en' : 'ar'));

  void toggleDark(Brightness current) => setThemeMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  void setHijriOffset(int days) {
    state = state.copyWith(hijriOffset: days.clamp(-1, 1));
    ref.read(sharedPreferencesProvider).setInt(_kHijri, state.hijriOffset);
  }

  void setQuranFontSize(double v) {
    state = state.copyWith(quranFontSize: v.clamp(20, 40));
    ref.read(sharedPreferencesProvider).setDouble(_kFont, state.quranFontSize);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
