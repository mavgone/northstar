// App themes: hand-built on Flutter ThemeData + our AppTokens extension.
// (flex_color_scheme v9 re-exports material_ui's ThemeData which clashes
// with Flutter's, so the theme is composed manually to stay offline-safe.)
import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static const Color seed = Color(0xFF6E56CF);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.light.bg,
      extensions: const [AppTokens.light],
      inputDecorationTheme: _input(AppTokens.light),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 500)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.dark.bg,
      extensions: const [AppTokens.dark],
      inputDecorationTheme: _input(AppTokens.dark),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 500)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData lain() {
    const t = AppTokens.lain;
    final scheme = ColorScheme.fromSeed(seedColor: t.accent, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      fontFamily: 'GohuFont',
      fontFamilyFallback: const ['Courier New', 'DejaVu Sans Mono', 'monospace'],
      extensions: const [AppTokens.lain],
      inputDecorationTheme: _input(t),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 500)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static InputDecorationTheme _input(AppTokens t) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: t.borderStrong),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: t.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: t.accent, width: 1.6),
      ),
      hintStyle: TextStyle(color: t.textFaint, fontSize: 13),
    );
  }
}
