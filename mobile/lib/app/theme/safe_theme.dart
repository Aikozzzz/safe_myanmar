import 'package:flutter/material.dart';

abstract final class SafeTheme {
  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      surface: const Color(0xFFFDFCFC),
      onSurface: const Color(0xFF201D1D),
      primary: const Color(0xFF0056B3),
      onPrimary: const Color(0xFFFDFCFC),
      error: const Color(0xFFB42318),
      onError: const Color(0xFFFDFCFC),
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      surface: const Color(0xFF201D1D),
      onSurface: const Color(0xFFFDFCFC),
      primary: const Color(0xFF9CCAFF),
      onPrimary: const Color(0xFF002B5C),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
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

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: const ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: const FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    );
  }
}
