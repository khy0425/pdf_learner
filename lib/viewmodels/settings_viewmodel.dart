import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 관리 ViewModel
class SettingsViewModel with ChangeNotifier {
  static const String _fontSizeKey = 'font_size';
  static const String _autoSaveKey = 'auto_save';
  static const String _highlightColorKey = 'highlight_color';
  static const String _notificationKey = 'notifications';
  
  final SharedPreferences _prefs;
  
  SettingsViewModel(this._prefs);
  
  /// 글꼴 크기
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16.0;
  
  /// 자동 저장 활성화 여부
  bool get isAutoSaveEnabled => _prefs.getBool(_autoSaveKey) ?? true;
  
  /// 하이라이트 색상
  Color get highlightColor {
    final colorValue = _prefs.getInt(_highlightColorKey) ?? Colors.yellow.value;
    return Color(colorValue);
  }
  
  /// 알림 활성화 여부
  bool get isNotificationEnabled => _prefs.getBool(_notificationKey) ?? true;
  
  /// 글꼴 크기 설정
  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
    notifyListeners();
  }
  
  /// 자동 저장 설정
  Future<void> setAutoSave(bool value) async {
    await _prefs.setBool(_autoSaveKey, value);
    notifyListeners();
  }
  
  /// 하이라이트 색상 설정
  Future<void> setHighlightColor(Color color) async {
    await _prefs.setInt(_highlightColorKey, color.value);
    notifyListeners();
  }
  
  /// 알림 설정
  Future<void> setNotificationEnabled(bool value) async {
    await _prefs.setBool(_notificationKey, value);
    notifyListeners();
  }
  
  /// 설정 초기화
  Future<void> resetSettings() async {
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove(_autoSaveKey);
    await _prefs.remove(_highlightColorKey);
    await _prefs.remove(_notificationKey);
    notifyListeners();
  }
} 