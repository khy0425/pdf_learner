import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// 웹 환경에서 사용하는 유틸리티 기능을 제공하는 클래스
class WebUtils {
  static final WebUtils _instance = WebUtils._internal();
  
  factory WebUtils() => _instance;
  
  WebUtils._internal();
  
  /// 브라우저에서 지원하는지 여부 확인
  bool get isWebSupported => kIsWeb;
  
  /// 현재 브라우저 정보를 가져옴
  String get browserInfo => html.window.navigator.userAgent;
  
  /// PWA로 설치되었는지 확인
  bool get isInstalledPWA {
    return js.context.hasProperty('matchMedia') &&
           js.context.callMethod('matchMedia', ['(display-mode: standalone)'])
                      .callMethod('matches');
  }
  
  /// 파일 다운로드 기능 
  void downloadFile(String content, String fileName, {String mimeType = 'text/plain'}) {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
      
    html.document.body?.children.add(anchor);
    anchor.click();
    
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
  
  /// 파일 선택 대화상자 열기
  void pickFile(List<String> acceptedTypes, Function(List<html.File>) onFilesPicked) {
    final input = html.FileUploadInputElement()
      ..accept = acceptedTypes.map((type) => '.$type').join(',')
      ..multiple = false
      ..click();
      
    input.onChange.listen((event) {
      if (input.files?.isNotEmpty ?? false) {
        onFilesPicked(input.files!);
      }
    });
  }
  
  /// 클립보드에 텍스트 복사
  Future<bool> copyToClipboard(String text) async {
    try {
      await html.window.navigator.clipboard?.writeText(text);
      return true;
    } catch (e) {
      debugPrint('웹 클립보드 복사 오류: $e');
      
      // 폴백 메커니즘: textarea를 사용하여 복사
      try {
        final textarea = html.TextAreaElement()
          ..value = text
          ..style.position = 'fixed'
          ..style.left = '-9999px'
          ..style.opacity = '0';
          
        html.document.body?.append(textarea);
        textarea.select();
        
        final result = html.document.execCommand('copy');
        textarea.remove();
        
        return result;
      } catch (e) {
        debugPrint('폴백 클립보드 복사 오류: $e');
        return false;
      }
    }
  }
  
  /// 웹 공유 API 사용 (지원하는 브라우저에서만)
  Future<bool> shareContent(String title, String text, String? url) async {
    if (js.context.hasProperty('navigator') && js.context['navigator'].hasProperty('share')) {
      try {
        final shareData = <String, dynamic>{
          'title': title,
          'text': text,
        };
        
        if (url != null) {
          shareData['url'] = url;
        }
        
        await js.context['navigator'].callMethod('share', [js.JsObject.jsify(shareData)]);
        return true;
      } catch (e) {
        debugPrint('웹 공유 API 오류: $e');
        return false;
      }
    }
    return false;
  }
  
  /// 로컬 스토리지에 데이터 저장
  void saveToLocalStorage(String key, String value) {
    html.window.localStorage[key] = value;
  }
  
  /// 로컬 스토리지에서 데이터 로드
  String? loadFromLocalStorage(String key) {
    return html.window.localStorage[key];
  }
  
  /// 로컬 스토리지에서 데이터 삭제
  void removeFromLocalStorage(String key) {
    html.window.localStorage.remove(key);
  }
  
  /// 웹 알림 권한 요청 및 알림 표시
  Future<bool> requestNotificationPermission() async {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    }
    return false;
  }
  
  /// 웹 알림 표시
  void showNotification(String title, String body, {String? icon}) {
    if (html.Notification.supported && html.Notification.permission == 'granted') {
      html.Notification(title, body: body, icon: icon);
      return;
    }
    debugPrint('웹 알림이 지원되지 않거나 권한이 없습니다.');
  }
  
  /// 화면이 모바일 크기인지 확인
  bool get isMobileScreen {
    final width = html.window.innerWidth ?? 0;
    return width < 768;
  }
  
  /// 현재 URL 가져오기
  String get currentUrl => html.window.location.href;
  
  /// 페이지 새로고침
  void refreshPage() {
    html.window.location.reload();
  }
  
  /// IndexedDB 데이터베이스 열기 (간단한 래퍼)
  Future<html.IdbDatabase> openDatabase(String name, int version) async {
    final completer = Completer<html.IdbDatabase>();
    final request = html.window.indexedDB?.open(name, version);
    
    request?.onUpgradeNeeded.listen((event) {
      final db = request.result as html.IdbDatabase;
      // DB 업그레이드 코드는 호출자가 처리해야 함
      completer.complete(db);
    });
    
    request?.onSuccess.listen((event) {
      final db = request.result as html.IdbDatabase;
      completer.complete(db);
    });
    
    request?.onError.listen((event) {
      completer.completeError('IndexedDB 열기 오류: ${request.error}');
    });
    
    return completer.future;
  }
} 