import 'package:flutter/material.dart';

class AppTheme {
  static const Color neonPurple = Color(0xFFB49EFF);
  static const Color neonRed = Color(0xFFF08CA1);
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
        seedColor: neonPurple,
        brightness: Brightness.dark,
        surface: const Color(0xFF14151F)),
    scaffoldBackgroundColor: const Color(0xFF0B0C14),
    cardTheme: CardThemeData(
        color: const Color(0xFF171823),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF292A3B)))),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0C14),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF10111B),
        indicatorColor: const Color(0xFF382D54),
        height: 76,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12))),
    chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0xFF323347)),
        selectedColor: const Color(0xFF382D54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: neonPurple,
            foregroundColor: const Color(0xFF20172F),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181925),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF303144))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF303144))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neonPurple, width: 2))),
  );
  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: neonPurple));
}
