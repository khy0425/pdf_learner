import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정을 관리하는 ViewModel
class SettingsViewModel extends ChangeNotifier {
  // 상태
  Locale _locale = const Locale('ko'); // 기본 언어 한국어
  bool _isLoading = false;
  double _fontSize = 16.0; // 기본 폰트 크기
  bool _enableNotifications = true; // 기본 알림 설정
  bool _automaticDownload = false; // 자동 다운로드 설정
  String _defaultDownloadPath = ''; // 기본 다운로드 경로
  int _pdfCacheLimit = 100; // PDF 캐시 크기 제한 (MB)
  
  // 생성자
  SettingsViewModel() {
    _loadSettings();
  }
  
  // 게터
  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  bool get enableNotifications => _enableNotifications;
  bool get automaticDownload => _automaticDownload;
  String get defaultDownloadPath => _defaultDownloadPath;
  int get pdfCacheLimit => _pdfCacheLimit;
  
  // 언어 설정 변경
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _isLoading = true;
    notifyListeners();
    
    _locale = locale;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('언어 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 폰트 크기 설정 변경
  Future<void> setFontSize(double size) async {
    if (_fontSize == size) return;
    
    _isLoading = true;
    notifyListeners();
    
    _fontSize = size;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('폰트 크기 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 알림 설정 변경
  Future<void> setNotifications(bool enable) async {
    if (_enableNotifications == enable) return;
    
    _isLoading = true;
    notifyListeners();
    
    _enableNotifications = enable;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('알림 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 자동 다운로드 설정 변경
  Future<void> setAutomaticDownload(bool enable) async {
    if (_automaticDownload == enable) return;
    
    _isLoading = true;
    notifyListeners();
    
    _automaticDownload = enable;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('자동 다운로드 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 기본 다운로드 경로 설정 변경
  Future<void> setDefaultDownloadPath(String path) async {
    if (_defaultDownloadPath == path) return;
    
    _isLoading = true;
    notifyListeners();
    
    _defaultDownloadPath = path;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('기본 다운로드 경로 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // PDF 캐시 크기 제한 설정 변경
  Future<void> setPdfCacheLimit(int limit) async {
    if (_pdfCacheLimit == limit) return;
    
    _isLoading = true;
    notifyListeners();
    
    _pdfCacheLimit = limit;
    
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('PDF 캐시 크기 제한 설정 저장 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 설정 불러오기
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 언어 설정 불러오기
      final String? languageCode = prefs.getString('languageCode');
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      
      // 폰트 크기 설정 불러오기
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      
      // 알림 설정 불러오기
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      
      // 자동 다운로드 설정 불러오기
      _automaticDownload = prefs.getBool('automaticDownload') ?? false;
      
      // 기본 다운로드 경로 설정 불러오기
      _defaultDownloadPath = prefs.getString('defaultDownloadPath') ?? '';
      
      // PDF 캐시 크기 제한 설정 불러오기
      _pdfCacheLimit = prefs.getInt('pdfCacheLimit') ?? 100;
    } catch (e) {
      debugPrint('설정 불러오기 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 설정 저장하기
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 언어 설정 저장하기
      await prefs.setString('languageCode', _locale.languageCode);
      
      // 폰트 크기 설정 저장하기
      await prefs.setDouble('fontSize', _fontSize);
      
      // 알림 설정 저장하기
      await prefs.setBool('enableNotifications', _enableNotifications);
      
      // 자동 다운로드 설정 저장하기
      await prefs.setBool('automaticDownload', _automaticDownload);
      
      // 기본 다운로드 경로 설정 저장하기
      await prefs.setString('defaultDownloadPath', _defaultDownloadPath);
      
      // PDF 캐시 크기 제한 설정 저장하기
      await prefs.setInt('pdfCacheLimit', _pdfCacheLimit);
    } catch (e) {
      debugPrint('설정 저장 실패: $e');
    }
  }
  
  // 모든 설정 초기화
  Future<void> resetSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _locale = const Locale('ko');
      _fontSize = 16.0;
      _enableNotifications = true;
      _automaticDownload = false;
      _defaultDownloadPath = '';
      _pdfCacheLimit = 100;
      
      await _saveSettings();
    } catch (e) {
      debugPrint('설정 초기화 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 