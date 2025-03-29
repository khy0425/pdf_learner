import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/dependency_injection.dart';

/// 앱 테마 설정을 관리하는 ViewModel
class ThemeViewModel extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences _prefs;
  
  // 실제 사용할 테마들
  ThemeData _lightTheme = AppTheme.lightTheme;
  ThemeData _darkTheme = AppTheme.darkTheme;
  
  // 누락된 getter 추가
  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  
  ThemeViewModel({required SharedPreferences sharedPreferences}) 
      : _prefs = sharedPreferences {
    _init();
  }
  
  /// 초기화
  Future<void> _init() async {
    try {
      // 저장된 테마 모드 가져오기
      final savedMode = _prefs.getString('themeMode');
      
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
            break;
        }
      } else {
        // 기본값은 시스템 설정 사용
        _themeMode = ThemeMode.system;
      }
      
      // 상태바 스타일 설정
      _updateSystemUI();
      
      notifyListeners();
    } catch (e) {
      debugPrint('테마 초기화 오류: $e');
    }
  }
  
  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    // 설정 저장
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
        break;
    }
    
    await _prefs.setString('themeMode', modeString);
    
    // 시스템 UI 업데이트
    _updateSystemUI();
    
    notifyListeners();
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
        ? _lightTheme 
        : (_themeMode == ThemeMode.dark ? _darkTheme : WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? _darkTheme : _lightTheme);
  }
  
  // 현재 실제 사용되는 테마 (다크모드 여부 고려)
  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
          ? _darkTheme
          : _lightTheme;
    }
    return _themeMode == ThemeMode.dark ? _darkTheme : _lightTheme;
  }
  
  // 다크 모드 여부
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // 시스템 UI 업데이트 (상태바 색상 등)
  void _updateSystemUI() {
    final currentBrightness = isDarkMode ? Brightness.dark : Brightness.light;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: currentBrightness,
      statusBarIconBrightness: currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: currentBrightness == Brightness.dark ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness: currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));
  }
  
  // 커스텀 테마 적용 (옵션)
  void applyCustomTheme(ThemeData lightTheme, ThemeData darkTheme) {
    _lightTheme = lightTheme;
    _darkTheme = darkTheme;
    _updateSystemUI();
    notifyListeners();
  }
} 