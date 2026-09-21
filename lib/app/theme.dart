import 'package:flutter/material.dart';

ThemeData buildOutdoorTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF1F6B4F),
  );

  return base.copyWith(
    scaffoldBackgroundColor: isDark ? const Color(0xFF0C1411) : const Color(0xFFF5F7F4),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0C1411) : const Color(0xFFF5F7F4),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
