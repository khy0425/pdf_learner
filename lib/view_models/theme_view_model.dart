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
    
    _themeMode = mode;
    
    try {
      await _saveThemePreference();
    } catch (e) {
      debugPrint('테마 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 저장된 테마 설정 불러오기
  Future<void> _loadThemePreference() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt('themeMode') ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
    } catch (e) {
      debugPrint('테마 불러오기 실패: $e');
      _themeMode = ThemeMode.system;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 테마 설정 저장하기
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
    } catch (e) {
      debugPrint('테마 저장 실패: $e');
    }
  }
} 