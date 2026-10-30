import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primarySky = Color(0xFF0284C7); // Main Sky Blue
  static const Color primaryLight = Color(0xFFE0F2FE); // Light Sky Background
  static const Color primaryDark = Color(0xFF0369A1); // Text & Highlight Dark
  static const Color accentCyan = Color(0xFF06B6D4); // Accent Button

  // Neutral Colors
  static const Color bgCanvas = Color(0xFFF8FAFC); // Light grey
  static const Color textMain = Color(0xFF0F172A); // Main text
  static const Color textMuted = Color(0xFF64748B); // Subtitle

  // Status Color
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySky,
        primary: primarySky,
        secondary: accentCyan,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySky,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }
}
