// Own Design System: single source of truth for color / type / space / radius / motion.
// Widgets must use these tokens via context.tokens. No raw hex in widgets.
//
// Themes: light, dark, lain (Serial Experiments Lain terminal: phosphor
// green on deep green-black, PressStart2P headings, GohuFont body).
import 'package:flutter/material.dart';

/// Theme ids owned by the design system. ThemeMode stays Flutter-side.
enum AppThemeId { light, dark, lain }

/// Spacing scale (4pt base).
abstract class AppSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
}

/// Radii.
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double pill = 999;
}

/// Motion durations (calm, not excessive).
abstract class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
  static const Curve ease = Curves.easeOutCubic;
}

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.id,
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warningSoft,
    required this.hover,
    required this.selected,
    required this.shadow,
    required this.isDark,
    this.isLain = false,
    this.headingFontFamily,
    this.headingFontFallback = const [],
    this.headingGlow,
  });

  final AppThemeId id;
  final Color bg;
  final Color panel;
  final Color panel2;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warningSoft;
  final Color hover;
  final Color selected;
  final Color shadow;
  final bool isDark;
  final bool isLain;
  final String? headingFontFamily;
  final List<String> headingFontFallback;
  final List<Shadow>? headingGlow;

  static const light = AppTokens(
    id: AppThemeId.light,
    bg: Color(0xFFF7F7F5),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF1F1EE),
    border: Color(0xFFE7E5E0),
    borderStrong: Color(0xFFD9D7D1),
    text: Color(0xFF1A1C1E),
    textMuted: Color(0xFF565B61),
    textFaint: Color(0xFF7E838A),
    accent: Color(0xFF6E56CF),
    accentSoft: Color(0xFFEEE9FE),
    danger: Color(0xFFD92D20),
    dangerSoft: Color(0xFFFDECEA),
    warningSoft: Color(0xFFFFF3D6),
    hover: Color(0x0F000000),
    selected: Color(0x146E56CF),
    shadow: Color(0x1A000000),
    isDark: false,
  );

  static const dark = AppTokens(
    id: AppThemeId.dark,
    bg: Color(0xFF131314),
    panel: Color(0xFF1B1B1D),
    panel2: Color(0xFF232326),
    border: Color(0xFF2C2C30),
    borderStrong: Color(0xFF3A3A40),
    text: Color(0xFFF2F1ED),
    textMuted: Color(0xFFA7AAB0),
    textFaint: Color(0xFF7E838B),
    accent: Color(0xFF9E8CFC),
    accentSoft: Color(0xFF2A2540),
    danger: Color(0xFFF97066),
    dangerSoft: Color(0xFF3A2320),
    warningSoft: Color(0xFF3A3220),
    hover: Color(0x14FFFFFF),
    selected: Color(0x2E9E8CFC),
    shadow: Color(0x66000000),
    isDark: true,
  );

  /// Lain: Serial Experiments Lain terminal. Deep green-black, phosphor
  /// green text, PressStart2P headings with a soft green glow, GohuFont body.
  static const lain = AppTokens(
    id: AppThemeId.lain,
    bg: Color(0xFF060906),
    panel: Color(0xFF0C120C),
    panel2: Color(0xFF141C14),
    border: Color(0xFF1F2E1F),
    borderStrong: Color(0xFF33502F),
    text: Color(0xFFC9E8C9),
    textMuted: Color(0xFF7BA07B),
    textFaint: Color(0xFF4E6B4E),
    accent: Color(0xFF4ADE80),
    accentSoft: Color(0xFF0F2417),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF2A1215),
    warningSoft: Color(0xFF241D0E),
    hover: Color(0x144ADE80),
    selected: Color(0x2B4ADE80),
    shadow: Color(0xAA000000),
    isDark: true,
    isLain: true,
    headingFontFamily: 'PressStart2P',
    headingFontFallback: ['GohuFont', 'Courier New', 'monospace'],
    headingGlow: [
      Shadow(color: Color(0xBFE2FFDC), blurRadius: 6),
      Shadow(color: Color(0x404ADE80), blurRadius: 14),
    ],
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => t < 0.5 ? this : (other as AppTokens?) ?? this;
}

extension TokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

/// Theme-aware heading styles. In lain they pick up the pixel face plus glow.
extension ThemeTextX on BuildContext {
  TextStyle get displayGlow => AppType.display.copyWith(
        color: tokens.text,
        fontFamily: tokens.headingFontFamily,
        fontFamilyFallback: tokens.headingFontFallback,
        shadows: tokens.headingGlow,
      );
  TextStyle get headlineGlow => AppType.headline.copyWith(
        color: tokens.text,
        fontFamily: tokens.headingFontFamily,
        fontFamilyFallback: tokens.headingFontFallback,
        shadows: tokens.headingGlow,
      );
}

abstract class AppType {
  static const TextStyle display = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2);
  static const TextStyle title = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3);
  static const TextStyle headline = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35);
  static const TextStyle body = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, height: 1.55);
  static const TextStyle small = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.45);
  static const TextStyle caption = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle mono = TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5);
}
