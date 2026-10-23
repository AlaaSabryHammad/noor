import 'package:flutter/material.dart';

import 'noor_colors.dart';

/// Theme-aware design tokens. Read with `context.noor`.
@immutable
class NoorTokens extends ThemeExtension<NoorTokens> {
  const NoorTokens({
    required this.background,
    required this.surface,
    required this.sunk,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.primaryLine,
    required this.gold,
    required this.goldText,
    required this.goldSoft,
    required this.goldLine,
    required this.reader,
    required this.heroGradient,
    required this.cardShadow,
    required this.navBackground,
  });

  final Color background;
  final Color surface;
  final Color sunk;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color primaryLine;
  final Color gold;
  final Color goldText;
  final Color goldSoft;
  final Color goldLine;
  final Color reader;
  final Gradient heroGradient;
  final List<BoxShadow> cardShadow;
  final Color navBackground;

  /// Text and accents that sit on the hero gradient (same in both modes).
  static const onHero = Colors.white;
  static const onHeroAccent = NoorPalette.darkGold;

  static const light = NoorTokens(
    background: NoorPalette.ivory,
    surface: NoorPalette.white,
    sunk: NoorPalette.sunk,
    text: NoorPalette.text,
    textSecondary: NoorPalette.textSecondary,
    border: NoorPalette.border,
    borderStrong: NoorPalette.borderStrong,
    primary: NoorPalette.emerald,
    onPrimary: Colors.white,
    primarySoft: NoorPalette.emeraldSoft,
    primaryLine: Color(0xFFBFE0D6),
    gold: NoorPalette.gold,
    goldText: NoorPalette.goldText,
    goldSoft: NoorPalette.goldSoft,
    goldLine: NoorPalette.goldLine,
    reader: NoorPalette.readerLight,
    heroGradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color(0xFF0B7565), NoorPalette.forest, Color(0xFF053E37)],
      stops: [0, .58, 1],
    ),
    cardShadow: [
      BoxShadow(color: Color(0x0A172B28), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x1F172B28), blurRadius: 26, spreadRadius: -12, offset: Offset(0, 10)),
    ],
    navBackground: Color(0xE6FFFFFF),
  );

  static const dark = NoorTokens(
    background: NoorPalette.darkBg,
    surface: NoorPalette.darkSurface,
    sunk: NoorPalette.darkSunk,
    text: NoorPalette.darkText,
    textSecondary: NoorPalette.darkTextSecondary,
    border: NoorPalette.darkBorder,
    borderStrong: NoorPalette.darkBorderStrong,
    primary: NoorPalette.darkEmerald,
    onPrimary: NoorPalette.darkOnEmerald,
    primarySoft: NoorPalette.darkEmeraldSoft,
    primaryLine: Color(0xFF2C6A5E),
    gold: NoorPalette.darkGold,
    goldText: NoorPalette.darkGold,
    goldSoft: NoorPalette.darkGoldSoft,
    goldLine: NoorPalette.darkGoldLine,
    reader: NoorPalette.readerDark,
    heroGradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color(0xFF174A42), Color(0xFF0F332E), Color(0xFF0B2623)],
      stops: [0, .6, 1],
    ),
    cardShadow: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x80000000), blurRadius: 30, spreadRadius: -14, offset: Offset(0, 12)),
    ],
    navBackground: Color(0xEB142423),
  );

  @override
  NoorTokens copyWith() => this;

  @override
  NoorTokens lerp(ThemeExtension<NoorTokens>? other, double t) {
    if (other is! NoorTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return NoorTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      sunk: c(sunk, other.sunk),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primarySoft: c(primarySoft, other.primarySoft),
      primaryLine: c(primaryLine, other.primaryLine),
      gold: c(gold, other.gold),
      goldText: c(goldText, other.goldText),
      goldSoft: c(goldSoft, other.goldSoft),
      goldLine: c(goldLine, other.goldLine),
      reader: c(reader, other.reader),
      heroGradient: t < .5 ? heroGradient : other.heroGradient,
      cardShadow: t < .5 ? cardShadow : other.cardShadow,
      navBackground: c(navBackground, other.navBackground),
    );
  }
}

/// Spacing, radii and motion tokens.
abstract final class NoorSpace {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const double screenPadding = 20;
}

abstract final class NoorRadius {
  static const double xs = 10, sm = 14, md = 18, card = 24, hero = 30, pill = 999;
}

abstract final class NoorMotion {
  static const press = Duration(milliseconds: 180);
  static const enter = Duration(milliseconds: 420);
  static const sheet = Duration(milliseconds: 380);
  static const theme = Duration(milliseconds: 500);
  static const curve = Cubic(.2, .8, .2, 1);
}

extension NoorContext on BuildContext {
  NoorTokens get noor => Theme.of(this).extension<NoorTokens>()!;
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
