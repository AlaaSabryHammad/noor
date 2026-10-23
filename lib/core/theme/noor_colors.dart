import 'package:flutter/material.dart';

/// Raw palette from the NOOR design system (canvas board "نظام التصميم").
/// Widgets should read colours through [NoorTokens] (theme-aware), not here.
abstract final class NoorPalette {
  // Light
  static const emerald = Color(0xFF087F6D);
  static const forest = Color(0xFF064E45);
  static const gold = Color(0xFFC8A45D);
  static const goldText = Color(0xFF80612A); // gold that passes 4.5:1 on ivory
  static const ivory = Color(0xFFFAF9F5);
  static const white = Color(0xFFFFFFFF);
  static const sunk = Color(0xFFF1EFE8);
  static const text = Color(0xFF172B28);
  static const textSecondary = Color(0xFF5E6A66); // #75817D fails AA for small text
  static const border = Color(0xFFE7EBE5);
  static const borderStrong = Color(0xFFCBD3CC);
  static const emeraldSoft = Color(0xFFE7F2EE);
  static const goldSoft = Color(0xFFF7F0E1);
  static const goldLine = Color(0xFFEADBB8);
  static const readerLight = Color(0xFFFBF8F0);

  // Dark
  static const darkBg = Color(0xFF0B1717);
  static const darkSurface = Color(0xFF142423);
  static const darkSurfaceHigh = Color(0xFF1B302D);
  static const darkSunk = Color(0xFF0F1E1D);
  static const darkEmerald = Color(0xFF43B99F);
  static const darkGold = Color(0xFFE0C486);
  static const darkText = Color(0xFFF4F6F1);
  static const darkTextSecondary = Color(0xFFA8BCB5);
  static const darkBorder = Color(0xFF223A36);
  static const darkBorderStrong = Color(0xFF2F4B46);
  static const darkEmeraldSoft = Color(0xFF163631);
  static const darkGoldSoft = Color(0xFF1F2A22);
  static const darkGoldLine = Color(0xFF4A4430);
  static const darkOnEmerald = Color(0xFF06231E);
  static const readerDark = Color(0xFF101C1B);
}
