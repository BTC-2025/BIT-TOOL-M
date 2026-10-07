import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeumorphicTheme {
  // Light Mode Colors (Elite Premium Palette)
  static const Color lightBg = Color(
    0xFFE6EEF8,
  ); // Soft cool blue-grey background
  static const Color lightCard = Color(
    0xFFE6EEF8,
  ); // Identical for seamless neumorphic blending
  static const Color lightDarkShadow = Color(
    0xFFB8C4D9,
  ); // Softer, less harsh dark shadow
  static const Color lightLightShadow = Color(
    0xFFFFFFFF,
  ); // Clean white highlight
  static const Color lightText = Color(
    0xFF1E293B,
  ); // Slate 800 for high-contrast, premium readability
  static const Color lightAccent = Color(0xFF3B82F6); // Premium Blue

  // Dark Mode Colors (Elite Premium Palette)
  static const Color darkBg = Color(
    0xFF0E131F,
  ); // Deep rich navy-slate background
  static const Color darkCard = Color(0xFF0E131F); // Blended card
  static const Color darkDarkShadow = Color(0xFF06090F); // Very deep shadow
  static const Color darkLightShadow = Color(
    0xFF1B2336,
  ); // Soft reflective highlight
  static const Color darkText = Color(0xFFF1F5F9); // Slate 100
  static const Color darkAccent = Color(0xFF60A5FA); // Bright Premium Blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightAccent,
      cardColor: lightCard,
      colorScheme: const ColorScheme.light(
        surface: lightBg,
        primary: lightAccent,
        onSurface: lightText,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(
            color: lightText,
            fontSize: 16,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: lightText,
            fontSize: 14,
            letterSpacing: -0.1,
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            color: lightText,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkAccent,
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        surface: darkBg,
        primary: darkAccent,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(
            color: darkText,
            fontSize: 16,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: darkText,
            fontSize: 14,
            letterSpacing: -0.1,
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
