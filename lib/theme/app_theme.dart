import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf_learner_v2/config/platform_config.dart';

class AppTheme {
  // 앱 브랜드 색상 - 더 생생한 색상으로 업데이트
  static const Color primaryColor = Color(0xFF1976D2); // 밝은 파란색
  static const Color secondaryColor = Color(0xFF00BFA5); // 밝은 청록색
  static const Color accentColor = Color(0xFFFF4081); // 밝은 핑크
  static const Color tertiaryColor = Color(0xFFFF9800); // 밝은 주황색
  
  // 다크 모드 색상
  static const Color primaryDarkColor = Color(0xFF0D47A1); // 어두운 파란색
  static const Color secondaryDarkColor = Color(0xFF00796B); // 어두운 청록색
  static const Color accentDarkColor = Color(0xFFAD1457); // 어두운 핑크
  static const Color tertiaryDarkColor = Color(0xFFE65100); // 어두운 주황색
  static const Color surfaceDarkColor = Color(0xFF121212); // 다크 모드 배경색
  
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
  
  // 크로스 플랫폼 테마 적용을 위한 메서드
  static ThemeData getThemeForPlatform({required bool isDark, required BuildContext? context}) {
    final platform = PlatformConfig();
    
    if (platform.isIOS || platform.isMacOS) {
      return isDark ? _cupertinoThemeDark : _cupertinoThemeLight;
    } else {
      return isDark ? darkTheme : lightTheme;
    }
  }
  
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

  // 다크 테마 정의
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDarkColor,
      primary: primaryDarkColor,
      secondary: secondaryDarkColor,
      tertiary: tertiaryDarkColor,
      brightness: Brightness.dark,
    ),
    primaryColor: primaryDarkColor,
    scaffoldBackgroundColor: surfaceDarkColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDarkColor,
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: 4,
      margin: EdgeInsets.all(8),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 8,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryDarkColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      displayMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      displaySmall: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      headlineSmall: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleLarge: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleMedium: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleSmall: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
      bodyLarge: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      bodyMedium: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      bodySmall: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
      labelLarge: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      labelMedium: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    dividerColor: Colors.white30,
  );
  
  // Cupertino 스타일 라이트 테마
  static final ThemeData _cupertinoThemeLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      brightness: Brightness.light,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: CupertinoColors.systemBackground,
      foregroundColor: CupertinoColors.label,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: primaryColor,
      ),
    ),
    cardTheme: const CardTheme(
      color: CupertinoColors.systemBackground,
      elevation: 1,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display'),
      displayMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display'),
      displaySmall: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display'),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display'),
      headlineSmall: TextStyle(fontFamily: '.SF Pro Display'),
      titleLarge: TextStyle(fontFamily: '.SF Pro Display'),
      titleMedium: TextStyle(fontFamily: '.SF Pro Display'),
      titleSmall: TextStyle(fontFamily: '.SF Pro Text'),
      bodyLarge: TextStyle(fontFamily: '.SF Pro Text'),
      bodyMedium: TextStyle(fontFamily: '.SF Pro Text'),
      bodySmall: TextStyle(fontFamily: '.SF Pro Text'),
      labelLarge: TextStyle(fontFamily: '.SF Pro Text'),
      labelMedium: TextStyle(fontFamily: '.SF Pro Text'),
    ),
  );
  
  // Cupertino 스타일 다크 테마 
  static final ThemeData _cupertinoThemeDark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDarkColor,
      primary: primaryDarkColor,
      secondary: secondaryDarkColor,
      tertiary: tertiaryDarkColor,
      brightness: Brightness.dark,
    ),
    primaryColor: primaryDarkColor,
    scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: CupertinoColors.darkBackgroundGray,
      foregroundColor: CupertinoColors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: primaryColor,
      ),
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: 1,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      displayMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      displaySmall: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', color: Colors.white),
      headlineSmall: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleLarge: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleMedium: TextStyle(fontFamily: '.SF Pro Display', color: Colors.white),
      titleSmall: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
      bodyLarge: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      bodyMedium: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      bodySmall: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
      labelLarge: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white),
      labelMedium: TextStyle(fontFamily: '.SF Pro Text', color: Colors.white70),
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