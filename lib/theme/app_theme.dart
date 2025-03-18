import 'package:flutter/material.dart';

class AppTheme {
  // 앱 브랜드 색상 - 더 생생한 색상으로 업데이트
  static const Color primaryColor = Color(0xFF1976D2); // 밝은 파란색
  static const Color secondaryColor = Color(0xFF00BFA5); // 밝은 청록색
  static const Color accentColor = Color(0xFFFF4081); // 밝은 핑크
  static const Color tertiaryColor = Color(0xFFFF9800); // 밝은 주황색
  
  // 그라데이션 색상 - 더 다양한 색상으로 업데이트
  static const List<Color> primaryGradient = [
    Color(0xFF1A237E), // 매우 진한 파란색
    Color(0xFF1976D2), // 중간 파란색
    Color(0xFF42A5F5), // 밝은 파란색
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF004D40), // 매우 진한 청록색
    Color(0xFF00BFA5), // 중간 청록색
    Color(0xFF64FFDA), // 밝은 청록색
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFFC2185B), // 진한 핑크
    Color(0xFFFF4081), // 중간 핑크
    Color(0xFFFF80AB), // 밝은 핑크
  ];
  
  static const List<Color> tertiaryGradient = [
    Color(0xFFE65100), // 진한 주황색
    Color(0xFFFF9800), // 중간 주황색
    Color(0xFFFFCC80), // 밝은 주황색
  ];
  
  // 라이트 테마 정의
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      brightness: Brightness.light,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade400;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade400;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade400;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Colors.grey.shade200,
      linearTrackColor: Colors.grey.shade200,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.grey.shade800),
      bodyMedium: TextStyle(color: Colors.grey.shade800),
      bodySmall: TextStyle(color: Colors.grey.shade700),
      labelLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Colors.grey.shade900),
      labelSmall: TextStyle(color: Colors.grey.shade900),
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
      shadowColor: primaryColor.withOpacity(0.5),
    ),
    // 버튼 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
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
    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // 버튼 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return const Color(0xFF3A3A3A);
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
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
  
  // 그라데이션 버튼 데코레이션
  static BoxDecoration gradientButtonDecoration({
    List<Color>? colors,
    double radius = 12.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (colors ?? primaryGradient).last.withOpacity(0.3),
          blurRadius: 4,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // 카드 데코레이션
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 16.0,
    double elevation = 4.0,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          spreadRadius: elevation / 2,
          offset: Offset(0, elevation / 2),
        ),
      ],
    );
  }
} 