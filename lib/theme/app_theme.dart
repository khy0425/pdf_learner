import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    // PDF 뷰어 배경색
    scaffoldBackgroundColor: Colors.white,
    // 드래그 앤 드롭 영역 스타일
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    // PDF 뷰어 배경색 (어두운 모드)
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    // 드래그 앤 드롭 영역 스타일
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
} 