import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:injectable/injectable.dart';

import '../../core/base/base_viewmodel.dart';

/// 설정 관리 ViewModel
@injectable
class SettingsViewModel extends BaseViewModel {
  static const String _fontSizeKey = 'font_size';
  static const String _autoSaveKey = 'auto_save';
  static const String _highlightColorKey = 'highlight_color';
  static const String _notificationKey = 'notifications';
  
  /// SharedPreferences 인스턴스
  final SharedPreferences _prefs;
  late String _appVersion = '1.0.0';
  
  /// 앱 버전
  String get appVersion => _appVersion;
  
  /// 생성자
  SettingsViewModel(this._prefs) {
    _loadAppInfo();
    _loadSettings();
  }
  
  /// 앱 정보 로드
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      notifyListeners();
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }
  
  /// 개인정보 처리방침 열기
  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://pdf-learner.web.app/privacy');
    if (!await launchUrl(url)) {
      setError('URL을 열 수 없습니다: $url');
    }
  }
  
  /// 서비스 이용약관 열기
  Future<void> openTermsOfService() async {
    final Uri url = Uri.parse('https://pdf-learner.web.app/terms');
    if (!await launchUrl(url)) {
      setError('URL을 열 수 없습니다: $url');
    }
  }
  
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
    await _prefs.remove(_languageKey);
    await _prefs.remove(_notificationsEnabledKey);
    await _prefs.remove(_autoDownloadEnabledKey);
    await _prefs.remove(_dataSavingModeKey);
    _loadSettings();
    notifyListeners();
  }

  /// 언어 설정 키
  static const String _languageKey = 'language';

  /// 알림 설정 키
  static const String _notificationsEnabledKey = 'notifications_enabled';

  /// 자동 다운로드 설정 키
  static const String _autoDownloadEnabledKey = 'auto_download_enabled';

  /// 데이터 절약 모드 설정 키
  static const String _dataSavingModeKey = 'data_saving_mode';

  /// 앱 언어
  String _language = 'ko';
  /// 앱 언어 getter
  String get language => _language;

  /// 알림 활성화 여부
  bool _notificationsEnabled = true;
  /// 알림 활성화 여부 getter
  bool get notificationsEnabled => _notificationsEnabled;

  /// 자동 다운로드 활성화 여부
  bool _autoDownloadEnabled = false;
  /// 자동 다운로드 활성화 여부 getter
  bool get autoDownloadEnabled => _autoDownloadEnabled;

  /// 데이터 절약 모드 활성화 여부
  bool _dataSavingMode = false;
  /// 데이터 절약 모드 활성화 여부 getter
  bool get dataSavingMode => _dataSavingMode;

  /// 설정 로드
  void _loadSettings() {
    _language = _prefs.getString(_languageKey) ?? 'ko';
    _notificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    _autoDownloadEnabled = _prefs.getBool(_autoDownloadEnabledKey) ?? false;
    _dataSavingMode = _prefs.getBool(_dataSavingModeKey) ?? false;
    notifyListeners();
  }

  /// 언어 설정
  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString(_languageKey, language);
    notifyListeners();
  }

  /// 알림 설정
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }

  /// 자동 다운로드 설정
  Future<void> setAutoDownloadEnabled(bool enabled) async {
    _autoDownloadEnabled = enabled;
    await _prefs.setBool(_autoDownloadEnabledKey, enabled);
    notifyListeners();
  }

  /// 데이터 절약 모드 설정
  Future<void> setDataSavingMode(bool enabled) async {
    _dataSavingMode = enabled;
    await _prefs.setBool(_dataSavingModeKey, enabled);
    notifyListeners();
  }
} 