/// 웹 환경에서 사용할 Platform 스텁 클래스
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'non_web_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'non_web_stub.dart' if (dart.library.js) 'dart:js' as js;

class Platform {
  static const bool isWindows = false;
  static const bool isMacOS = false;
  static const bool isLinux = false;
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static const bool isFuchsia = false;
  static const bool isWeb = true;
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => '';
}

/// 웹에서 사용할 추가 유틸리티 기능
class WebUtils {
  // 로그 중복 방지
  static final Set<String> _loggedMessages = <String>{};

  // 웹 엔진 설정
  static void configureWebEngine() {
    if (!kIsWeb) return;
    
    try {
      if (js.context.hasProperty('flutterWebRenderer')) {
        js.context['flutterWebRenderer'] = 'html';
      }
      log('웹 렌더러를 HTML 모드로 설정했습니다.');
    } catch (e) {
      log('웹 렌더러 설정 오류: $e');
    }
  }
  
  // 로그 출력 (중복 방지)
  static void log(String message) {
    if (kDebugMode) {
      print('[WebUtils] $message');
    }
  }
  
  // 로딩 스플래시 화면 숨기기
  static void hideLoadingScreen() {
    if (!kIsWeb) return;
    
    try {
      // 자바스크립트 함수 호출 대신 직접 DOM 접근 방식 추가
      final loader = html.document.getElementById('flutter-loader');
      if (loader != null) {
        loader.style.display = 'none';
      }
      
      log('스플래시 화면을 숨겼습니다.');
    } catch (e) {
      log('스플래시 화면 숨기기 오류: $e');
    }
  }
  
  // 화면 리사이즈 이벤트 발생
  static void triggerResizeEvent() {
    try {
      html.window.dispatchEvent(html.Event('resize'));
      log('리사이즈 이벤트 발생');
    } catch (e) {
      log('리사이즈 이벤트 발생 오류: $e');
    }
  }
  
  // Flutter 프레임 이벤트 발생
  static void triggerFlutterFrame() {
    try {
      html.window.dispatchEvent(html.Event('flutter-first-frame'));
      log('Flutter 프레임 이벤트 발생');
    } catch (e) {
      log('Flutter 프레임 이벤트 발생 오류: $e');
    }
  }
  
  // 앱 초기화 완료 알림
  static void notifyAppInitialized() {
    try {
      hideLoadingScreen();
      triggerFlutterFrame();
      if (js.context.hasProperty('pdfl')) {
        final pdfl = js.context['pdfl'];
        if (pdfl != null && pdfl.hasProperty('appInitialized')) {
          pdfl.callMethod('appInitialized');
        } else {
          log('앱 초기화 완료 메서드가 정의되지 않음');
        }
      }
      log('앱 초기화 완료 알림 전송됨');
    } catch (e) {
      log('앱 초기화 알림 중 오류 발생: $e');
    }
  }
  
  // JavaScript 메서드 안전하게 호출
  static dynamic callJsMethod(String methodName, [List<dynamic>? args]) {
    try {
      // pdfl 네임스페이스 사용
      if (methodName.startsWith('pdfl.')) {
        String actualMethod = methodName.substring(5);
        if (js.context.hasProperty('pdfl')) {
          final pdfl = js.context['pdfl'];
          if (pdfl != null && pdfl.hasProperty(actualMethod)) {
            log('JavaScript 메서드 호출: $methodName');
            return pdfl.callMethod(actualMethod, args ?? []);
          } else {
            log('JavaScript 메서드가 pdfl 네임스페이스에 없음: $actualMethod');
          }
        } else {
          log('pdfl 네임스페이스가 정의되지 않음');
        }
      } else if (js.context.hasProperty(methodName)) {
        final method = js.context[methodName];
        if (method != null) {
          log('JavaScript 메서드 호출: $methodName');
          return js.context.callMethod(methodName, args ?? []);
        } else {
          log('JavaScript 메서드가 null: $methodName');
        }
      } else {
        log('JavaScript 메서드를 찾을 수 없음: $methodName');
      }
    } catch (e) {
      log('JavaScript 메서드 호출 오류: $methodName - $e');
    }
    return null;
  }
  
  // 사용자 정보 안전하게 가져오기
  static Map<String, dynamic> getCurrentUser() {
    // 기본 사용자 정보 객체
    final defaultUser = {
      'uid': '',
      'email': '',
      'displayName': '',
      'isAnonymous': true
    };
    
    try {
      // DOM 직접 접근 시도
      if (js.context.hasProperty('pdfl')) {
        final pdfl = js.context['pdfl'];
        if (pdfl != null && pdfl.hasProperty('getCurrentFirebaseUser')) {
          final jsResult = pdfl.callMethod('getCurrentFirebaseUser');
          if (jsResult != null) {
            final Map<String, dynamic> user = {
              'uid': jsResult['uid'] ?? '',
              'email': jsResult['email'] ?? '',
              'displayName': jsResult['displayName'] ?? '',
              'isAnonymous': jsResult['isAnonymous'] ?? true
            };
            log('사용자 정보 가져오기 성공: ${user['email']}');
            return user;
          }
        }
      }
    } catch (e) {
      log('현재 사용자 정보 가져오기 오류: $e');
    }
    
    // 항상 기본 사용자 정보 반환
    return defaultUser;
  }
  
  // 저장된 사용자 정보 가져오기
  static Map<String, dynamic> getStoredUserInfo() {
    // 기본 사용자 정보 객체
    final defaultUser = {
      'uid': '',
      'email': '',
      'displayName': '',
      'isAnonymous': true
    };
    
    try {
      // 로컬 스토리지 직접 접근 시도
      final userInfoStr = html.window.localStorage['user_info'];
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        try {
          final dynamic jsonData = json.decode(userInfoStr);
          if (jsonData is Map) {
            final Map<String, dynamic> user = {
              'uid': jsonData['uid'] ?? '',
              'email': jsonData['email'] ?? '',
              'displayName': jsonData['displayName'] ?? '',
              'isAnonymous': jsonData['isAnonymous'] ?? true
            };
            log('로컬 스토리지에서 사용자 정보 가져오기 성공');
            return user;
          }
        } catch (e) {
          log('저장된 사용자 정보 파싱 오류: $e');
        }
      }
      
      // JS 메서드 호출 시도
      if (js.context.hasProperty('pdfl')) {
        final pdfl = js.context['pdfl'];
        if (pdfl != null && pdfl.hasProperty('getStoredUserInfo')) {
          final jsResult = pdfl.callMethod('getStoredUserInfo');
          if (jsResult != null) {
            final Map<String, dynamic> user = {
              'uid': jsResult['uid'] ?? '',
              'email': jsResult['email'] ?? '',
              'displayName': jsResult['displayName'] ?? '',
              'isAnonymous': jsResult['isAnonymous'] ?? true
            };
            log('JS를 통한 저장된 사용자 정보 가져오기 성공');
            return user;
          }
        }
      }
    } catch (e) {
      log('저장된 사용자 정보 가져오기 오류: $e');
    }
    
    // 항상 기본 사용자 정보 반환
    return defaultUser;
  }
  
  // 페이지 상태 초기화 (문제 발생 시)
  static void resetPage() {
    try {
      html.window.location.reload();
    } catch (e) {
      log('페이지 리로드 오류: $e');
    }
  }
  
  // 모든 DOM 이벤트 연결 강제 시도
  static void forceConnectListeners() {
    try {
      hideLoadingScreen();
      triggerResizeEvent();
      triggerFlutterFrame();
      log('이벤트 리스너 강제 연결 시도');
    } catch (e) {
      log('이벤트 리스너 강제 연결 오류: $e');
    }
  }
  
  // 웹 표시 상태 디버깅
  static String debugWebDisplayStatus() {
    try {
      final flutterTarget = html.document.getElementById('flutter_target');
      if (flutterTarget == null) {
        log('Flutter 타겟 요소가 없습니다.');
        return 'Flutter 타겟 요소가 없습니다.';
      }
      
      final status = StringBuffer();
      status.writeln('Flutter UI 상태:');
      status.writeln('- 자식 요소 수: ${flutterTarget.children.length}');
      status.writeln('- 표시 상태: ${flutterTarget.style.display}');
      status.writeln('- 가시성: ${flutterTarget.style.visibility}');
      
      // 상태를 로그로 출력
      log(status.toString());
      return status.toString();
    } catch (e) {
      log('웹 표시 상태 디버깅 오류: $e');
      return '오류: $e';
    }
  }
  
  // 간단한 체크 캔버스 함수
  static void checkCanvasElements() {
    final flutterTarget = html.document.getElementById('flutter_target');
    if (flutterTarget == null) {
      log('Flutter 타겟 요소가 없습니다.');
      return;
    }
    
    log('Flutter 타겟 자식 요소 수: ${flutterTarget.children.length}');
  }

  // 웹 렌더링 디버깅 함수
  static void logWebStateDebug() {
    try {
      // DOM 상태 확인
      final bodyElement = html.document.body;
      final flutterElement = html.document.getElementById('flutter_target');
      final loadingElement = html.document.getElementById('loading');
      
      // 요소들의 상태 로깅
      log('===== 웹 디버그 정보 =====');
      log('Body 존재: ${bodyElement != null}');
      log('Flutter 요소 존재: ${flutterElement != null}');
      log('Flutter 요소 표시 상태: ${flutterElement?.style.display}');
      log('Flutter 요소 자식 수: ${flutterElement?.children.length ?? 0}');
      log('로딩 요소 존재: ${loadingElement != null}');
      log('로딩 요소 표시 상태: ${loadingElement?.style.display}');
      
      // CSS 디버깅
      if (flutterElement != null) {
        log('Flutter 요소 스타일:');
        log(' - z-index: ${flutterElement.style.zIndex}');
        log(' - 위치: ${flutterElement.style.position}');
        log(' - visibility: ${flutterElement.style.visibility}');
        log(' - opacity: ${flutterElement.style.opacity}');
        
        // 크기 확인
        log(' - 너비: ${flutterElement.clientWidth}px');
        log(' - 높이: ${flutterElement.clientHeight}px');
      }
      
      // 핫픽스 적용 - 강제로 스타일 수정 시도
      if (flutterElement != null) {
        flutterElement.style.position = 'absolute';
        flutterElement.style.top = '0';
        flutterElement.style.left = '0';
        flutterElement.style.width = '100%';
        flutterElement.style.height = '100%';
        flutterElement.style.zIndex = '2';
        flutterElement.style.visibility = 'visible';
        flutterElement.style.opacity = '1';
        flutterElement.style.backgroundColor = 'white';
        flutterElement.style.display = 'block';
        log('Flutter 요소 스타일 핫픽스 적용됨');
        
        // 자식 요소 찾기
        if (flutterElement.children.isEmpty) {
          log('Flutter 요소에 자식 없음 - 엔진 초기화 문제 가능성');
          
          try {
            // 엔진 상태 확인 및 강제 재설정 시도 - 직접 main.dart.js 로드 방식으로 변경
            log('Flutter 엔진 재시작 시도 - 직접 main.dart.js 로드');
            
            // JavaScript를 통해 스크립트 요소 생성 및 추가
            js.context.callMethod('eval', [
              """
              (function() {
                var script = document.createElement('script');
                script.src = 'main.dart.js';
                script.type = 'application/javascript';
                document.body.appendChild(script);
                console.log('main.dart.js 스크립트 직접 추가 완료');
              })();
              """
            ]);
            
            log('main.dart.js 스크립트 직접 추가 완료');
          } catch (e) {
            log('Flutter 엔진 재시작 시도 실패: $e');
          }
        }
      }
      
      log('===== 디버그 정보 종료 =====');
    } catch (e) {
      log('웹 상태 디버깅 중 오류: $e');
    }
  }
}

// Window 객체와 관련된 편의 기능
class Window {
  // 현재 URL 가져오기
  static String getCurrentUrl() {
    try {
      return html.window.location.href;
    } catch (e) {
      debugPrint('현재 URL 가져오기 오류: $e');
      return '';
    }
  }
  
  // URL 변경하기
  static void navigateTo(String url) {
    try {
      html.window.location.href = url;
    } catch (e) {
      debugPrint('URL 이동 오류: $e');
    }
  }
  
  // 브라우저 히스토리 뒤로가기
  static void goBack() {
    try {
      html.window.history.back();
    } catch (e) {
      debugPrint('뒤로가기 오류: $e');
    }
  }
  
  // 로컬 스토리지에 데이터 저장
  static void setLocalStorage(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      debugPrint('로컬 스토리지 저장 오류: $e');
    }
  }
  
  // 로컬 스토리지에서 데이터 가져오기
  static String? getLocalStorage(String key) {
    try {
      return html.window.localStorage[key];
    } catch (e) {
      debugPrint('로컬 스토리지 가져오기 오류: $e');
      return null;
    }
  }
  
  // 로컬 스토리지에서 데이터 삭제
  static void removeLocalStorage(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      debugPrint('로컬 스토리지 삭제 오류: $e');
    }
  }
} 