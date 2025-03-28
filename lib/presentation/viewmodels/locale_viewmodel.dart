import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/base/base_viewmodel.dart';

/// 로케일 관리 ViewModel
class LocaleViewModel extends BaseViewModel {
  /// 로케일 저장 키
  static const String _localePreferenceKey = 'locale_code';
  
  /// SharedPreferences 인스턴스
  final SharedPreferences _prefs;
  
  /// 현재 로케일
  Locale? _locale;
  
  /// 지원 로케일 목록
  final List<Locale> _supportedLocales = const [
    Locale('ko', ''), // 한국어
    Locale('en', ''), // 영어
    Locale('ja', ''), // 일본어
    Locale('zh', ''), // 중국어
  ];
  
  /// 생성자
  LocaleViewModel({required SharedPreferences sharedPreferences}) : _prefs = sharedPreferences {
    _loadSavedLocale();
  }
  
  /// 현재 로케일 반환
  Locale? get locale => _locale;
  
  /// 지원 로케일 목록 반환
  List<Locale> get supportedLocales => _supportedLocales;
  
  /// 로케일 설정
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    await _prefs.setString(_localePreferenceKey, locale.languageCode);
  }
  
  /// 저장된 로케일 로드
  void _loadSavedLocale() {
    String? localeCode = _prefs.getString(_localePreferenceKey);
    
    if (localeCode != null) {
      _locale = Locale(localeCode, '');
    }
  }
  
  /// 로케일 코드로 로케일 설정
  Future<void> setLocaleByCode(String code) async {
    final locale = Locale(code, '');
    await setLocale(locale);
  }
  
  /// 시스템 로케일 사용 (null로 설정)
  Future<void> useSystemLocale() async {
    _locale = null;
    notifyListeners();
    
    await _prefs.remove(_localePreferenceKey);
  }
  
  /// 한국어 설정
  Future<void> setKorean() async {
    await setLocale(const Locale('ko', ''));
  }
  
  /// 영어 설정
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', ''));
  }
  
  String getLanguageName(Locale locale) {
    final localeKey = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    
    return AppLocalizations.countryNames[localeKey] ?? 'Unknown';
  }
  
  String get currentLanguageName {
    return getLanguageName(_locale ?? const Locale('en', ''));
  }
} 