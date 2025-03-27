import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// 웹 HTML 유틸리티 클래스
/// 
/// 웹 환경에서만 사용 가능한 유틸리티 메서드 모음입니다.
class WebHtmlUtils {
  /// 파일 다운로드 기능 (웹 전용)
  static void downloadFile(List<int> bytes, String fileName) {
    if (!kIsWeb) return;
    
    // Blob 생성
    final blob = html.Blob([bytes]);
    
    // URL 생성
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 다운로드 링크 생성
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // 문서에 추가
    html.document.body?.children.add(anchor);
    
    // 다운로드 트리거
    anchor.click();
    
    // 정리
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
  
  /// 브라우저 로컬 스토리지에 데이터 저장
  static void saveToLocalStorage(String key, String value) {
    if (!kIsWeb) return;
    html.window.localStorage[key] = value;
  }
  
  /// 브라우저 로컬 스토리지에서 데이터 로드
  static String? loadFromLocalStorage(String key) {
    if (!kIsWeb) return null;
    return html.window.localStorage[key];
  }
  
  /// 브라우저 로컬 스토리지에서 데이터 삭제
  static void removeFromLocalStorage(String key) {
    if (!kIsWeb) return;
    html.window.localStorage.remove(key);
  }
  
  /// 브라우저 로컬 스토리지 초기화
  static void clearLocalStorage() {
    if (!kIsWeb) return;
    html.window.localStorage.clear();
  }
} 