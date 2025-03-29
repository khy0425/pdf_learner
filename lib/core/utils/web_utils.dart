import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/web_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

/// 웹 환경에서 사용하는 유틸리티 함수들
@singleton
class WebUtils {
  /// 싱글톤 인스턴스 관리
  static final WebUtils _instance = WebUtils._internal();
  
  /// 웹 스토리지 만료 기간 (일)
  static const int _expirationDays = 7;

  /// 인스턴스 getter
  static WebUtils get instance => _instance;
  
  factory WebUtils() => _instance;
  
  /// 싱글톤 등록
  static void registerSingleton() {
    if (!GetIt.instance.isRegistered<WebUtils>()) {
      GetIt.instance.registerSingleton<WebUtils>(_instance);
    }
  }
  
  /// 내부 생성자
  WebUtils._internal();

  /// 웹 환경인지 확인합니다.
  bool get isWeb => kIsWeb;

  /// 웹 윈도우 객체를 반환합니다.
  dynamic get window => kIsWeb ? html.window : null;

  /// 페이지 새로고침
  Future<void> reloadPage() async {
    if (isWeb) {
      window.location.reload();
    }
  }
  
  /// URL 공유 (웹 환경)
  Future<bool> shareUrl(String url) async {
    if (!isWeb) {
      return false;
    }
    
    try {
      if (window.navigator.share != null) {
        await window.navigator.share({
          'url': url,
        });
        return true;
      }
    } catch (e) {
      debugPrint('URL 공유 오류: $e');
    }
    return false;
  }
  
  /// 파일 다운로드 (웹 환경)
  void downloadFile(String url, String filename) {
    if (!isWeb) return;
    
    // <a> 요소 생성
    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename
      ..target = '_blank'
      ..style.display = 'none';
    
    // 문서에 추가하고 클릭
    html.document.body!.children.add(anchor);
    anchor.click();
    
    // 문서에서 제거
    anchor.remove();
  }
  
  /// URL에서 PDF 파일 다운로드하여 바이트 배열로 반환
  Future<Uint8List?> downloadPdfFromUrl(String url) async {
    if (isWeb) {
      try {
        // HTTP 요청으로 PDF 다운로드
        final request = await html.HttpRequest.request(
          url,
          method: 'GET',
          responseType: 'arraybuffer',
        );
        
        if (request.status == 200) {
          // ArrayBuffer를 Uint8List로 변환
          final buffer = (request.response as dynamic).asUint8List();
          return buffer;
        }
      } catch (e) {
        debugPrint('PDF 다운로드 오류: $e');
      }
    }
    return null;
  }
  
  /// PDF 파일 사용자 다운로드
  void downloadPdfToUser(String url, String filename) {
    if (isWeb) {
      downloadFile(url, filename);
    }
  }

  /// 로컬 스토리지에 데이터를 저장합니다 (base64 인코딩)
  void saveToLocalStorage(String key, String value) {
    if (isWeb) {
      try {
        // 만료 정보와 함께 저장
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final data = {
          'value': value,
          'timestamp': timestamp,
          'expiration': timestamp + (_expirationDays * 24 * 60 * 60 * 1000),
        };
        
        window.localStorage[key] = jsonEncode(data);
        debugPrint('로컬 스토리지 저장: $key');
      } catch (e) {
        debugPrint('로컬 스토리지 저장 오류: $e');
      }
    }
  }

  /// 로컬 스토리지에서 데이터를 불러옵니다.
  String? loadFromLocalStorage(String key) {
    if (isWeb) {
      try {
        final storedData = window.localStorage[key];
        if (storedData == null) return null;
        
        final data = jsonDecode(storedData);
        final expiration = data['expiration'] as int;
        
        // 만료 확인
        if (DateTime.now().millisecondsSinceEpoch > expiration) {
          removeFromLocalStorage(key);
          return null;
        }
        
        return data['value'] as String;
      } catch (e) {
        debugPrint('로컬 스토리지 불러오기 오류: $e');
      }
    }
    return null;
  }

  /// 로컬 스토리지에서 데이터를 삭제합니다.
  void removeFromLocalStorage(String key) {
    if (isWeb) {
      try {
        window.localStorage.remove(key);
        debugPrint('로컬 스토리지 항목 삭제: $key');
      } catch (e) {
        debugPrint('로컬 스토리지 항목 삭제 오류: $e');
      }
    }
  }
  
  /// 바이트 데이터를 IndexedDB에 저장합니다.
  Future<void> saveBytesToIndexedDB(String id, Uint8List bytes) async {
    if (isWeb) {
      try {
        // Base64로 인코딩하여 로컬 스토리지에 저장
        final base64String = base64Encode(bytes);
        
        // 만료 정보 추가
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final data = {
          'data': base64String,
          'size': bytes.length,
          'timestamp': timestamp,
          'expiration': timestamp + (_expirationDays * 24 * 60 * 60 * 1000),
        };
        
        // 로컬 스토리지에 저장
        window.localStorage['pdf_$id'] = jsonEncode(data);
        debugPrint('PDF 데이터 저장됨: $id (${bytes.length} 바이트)');
      } catch (e) {
        debugPrint('IndexedDB 저장 오류: $e');
      }
    }
  }
  
  /// IndexedDB에서 바이트 데이터를 가져옵니다.
  Future<Uint8List?> getBytesFromIndexedDB(String id) async {
    if (isWeb) {
      try {
        final storedData = window.localStorage['pdf_$id'];
        if (storedData == null) return null;
        
        final data = jsonDecode(storedData);
        final expiration = data['expiration'] as int;
        
        // 만료 확인
        if (DateTime.now().millisecondsSinceEpoch > expiration) {
          // 만료된 항목 삭제
          window.localStorage.remove('pdf_$id');
          return null;
        }
        
        // Base64 디코딩
        final base64String = data['data'] as String;
        return base64Decode(base64String);
      } catch (e) {
        debugPrint('IndexedDB 조회 오류: $e');
      }
    }
    return null;
  }
  
  /// 만료된 파일을 정리합니다.
  void cleanupExpiredFiles() {
    if (isWeb) {
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        final keysToRemove = <String>[];
        
        // 모든 PDF 데이터 항목 확인
        for (var i = 0; i < window.localStorage.length; i++) {
          final key = window.localStorage.key(i);
          if (key.startsWith('pdf_')) {
            try {
              final storedData = window.localStorage[key];
              if (storedData != null) {
                final data = jsonDecode(storedData);
                final expiration = data['expiration'] as int;
                
                if (now > expiration) {
                  keysToRemove.add(key);
                }
              }
            } catch (e) {
              // 오류가 발생한 항목도 삭제 대상에 추가
              keysToRemove.add(key);
            }
          }
        }
        
        // 만료된 항목 삭제
        for (final key in keysToRemove) {
          window.localStorage.remove(key);
          debugPrint('만료된 항목 삭제: $key');
        }
        
        if (keysToRemove.isNotEmpty) {
          debugPrint('${keysToRemove.length}개의 만료된 파일 정리 완료');
        }
      } catch (e) {
        debugPrint('만료 파일 정리 중 오류: $e');
      }
    }
  }
  
  /// PDF 파일의 만료까지 남은 일수를 계산합니다.
  int getRemainingDaysForPdf(String id) {
    if (!isWeb) return 0;
    
    try {
      final storedData = window.localStorage['pdf_$id'];
      if (storedData == null) return 0;
      
      final data = jsonDecode(storedData);
      final expiration = data['expiration'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 이미 만료된 경우
      if (now > expiration) return 0;
      
      // 남은 시간 계산 (밀리초 -> 일)
      return ((expiration - now) / (24 * 60 * 60 * 1000)).floor();
    } catch (e) {
      debugPrint('만료일 계산 오류: $e');
      return 0;
    }
  }
  
  /// PDF 파일이 만료되었는지 확인합니다.
  bool isExpired(String id) {
    return getRemainingDaysForPdf(id) <= 0;
  }

  /// 로컬 스토리지에 데이터를 저장합니다.
  void setItem(String key, String value) {
    if (isWeb) {
      try {
        window.localStorage[key] = value;
        debugPrint('로컬 스토리지 저장: $key');
      } catch (e) {
        debugPrint('로컬 스토리지 저장 오류: $e');
      }
    }
  }

  /// 로컬 스토리지에서 데이터를 불러옵니다.
  String? getItem(String key) {
    if (isWeb) {
      try {
        final value = window.localStorage[key];
        return value;
      } catch (e) {
        debugPrint('로컬 스토리지 불러오기 오류: $e');
      }
    }
    return null;
  }

  /// 로컬 스토리지에서 데이터를 삭제합니다.
  void removeItem(String key) {
    if (isWeb) {
      try {
        window.localStorage.remove(key);
        debugPrint('로컬 스토리지 항목 삭제: $key');
      } catch (e) {
        debugPrint('로컬 스토리지 항목 삭제 오류: $e');
      }
    }
  }

  /// 로컬 스토리지 클리어
  void clear() {
    if (kIsWeb) {
      try {
        window.localStorage.clear();
        debugPrint('로컬 스토리지 초기화');
      } catch (e) {
        debugPrint('로컬 스토리지 초기화 오류: $e');
      }
    }
  }

  /// 세션 스토리지에 값을 저장합니다.
  void setSessionItem(String key, String value) {
    if (isWeb) {
      try {
        window.sessionStorage[key] = value;
      } catch (e) {
        debugPrint('세션 스토리지 저장 오류: $e');
      }
    }
  }

  /// 세션 스토리지에서 값을 가져옵니다.
  String? getSessionItem(String key) {
    if (isWeb) {
      try {
        return window.sessionStorage[key];
      } catch (e) {
        debugPrint('세션 스토리지 불러오기 오류: $e');
      }
    }
    return null;
  }

  /// 세션 스토리지에서 항목을 삭제합니다.
  void removeSessionItem(String key) {
    if (isWeb) {
      try {
        window.sessionStorage.remove(key);
      } catch (e) {
        debugPrint('세션 스토리지 항목 삭제 오류: $e');
      }
    }
  }

  /// 세션 스토리지를 비웁니다.
  void clearSession() {
    if (isWeb) {
      try {
        window.sessionStorage.clear();
      } catch (e) {
        debugPrint('세션 스토리지 초기화 오류: $e');
      }
    }
  }

  /// 클립보드에 텍스트 복사
  Future<void> copyToClipboard(String text) async {
    if (isWeb) {
      try {
        await window.navigator.clipboard?.writeText(text);
        debugPrint('클립보드에 복사: $text');
      } catch (e) {
        debugPrint('클립보드 복사 오류: $e');
      }
    }
  }

  /// Blob URL 생성
  String createBlobUrl(List<int> bytes, String mimeType) {
    if (!isWeb) return '';
    try {
      final blob = html.Blob([bytes], mimeType);
      return html.Url.createObjectUrlFromBlob(blob);
    } catch (e) {
      debugPrint('Blob URL 생성 오류: $e');
      return '';
    }
  }
  
  /// Base64에서 Blob URL 생성
  String createBlobUrlFromBase64(String base64Data, String mimeType) {
    if (isWeb) {
      try {
        final bytes = base64Decode(base64Data);
        return createBlobUrl(bytes, mimeType);
      } catch (e) {
        debugPrint('Base64 변환 오류: $e');
      }
    }
    return '';
  }

  /// 바이트 배열을 Base64 문자열로 변환합니다.
  String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }
  
  /// Base64 문자열을 바이트 배열로 변환합니다.
  Uint8List base64ToBytes(String base64) {
    return base64Decode(base64);
  }
}