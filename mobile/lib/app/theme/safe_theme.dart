import 'package:flutter/material.dart';

import 'safe_tokens.dart';

abstract final class SafeTheme {
  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      background: const Color(0xFFF7FAFA),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF14212B),
      primary: const Color(0xFF0E7C78),
      onPrimary: const Color(0xFFFFFFFF),
      error: const Color(0xFFD92D20),
      onError: const Color(0xFFFFFFFF),
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      background: const Color(0xFF0B171D),
      surface: const Color(0xFF14212B),
      onSurface: const Color(0xFFF7FAFA),
      primary: const Color(0xFF70D5CF),
      onPrimary: const Color(0xFF003734),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color onPrimary,
    required Color error,
    required Color onError,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          surface: surface,
          onSurface: onSurface,
          primary: primary,
          onPrimary: onPrimary,
          error: error,
          onError: onError,
        );
    const buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(48, 48)),
    );
    final typography = Typography.material2021(
      platform: null,
      colorScheme: colorScheme,
      black: _systemTextTheme(onSurface),
      white: _systemTextTheme(onSurface),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      typography: typography,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: const ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: const FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: const TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: SafeElevation.card,
        shape: RoundedRectangleBorder(borderRadius: SafeRadii.md),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(
          alpha: brightness == Brightness.dark ? 0.45 : 0.7,
        ),
        border: const OutlineInputBorder(borderRadius: SafeRadii.sm),
        enabledBorder: OutlineInputBorder(
          borderRadius: SafeRadii.sm,
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SafeRadii.sm,
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        height: 80,
        indicatorColor: primary.withValues(alpha: 0.16),
      ),
    );
  }

  static TextTheme _systemTextTheme(Color color) {
    final style = TextStyle(color: color, decoration: TextDecoration.none);
    return TextTheme(
      displayLarge: style,
      displayMedium: style,
      displaySmall: style,
      headlineLarge: style,
      headlineMedium: style,
      headlineSmall: style,
      titleLarge: style,
      titleMedium: style,
      titleSmall: style,
      bodyLarge: style,
      bodyMedium: style,
      bodySmall: style,
      labelLarge: style,
      labelMedium: style,
      labelSmall: style,
    );
  }
}
