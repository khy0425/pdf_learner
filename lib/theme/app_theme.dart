import 'package:flutter/material.dart';

class AppTheme {
  // 앱 브랜드 색상
  static const Color primaryColor = Color(0xFF1565C0); // 더 진한 파란색
  static const Color secondaryColor = Color(0xFF00897B); // 더 진한 청록색
  static const Color accentColor = Color(0xFFD81B60); // 더 선명한 핫핑크
  static const Color tertiaryColor = Color(0xFFF57C00); // 더 진한 주황색
  
  // 그라데이션 색상
  static const List<Color> primaryGradient = [
    Color(0xFF0D47A1), // 매우 진한 파란색
    Color(0xFF1565C0), // 진한 파란색
    Color(0xFF1E88E5), // 밝은 파란색
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF004D40), // 매우 진한 청록색
    Color(0xFF00695C), // 진한 청록색
    Color(0xFF00897B), // 밝은 청록색
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: Colors.red[700]!,
      background: Colors.grey[50]!,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onError: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
    ),
    // PDF 뷰어 배경색
    scaffoldBackgroundColor: Colors.grey[50],
    // 드래그 앤 드롭 영역 스타일
    cardTheme: CardTheme(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // 버튼 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    // 앱바 스타일
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),
    // 텍스트 스타일
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    // 아이콘 테마
    iconTheme: IconThemeData(
      color: primaryColor,
      size: 24,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: Colors.red[300]!,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onError: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    // PDF 뷰어 배경색 (어두운 모드)
    scaffoldBackgroundColor: const Color(0xFF121212),
    // 드래그 앤 드롭 영역 스타일
    cardTheme: CardTheme(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    // 버튼 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // 앱바 스타일
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),
    // 텍스트 스타일
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    // 아이콘 테마
    iconTheme: IconThemeData(
      color: primaryColor,
      size: 24,
    ),
  );
  
  // 그라데이션 박스 데코레이션 생성
  static BoxDecoration gradientBoxDecoration({
    required List<Color> colors,
    double radius = 16.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.last.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
} 