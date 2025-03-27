import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

@singleton
class ThemeService {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _fontSizeKey = 'font_size';

  ThemeService(@Named('sharedPreferences') this._prefs);

  /// 현재 테마 모드
  ThemeMode get themeMode {
    final String? mode = _prefs.getString(_themeKey);
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs.setString(_themeKey, value);
  }

  /// 현재 기본 색상
  Color get primaryColor {
    final int? colorValue = _prefs.getInt(_primaryColorKey);
    return Color(colorValue ?? Colors.blue.value);
  }

  /// 기본 색상 설정
  Future<void> setPrimaryColor(Color color) async {
    await _prefs.setInt(_primaryColorKey, color.value);
  }

  /// 현재 글자 크기
  double get fontSize {
    return _prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  /// 글자 크기 설정
  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  /// 테마 설정 초기화
  Future<void> reset() async {
    await _prefs.remove(_themeKey);
    await _prefs.remove(_primaryColorKey);
    await _prefs.remove(_fontSizeKey);
  }

  /// 다크 모드 토글
  Future<void> toggleThemeMode() async {
    final isDark = _prefs.getBool(_themeKey) ?? false;
    await _prefs.setBool(_themeKey, !isDark);
  }

  /// 시스템 테마 모드 사용
  Future<void> useSystemTheme() async {
    await _prefs.remove(_themeKey);
  }

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }
} 