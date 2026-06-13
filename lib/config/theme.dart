import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00E676);
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF141420);
  static const Color surfaceVariant = Color(0xFF1E1E2E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        surfaceVariant: surfaceVariant,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      useMaterial3: true,
    );
  }
}
