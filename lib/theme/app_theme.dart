import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱의 테마 정의
class AppTheme {
  static const int _primaryColorValue = 0xFF2196F3;
  static const int _secondaryColorValue = 0xFF03A9F4;
  
  static const MaterialColor primarySwatch = MaterialColor(
    _primaryColorValue,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(_primaryColorValue),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );
  
  static const MaterialColor secondarySwatch = MaterialColor(
    _secondaryColorValue,
    <int, Color>{
      50: Color(0xFFE1F5FE),
      100: Color(0xFFB3E5FC),
      200: Color(0xFF81D4FA),
      300: Color(0xFF4FC3F7),
      400: Color(0xFF29B6F6),
      500: Color(_secondaryColorValue),
      600: Color(0xFF039BE5),
      700: Color(0xFF0288D1),
      800: Color(0xFF0277BD),
      900: Color(0xFF01579B),
    },
  );

  // 라이트 테마
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(_primaryColorValue),
        brightness: Brightness.light,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(_primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(_primaryColorValue),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(_primaryColorValue),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(_primaryColorValue),
            width: 2,
          ),
        ),
      ),
    );
  }

  // 다크 테마
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(_primaryColorValue),
        brightness: Brightness.dark,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(_primaryColorValue),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(_primaryColorValue),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(_primaryColorValue),
            width: 2,
          ),
        ),
      ),
    );
  }
} 