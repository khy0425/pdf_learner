/// dart:html을 대체하기 위한 비웹 환경 스텁 클래스

/// HTML 스텁 구현 - 웹이 아닌 환경에서 사용됨
class Window {
  /// localStorage 스텁
  final LocalStorage localStorage = LocalStorage();
}

/// localStorage 스텁 클래스
class LocalStorage {
  final Map<String, String> _storage = {};

  /// 키-값 쌍으로 localStorage 접근
  String? operator [](String key) => _storage[key];

  /// 키-값 쌍으로 localStorage 설정
  void operator []=(String key, String value) {
    _storage[key] = value;
  }

  /// localStorage에서 항목 제거
  void remove(String key) {
    _storage.remove(key);
  }

  /// localStorage 비우기
  void clear() {
    _storage.clear();
  }

  /// localStorage 각 항목에 대해 콜백 실행
  void forEach(void Function(String key, String value) callback) {
    _storage.forEach(callback);
  }
}

/// 전역 window 객체 스텁
final Window window = Window();

import 'package:flutter/foundation.dart';

/// 웹 HTML 유틸리티 스텁 클래스
/// 
/// 웹이 아닌 환경에서 사용할 스텁 구현입니다.
class WebHtmlUtils {
  /// 파일 다운로드 기능 (스텁)
  static void downloadFile(List<int> bytes, String fileName) {
    // 웹이 아닌 환경에서는 사용 불가
    throw UnsupportedError('downloadFile은 웹 환경에서만 지원됩니다.');
  }
  
  /// 브라우저 로컬 스토리지에 데이터 저장 (스텁)
  static void saveToLocalStorage(String key, String value) {
    // 웹이 아닌 환경에서는 동작하지 않음
    if (kDebugMode) {
      print('saveToLocalStorage는 웹 환경에서만 지원됩니다.');
    }
  }
  
  /// 브라우저 로컬 스토리지에서 데이터 로드 (스텁)
  static String? loadFromLocalStorage(String key) {
    // 웹이 아닌 환경에서는 null 반환
    return null;
  }
  
  /// 브라우저 로컬 스토리지에서 데이터 삭제 (스텁)
  static void removeFromLocalStorage(String key) {
    // 웹이 아닌 환경에서는 동작하지 않음
    if (kDebugMode) {
      print('removeFromLocalStorage는 웹 환경에서만 지원됩니다.');
    }
  }
  
  /// 브라우저 로컬 스토리지 초기화 (스텁)
  static void clearLocalStorage() {
    // 웹이 아닌 환경에서는 동작하지 않음
    if (kDebugMode) {
      print('clearLocalStorage는 웹 환경에서만 지원됩니다.');
    }
  }
} 