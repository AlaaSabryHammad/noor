import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'noor_tokens.dart';

/// Font families bundled in assets/fonts (offline-first, no runtime fetch).
abstract final class NoorFonts {
  static const quran = 'AmiriQuran';
  static const display = 'Amiri';
  static const arabicUi = 'IBMPlexSansArabic';
  static const latinUi = 'PlusJakartaSans';
}

abstract final class NoorTheme {
  static ThemeData light(Locale locale) => _build(NoorTokens.light, Brightness.light, locale);
  static ThemeData dark(Locale locale) => _build(NoorTokens.dark, Brightness.dark, locale);

  static ThemeData _build(NoorTokens t, Brightness b, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final ui = isAr ? NoorFonts.arabicUi : NoorFonts.latinUi;
    final fallback = isAr ? const [NoorFonts.latinUi, NoorFonts.display] : const [NoorFonts.arabicUi, NoorFonts.display]; // Amiri covers ﷺ
    final scheme = ColorScheme(
      brightness: b,
      primary: t.primary,
      onPrimary: t.onPrimary,
      secondary: t.gold,
      onSecondary: b == Brightness.light ? const Color(0xFF172B28) : const Color(0xFF0B1717),
      error: const Color(0xFFB23A1E),
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.text,
      outline: t.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: b,
      fontFamily: ui,
      fontFamilyFallback: fallback,
      scaffoldBackgroundColor: t.background,
      extensions: [t],
      splashFactory: InkSparkle.splashFactory,
    );
    final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text, fontFamily: ui, fontFamilyFallback: fallback);
    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: const TextStyle(fontFamily: NoorFonts.display, fontSize: 30, fontWeight: FontWeight.w700, height: 1.25).copyWith(color: t.text),
        // merge() keeps the UI font family set by apply() above.
        titleLarge: text.titleLarge!.merge(TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: t.text)),
        titleMedium: text.titleMedium!.merge(TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
        bodyLarge: text.bodyLarge!.merge(TextStyle(fontSize: 15, height: 1.6, color: t.text)),
        bodyMedium: text.bodyMedium!.merge(TextStyle(fontSize: 14, height: 1.55, color: t.text)),
        bodySmall: text.bodySmall!.merge(TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textSecondary)),
        labelLarge: text.labelLarge!.merge(const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      sliderTheme: SliderThemeData(activeTrackColor: t.primary, thumbColor: t.primary, inactiveTrackColor: t.sunk),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.text,
        contentTextStyle: TextStyle(fontFamily: ui, fontFamilyFallback: fallback, color: t.background, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        showDragHandle: true,
        dragHandleColor: t.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

/// Text styles that don't belong to Material's scale.
abstract final class NoorText {
  static TextStyle quran(BuildContext context, {double size = 26, Color? color}) => TextStyle(
        fontFamily: NoorFonts.quran,
        fontSize: size,
        height: 2.2,
        color: color ?? context.noor.text,
      );

  static TextStyle display(BuildContext context, {double size = 24, Color? color}) => TextStyle(
        fontFamily: NoorFonts.display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color ?? context.noor.text,
      );

  static TextStyle numerals({double size = 30, Color color = Colors.white, FontWeight weight = FontWeight.w600}) => TextStyle(
        fontFamily: NoorFonts.latinUi,
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
