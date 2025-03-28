import '../utils/web_stub.dart';

/// 웹 스토리지 유틸리티 클래스
/// 로컬 스토리지와 세션 스토리지에 접근하는 메서드를 제공합니다.
class WebStorageUtils {
  /// 싱글톤 인스턴스
  static final WebStorageUtils _instance = WebStorageUtils._internal();
  
  /// 내부 생성자
  WebStorageUtils._internal();
  
  /// 인스턴스 getter
  static WebStorageUtils get instance => _instance;

  /// 로컬 스토리지에 값을 저장합니다.
  void setItem(String key, String value) {
    window.localStorage[key] = value;
  }

  /// 로컬 스토리지에서 값을 가져옵니다.
  String? getItem(String key) {
    return window.localStorage[key];
  }

  /// 로컬 스토리지에서 항목을 삭제합니다.
  void removeItem(String key) {
    window.localStorage.remove(key);
  }

  /// 로컬 스토리지를 비웁니다.
  void clear() {
    window.localStorage.clear();
  }

  /// 세션 스토리지에 값을 저장합니다.
  void setSessionItem(String key, String value) {
    window.sessionStorage[key] = value;
  }

  /// 세션 스토리지에서 값을 가져옵니다.
  String? getSessionItem(String key) {
    return window.sessionStorage[key];
  }

  /// 세션 스토리지에서 항목을 삭제합니다.
  void removeSessionItem(String key) {
    window.sessionStorage.remove(key);
  }

  /// 세션 스토리지를 비웁니다.
  void clearSession() {
    window.sessionStorage.clear();
  }
} 