import 'package:flutter/material.dart';

class AppTheme {
  static const Color neonPurple = Color(0xFFB026FF);
  static const Color neonRed = Color(0xFFFF003C);
  
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: neonPurple,
    scaffoldBackgroundColor: Colors.black, // True Black
    cardColor: const Color(0xFF111111), // Almost black
    colorScheme: const ColorScheme.dark(
      primary: neonPurple,
      secondary: neonRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: neonPurple),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: neonPurple, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light, // Generally, vault relies on dark theme, but keeping this linked just in case.
    primaryColor: neonPurple,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Soft white
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: neonPurple,
      secondary: neonRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F5F5),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: neonPurple),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),
     inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE0E0E0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: neonPurple, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    ),
  );
}
