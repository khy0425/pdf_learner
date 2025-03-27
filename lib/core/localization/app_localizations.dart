import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 앱 내 다국어 지원을 위한 로컬라이제이션 클래스
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  // 정적 대리자 인스턴스
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // 로컬라이제이션 대리자 목록
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  
  // 지원하는 로케일 목록
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // 영어 (기본)
    Locale('ko', 'KR'), // 한국어
    Locale('ja', 'JP'), // 일본어
    Locale('zh', 'CN'), // 중국어 (간체)
    Locale('es', ''), // 스페인어
    Locale('fr', ''), // 프랑스어
    Locale('de', ''), // 독일어
  ];
  
  // 로컬라이제이션 대리자
  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();
  
  // 국가 이름 맵
  static const Map<String, String> countryNames = {
    'en': 'English',
    'ko_KR': '한국어',
    'ja_JP': '日本語',
    'zh_CN': '中文',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };
  
  // 언어와 국가 코드로 로케일 키 생성
  static String _getLocaleKey(Locale locale) {
    return locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
  }
  
  // 번역 맵
  late Map<String, String> _localizedStrings;
  
  // JSON 파일에서 현재 로케일에 해당하는 문자열 로드
  Future<bool> load() async {
    final localeKey = _getLocaleKey(locale);
    
    // 번역 파일 로드
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/lang/$localeKey.json');
    } catch (e) {
      // 해당 로케일 파일이 없으면 영어 기본값 사용
      jsonString = await rootBundle.loadString('assets/lang/en.json');
    }
    
    // JSON 파싱
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    
    // 문자열 맵으로 변환
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    
    return true;
  }
  
  // 번역된 문자열 조회
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
  
  // 현재 국가 이름 조회
  String get currentLanguageName {
    final localeKey = _getLocaleKey(locale);
    return countryNames[localeKey] ?? 'English';
  }
}

// 로컬라이제이션 대리자
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    // 지원하는 언어 확인
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    // 로컬라이제이션 객체 생성
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }
  
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 