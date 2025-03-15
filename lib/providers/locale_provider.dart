import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  // 지원되는 언어 목록
  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'),  // 한국어
    Locale('en', 'US'),  // 영어
  ];
  
  // 현재 로케일
  Locale _locale = const Locale('ko', 'KR');  // 기본값은 한국어
  
  // Getter
  Locale get locale => _locale;
  
  // 생성자
  LocaleProvider() {
    _loadSavedLocale();
  }
  
  // 저장된 로케일 불러오기
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code');
      final countryCode = prefs.getString('country_code');
      
      if (languageCode != null) {
        _locale = Locale(languageCode, countryCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('로케일 로드 오류: $e');
    }
  }
  
  // 로케일 변경
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;
    
    _locale = locale;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');
    } catch (e) {
      debugPrint('로케일 저장 오류: $e');
    }
    
    notifyListeners();
  }
  
  // 영어로 변경
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }
  
  // 한국어로 변경
  Future<void> setKorean() async {
    await setLocale(const Locale('ko', 'KR'));
  }
  
  // 시스템 언어 설정으로 변경
  Future<void> setSystemLocale(BuildContext context) async {
    final systemLocale = Localizations.localeOf(context);
    
    // 지원되는 언어인지 확인
    if (_isSupported(systemLocale)) {
      await setLocale(systemLocale);
    } else {
      // 지원되지 않는 언어일 경우 기본값(한국어)으로 설정
      await setLocale(const Locale('ko', 'KR'));
    }
  }
  
  // 로케일이 지원되는지 확인
  bool _isSupported(Locale locale) {
    return supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }
} 