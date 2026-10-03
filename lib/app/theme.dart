import 'package:flutter/material.dart';

import 'eo_components.dart';

ThemeData buildOutdoorTheme(Brightness brightness, {bool highContrast = false}) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark
      ? ColorScheme.dark(
          primary: EOColors.green,
          onPrimary: EOColors.white,
          primaryContainer: EOColors.greenSoft,
          onPrimaryContainer: EOColors.white,
          secondary: EOColors.textSecondary,
          onSecondary: EOColors.night,
          tertiary: EOColors.blue,
          onTertiary: EOColors.white,
          error: EOColors.red,
          onError: EOColors.white,
          surface: highContrast ? Colors.black : EOColors.surface,
          onSurface: EOColors.white,
          surfaceContainerHighest: EOColors.surfaceElevated,
          outline: EOColors.border,
          outlineVariant: EOColors.border,
        )
      : ColorScheme.light(
          primary: EOColors.green,
          onPrimary: EOColors.white,
          primaryContainer: const Color(0xFFDDF4E6),
          onPrimaryContainer: const Color(0xFF062B16),
          secondary: const Color(0xFF47605A),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFDCE9E4),
          onSecondaryContainer: const Color(0xFF10231D),
          tertiary: EOColors.blue,
          onTertiary: Colors.white,
          error: EOColors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF102326),
          surfaceContainerHighest: const Color(0xFFEAF1F1),
          outline: const Color(0xFF668083),
          outlineVariant: EOColors.border,
        );

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? EOColors.night : Colors.white,
  );
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: EOTextStyles.hero.copyWith(color: scheme.onSurface, fontSize: 32),
      headlineMedium: EOTextStyles.title.copyWith(color: scheme.onSurface),
      titleLarge: EOTextStyles.title.copyWith(color: scheme.onSurface),
      titleMedium: EOTextStyles.cardTitle.copyWith(color: scheme.onSurface),
      bodyLarge: EOTextStyles.body.copyWith(color: scheme.onSurface),
      bodyMedium: EOTextStyles.body.copyWith(color: scheme.onSurface),
      bodySmall: EOTextStyles.secondary.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: EOTextStyles.label.copyWith(color: scheme.onSurface),
    ),
    appBarTheme: AppBarTheme(
      toolbarHeight: 64,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? EOColors.night : Colors.white,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? EOColors.surface : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EORadii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EORadii.sm)),
      side: const BorderSide(color: EOColors.border),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? EOColors.surfaceElevated : const Color(0xFFEAF1F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EORadii.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EORadii.md),
        borderSide: const BorderSide(color: EOColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EORadii.md),
        borderSide: const BorderSide(color: EOColors.green, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: EOSpacing.lg, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: EOColors.green,
        foregroundColor: EOColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EORadii.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: scheme.onSurface,
        side: const BorderSide(color: EOColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EORadii.md)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: EOColors.green,
      foregroundColor: EOColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EORadii.md)),
    ),
    dividerTheme: const DividerThemeData(
      color: EOColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
