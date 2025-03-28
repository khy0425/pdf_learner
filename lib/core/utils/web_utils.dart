import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:injectable/injectable.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/conditional_file_picker.dart';
import 'package:get_it/get_it.dart';

/// 웹 환경에서 사용하는 유틸리티 함수들
@singleton
class WebUtils {
  /// 싱글톤 인스턴스 관리
  static final WebUtils _instance = WebUtils._internal();
  factory WebUtils() => _instance;
  
  /// 내부 생성자
  WebUtils._internal();

  /// 웹 환경인지 확인합니다.
  bool get isWeb => kIsWeb;

  /// 웹 윈도우 객체를 반환합니다.
  html.Window get window => html.window;

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

  /// 로컬 스토리지에 데이터를 저장합니다.
  void saveToLocalStorage(String key, String value) {
    if (isWeb) {
      window.localStorage[key] = value;
    }
  }

  /// 로컬 스토리지에서 데이터를 불러옵니다.
  String? loadFromLocalStorage(String key) {
    if (isWeb) {
      return window.localStorage[key];
    }
    return null;
  }

  /// 로컬 스토리지에서 데이터를 삭제합니다.
  void removeFromLocalStorage(String key) {
    if (isWeb) {
      window.localStorage.remove(key);
    }
  }

  /// 로컬 스토리지 클리어
  void clearLocalStorage() {
    if (kIsWeb) {
      html.window.localStorage.clear();
    }
  }

  /// 세션 스토리지에 값을 저장합니다.
  void setSessionItem(String key, String value) {
    if (isWeb) {
      window.sessionStorage[key] = value;
    }
  }

  /// 세션 스토리지에서 값을 가져옵니다.
  String? getSessionItem(String key) {
    if (isWeb) {
      return window.sessionStorage[key];
    }
    return null;
  }

  /// 세션 스토리지에서 항목을 삭제합니다.
  void removeSessionItem(String key) {
    if (isWeb) {
      window.sessionStorage.remove(key);
    }
  }

  /// 세션 스토리지를 비웁니다.
  void clearSession() {
    if (isWeb) {
      window.sessionStorage.clear();
    }
  }

  /// 클립보드에 텍스트 복사
  Future<void> copyToClipboard(String text) async {
    if (isWeb) {
      await window.navigator.clipboard?.writeText(text);
    }
  }

  /// Blob URL 생성
  String createBlobUrl(List<int> bytes, String mimeType) {
    if (!isWeb) return '';
    final blob = html.Blob([bytes], mimeType);
    return html.Url.createObjectUrlFromBlob(blob);
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

  /// 파일을 다운로드합니다.
  void downloadBytes(Uint8List bytes, String fileName) async {
    if (!isWeb) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
    }
  }

  /// 파일을 업로드합니다.
  Future<String?> uploadFile(String accept) async {
    final completer = Completer<String?>();
    final input = html.FileUploadInputElement();
    input.accept = accept;
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoad.listen((event) {
          final result = reader.result;
          if (result is Uint8List) {
            completer.complete(base64Encode(result));
          } else {
            completer.complete(null);
          }
        });

        reader.onError.listen((event) {
          completer.complete(null);
        });
      } else {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  void shareFile(String url) {
    if (!isWeb) {
      // 웹 플랫폼에서만 실행되는 코드는 별도의 파일로 분리
      throw UnimplementedError('웹 플랫폼에서만 사용 가능합니다.');
    }
  }

  bool canShare(String url) {
    if (!isWeb) return false;
    // 웹 플랫폼에서만 실행되는 코드는 별도의 파일로 분리
    return false;
  }

  Future<String?> getSaveLocation() async {
    if (!isWeb) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return null;
  }

  /// GetIt에 싱글톤으로 등록
  static void registerSingleton() {
    if (!GetIt.instance.isRegistered<WebUtils>()) {
      GetIt.instance.registerSingleton<WebUtils>(_instance);
    }
  }
} 