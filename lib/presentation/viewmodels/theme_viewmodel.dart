import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/base/base_viewmodel.dart';

/// 앱 테마 설정을 관리하는 ViewModel
class ThemeViewModel extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  
  final SharedPreferences _prefs;
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeViewModel({required SharedPreferences sharedPreferences}) 
      : _prefs = sharedPreferences {
    _loadTheme();
  }
  
  /// 테마 설정 불러오기
  Future<void> _loadTheme() async {
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }
  
  /// 테마 모드 설정
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    
    _isDarkMode = value;
    await _prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }
  
  /// 테마 모드 전환
  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
  
  /// 현재 테마 모드에 맞는 ThemeData 반환
  ThemeData get themeData {
    return _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }
} 