import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/core/design/theme.dart';
import 'package:note_app/core/design/tokens.dart';
import 'package:note_app/features/auth/auth_screens.dart';

double ratio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('all themes expose AppTokens', () {
    for (final theme in [AppTheme.light(), AppTheme.dark(), AppTheme.lain()]) {
      expect(theme.extension<AppTokens>(), isNotNull);
    }
  });

  test('measured contrast per theme', () {
    for (final t in [AppTokens.light, AppTokens.dark, AppTokens.lain]) {
      expect(ratio(t.text, t.bg), greaterThanOrEqualTo(4.5), reason: '${t.id} text/bg');
      expect(ratio(t.textMuted, t.bg), greaterThanOrEqualTo(3.0), reason: '${t.id} muted/bg');
      expect(ratio(t.accent, t.bg), greaterThanOrEqualTo(3.0), reason: '${t.id} accent/bg');
    }
  });

  test('logo mark switches with theme, one file per theme', () {
    final files = AppThemeId.values.map(AppLogoMark.assetFor).toList();
    expect(files.toSet().length, 3);
    expect(AppLogoMark.assetFor(AppThemeId.lain), contains('mark-phosphor'));
  });

  test('lain carries glow and pixel headings', () {
    expect(AppTokens.lain.isLain, isTrue);
    expect(AppTokens.lain.isDark, isTrue);
    expect(AppTokens.lain.headingGlow, isNotNull);
    expect(AppTokens.lain.headingFontFamily, 'PressStart2P');
    expect(AppTokens.lain.headingFontFallback, isNotEmpty);
    expect(AppTokens.light.headingGlow, isNull);
  });
}
