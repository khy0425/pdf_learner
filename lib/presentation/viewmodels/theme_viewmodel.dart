import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 테마 설정을 관리하는 ViewModel
class ThemeViewModel extends ChangeNotifier {
  // 상태
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;
  
  // 생성자
  ThemeViewModel() {
    _loadThemePreference();
  }
  
  // 게터
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  
  // 기기 설정에 따라 테마 모드 설정
  Future<void> setSystemTheme() async {
    await _updateThemeMode(ThemeMode.system);
  }
  
  // 라이트 테마 설정
  Future<void> setLightTheme() async {
    await _updateThemeMode(ThemeMode.light);
  }
  
  // 다크 테마 설정
  Future<void> setDarkTheme() async {
    await _updateThemeMode(ThemeMode.dark);
  }
  
  // 테마 모드 토글
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setLightTheme();
    } else {
      await setDarkTheme();
    }
  }
  
  // 테마 모드 업데이트 및 저장
  Future<void> _updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _themeMode = mode;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', _themeModeToString(mode));
    } catch (e) {
      debugPrint('테마 저장 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 테마 모드 불러오기
  Future<void> _loadThemePreference() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString('themeMode');
      
      if (themeModeString != null) {
        _themeMode = _stringToThemeMode(themeModeString);
      }
    } catch (e) {
      debugPrint('테마 설정 로드 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ThemeMode를 문자열로 변환
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  // 문자열을 ThemeMode로 변환
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
} 