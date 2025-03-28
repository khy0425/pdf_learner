import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/base/base_viewmodel.dart';

/// 앱 테마 설정을 관리하는 ViewModel
class ThemeViewModel extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  // 누락된 getter 추가
  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _getLightTheme();
  ThemeData get darkTheme => _getDarkTheme();
  
  ThemeViewModel() {
    _loadTheme();
  }
  
  /// 테마 설정 불러오기
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
      notifyListeners();
    } catch (e) {
      debugPrint('테마 로드 중 오류: $e');
    }
  }
  
  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint('테마 저장 중 오류: $e');
    }
  }
  
  /// 테마 모드 전환
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : (_themeMode == ThemeMode.dark ? ThemeMode.system : ThemeMode.light);
    
    await setThemeMode(newMode);
  }
  
  /// 현재 테마 모드에 맞는 ThemeData 반환
  ThemeData get themeData {
    return _themeMode == ThemeMode.light 
        ? _getLightTheme() 
        : (_themeMode == ThemeMode.dark ? _getDarkTheme() : WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? _getDarkTheme() : _getLightTheme());
  }
  
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 