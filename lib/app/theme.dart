import 'package:flutter/material.dart';

import 'brand.dart';

ThemeData buildOutdoorTheme(Brightness brightness, {bool highContrast = false}) {
  final isDark = brightness == Brightness.dark;

  final scheme = isDark
      ? ColorScheme.dark(
          primary: OutdoorBrand.forestLight,
          onPrimary: OutdoorBrand.darkBackground,
          primaryContainer: const Color(0xFF1E4F3D),
          onPrimaryContainer: OutdoorBrand.textDark,
          secondary: OutdoorBrand.earthLight,
          onSecondary: const Color(0xFF2A2115),
          secondaryContainer: const Color(0xFF4B3A21),
          onSecondaryContainer: OutdoorBrand.textDark,
          tertiary: OutdoorBrand.waterLight,
          onTertiary: const Color(0xFF06212A),
          error: OutdoorBrand.emergency,
          onError: Colors.white,
          surface: highContrast ? Colors.black : OutdoorBrand.darkSurface,
          onSurface: OutdoorBrand.textDark,
          surfaceContainerHighest: const Color(0xFF22332D),
          outline: const Color(0xFF8EA39B),
          outlineVariant: const Color(0xFF41534C),
        )
      : ColorScheme.light(
          primary: OutdoorBrand.forest,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFD6EDE3),
          onPrimaryContainer: OutdoorBrand.textLight,
          secondary: const Color(0xFF80633D),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFF0E2CC),
          onSecondaryContainer: OutdoorBrand.textLight,
          tertiary: OutdoorBrand.water,
          onTertiary: Colors.white,
          error: OutdoorBrand.danger,
          onError: Colors.white,
          surface: highContrast ? Colors.white : OutdoorBrand.lightSurface,
          onSurface: OutdoorBrand.textLight,
          surfaceContainerHighest: const Color(0xFFE7ECE9),
          outline: const Color(0xFF60736C),
          outlineVariant: const Color(0xFFB7C4BF),
        );

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? OutdoorBrand.darkBackground : OutdoorBrand.lightBackground,
  );

  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark
          ? OutdoorBrand.darkBackground
          : OutdoorBrand.lightBackground,
      foregroundColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? OutdoorBrand.darkSurface : OutdoorBrand.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: isDark ? OutdoorBrand.darkSurface : Colors.white,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? OutdoorBrand.darkSurface : Colors.white,
      indicatorColor: scheme.primaryContainer,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF172A23) : const Color(0xFFEFF3F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
