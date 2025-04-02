import 'package:flutter/material.dart';

/// 앱 테마 정의
class AppTheme {
  AppTheme._();
  
  /// 기본 색상
  static const Color primaryColor = Color(0xFF5D5FEF);
  static const Color secondaryColor = Color(0xFF00C853);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFD32F2F);
  
  /// 라이트 테마
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        inherit: true,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, inherit: true),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, inherit: true),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, inherit: true),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, inherit: true),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, inherit: true),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, inherit: true),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, inherit: true),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, inherit: true),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, inherit: true),
      bodyLarge: TextStyle(fontSize: 16, inherit: true),
      bodyMedium: TextStyle(fontSize: 14, inherit: true),
      bodySmall: TextStyle(fontSize: 12, inherit: true),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, inherit: true),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, inherit: true),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, inherit: true),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
  
  /// 다크 테마
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        inherit: true,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, inherit: true),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, inherit: true),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, inherit: true),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, inherit: true),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white, inherit: true),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white, inherit: true),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white, inherit: true),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2C2C2C),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

// 앱에서 사용할 모든 텍스트 스타일 정의
class AppTextStyles {
  // 헤더 스타일
  static TextStyle h1 = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    inherit: true,
  );
  
  static TextStyle h2 = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    inherit: true,
  );
  
  static TextStyle h3 = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    inherit: true,
  );
  
  // 본문 스타일
  static TextStyle body = const TextStyle(
    fontSize: 16,
    inherit: true,
  );
  
  static TextStyle bodySmall = const TextStyle(
    fontSize: 14,
    inherit: true,
  );
  
  static TextStyle caption = const TextStyle(
    fontSize: 12,
    inherit: true,
  );
  
  // 강조 스타일
  static TextStyle emphasis = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    inherit: true,
  );
  
  // 버튼 스타일
  static TextStyle button = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    inherit: true,
  );
  
  // 링크 스타일
  static TextStyle link = const TextStyle(
    fontSize: 16,
    decoration: TextDecoration.underline,
    inherit: true,
  );
  
  // 기타 스타일
  static TextStyle hint = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    inherit: true,
  );
  
  static TextStyle error = TextStyle(
    fontSize: 14,
    color: Colors.red,
    inherit: true,
  );
} 