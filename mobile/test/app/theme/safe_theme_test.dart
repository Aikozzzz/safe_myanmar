import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';

void main() {
  group('SafeTheme', () {
    test('uses Material 3 with exact light color roles', () {
      final theme = SafeTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.surface, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.onSurface, const Color(0xFF201D1D));
      expect(theme.colorScheme.primary, const Color(0xFF0056B3));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.error, const Color(0xFFB42318));
      expect(theme.colorScheme.onError, const Color(0xFFFDFCFC));
    });

    test('uses Material 3 with dedicated dark color roles', () {
      final theme = SafeTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.surface, const Color(0xFF201D1D));
      expect(theme.colorScheme.onSurface, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.primary, const Color(0xFF9CCAFF));
      expect(theme.colorScheme.onPrimary, const Color(0xFF002B5C));
      expect(theme.colorScheme.error, const Color(0xFFFFB4AB));
      expect(theme.colorScheme.onError, const Color(0xFF690005));
    });

    for (final themeFactory in <String, ThemeData Function()>{
      'light': SafeTheme.light,
      'dark': SafeTheme.dark,
    }.entries) {
      test('${themeFactory.key} uses accessible control sizing', () {
        final theme = themeFactory.value();

        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
        expect(
          minimumHeight(theme.elevatedButtonTheme.style),
          greaterThanOrEqualTo(48),
        );
        expect(
          minimumHeight(theme.filledButtonTheme.style),
          greaterThanOrEqualTo(48),
        );
        expect(
          minimumHeight(theme.outlinedButtonTheme.style),
          greaterThanOrEqualTo(48),
        );
        expect(
          minimumHeight(theme.textButtonTheme.style),
          greaterThanOrEqualTo(48),
        );
      });

      test('${themeFactory.key} has no proprietary font override', () {
        final theme = themeFactory.value();

        expect(theme.textTheme.bodyMedium?.fontFamily, isNot('Berkeley Mono'));
        expect(theme.typography, isNotNull);
      });

      test('${themeFactory.key} named color pairs meet AA contrast', () {
        final colors = themeFactory.value().colorScheme;

        expect(
          contrastRatio(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.onError, colors.error),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}

double minimumHeight(ButtonStyle? style) {
  return style?.minimumSize?.resolve(<WidgetState>{})?.height ?? 0;
}

double contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
