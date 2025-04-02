import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf_learner_v2/config/platform_config.dart';

class AppTheme {
  // UPDF 스타일의 브랜드 색상
  static const Color primaryColor = Color(0xFF2D81FF); // UPDF 메인 파란색
  static const Color secondaryColor = Color(0xFF4FC3F7); // 밝은 하늘색
  static const Color accentColor = Color(0xFF00C896); // 민트 그린
  static const Color tertiaryColor = Color(0xFFFFA726); // 밝은 주황색
  
  // 다크 모드 색상
  static const Color primaryDarkColor = Color(0xFF1A73E8); // 어두운 파란색
  static const Color secondaryDarkColor = Color(0xFF0288D1); // 어두운 하늘색
  static const Color accentDarkColor = Color(0xFF00A37A); // 어두운 민트
  static const Color tertiaryDarkColor = Color(0xFFE68A00); // 어두운 주황색
  static const Color surfaceDarkColor = Color(0xFF121212); // 다크 모드 배경색
  
  // 그라데이션 색상
  static const List<Color> primaryGradient = [
    Color(0xFF1565C0), 
    Color(0xFF2D81FF), 
    Color(0xFF64B5F6),
  ];
  
  // 중립 색상 - UPDF 스타일
  static const Color neutral100 = Color(0xFFF8F9FA); // 매우 밝은 회색
  static const Color neutral200 = Color(0xFFEEEEEE); // 밝은 회색
  static const Color neutral300 = Color(0xFFE0E0E0); // 회색
  static const Color neutral400 = Color(0xFFBDBDBD); // 중간 회색
  static const Color neutral500 = Color(0xFF9E9E9E); // 회색
  static const Color neutral600 = Color(0xFF757575); // 진한 회색
  static const Color neutral700 = Color(0xFF616161); // 더 진한 회색
  static const Color neutral800 = Color(0xFF424242); // 매우 진한 회색
  static const Color neutral900 = Color(0xFF212121); // 거의 검정색
  
  static const Color disabledColor = Color(0xFFBDBDBD);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color bottomBarColor = Color(0xFF333333);
  
  // 툴바 색상
  static const Color toolbarBackgroundColor = Color(0xFF333333);
  static const Color toolbarTextColor = Colors.white;
  
  // 크로스 플랫폼 테마 적용을 위한 메서드
  static ThemeData getThemeForPlatform({required bool isDark, required BuildContext? context}) {
    final platform = PlatformConfig();
    
    if (platform.isIOS || platform.isMacOS) {
      return isDark ? _cupertinoThemeDark : _cupertinoThemeLight;
    } else {
      return isDark ? darkTheme : lightTheme;
    }
  }
  
  // 라이트 테마 정의 - UPDF 스타일
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
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: neutral900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: neutral900,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        inherit: true,
      ),
      iconTheme: IconThemeData(color: neutral900),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(120, 44),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(120, 44),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: neutral500,
        fontSize: 16,
        inherit: true,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return neutral300;
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
        return neutral400;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return neutral300;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: neutral200,
      linearTrackColor: neutral200,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        inherit: true,
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: neutral600,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        inherit: true,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        inherit: true,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: neutral600,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        inherit: true,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        inherit: true,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: neutral200,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: neutral900, inherit: true),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: neutral900, inherit: true),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: neutral900, inherit: true),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: neutral900, inherit: true),
      bodyLarge: TextStyle(fontSize: 16, color: neutral900, inherit: true),
      bodyMedium: TextStyle(fontSize: 14, color: neutral900, inherit: true),
      bodySmall: TextStyle(fontSize: 12, color: neutral900, inherit: true),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: neutral900, inherit: true),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: neutral900, inherit: true),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: neutral900, inherit: true),
    ),
    // 추가: UPDF 스타일의 슬라이더 테마
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: neutral200,
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.2),
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    // 추가: UPDF 스타일의 팝업메뉴 테마
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: neutral800,
        fontSize: 14,
        inherit: true,
      ),
    ),
  );

  // 다크 테마 정의 - UPDF 스타일
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
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        inherit: true,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: Color(0xFF272727),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDarkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(120, 44),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          inherit: true,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryDarkColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 16,
        inherit: true,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFFBDBDBD),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        inherit: true,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
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
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0), inherit: true),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0), inherit: true),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD), inherit: true),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white, inherit: true),
    ),
    // 다크 모드에서도 동일하게 적용
    dialogTheme: DialogTheme(
      backgroundColor: Color(0xFF272727),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
  
  // cupertino 테마 정의 - 나머지 코드 유지
  static final _cupertinoThemeLight = ThemeData(
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
  
  static final _cupertinoThemeDark = ThemeData(
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