import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// 웹에서만 dart:html 임포트
import 'dart:html' if (dart.library.io) '../views/web_stub_html.dart' as html;
import 'package:flutter/material.dart';
import 'dart:js_util' if (dart.library.io) '../views/web_stub_js_util.dart' as js_util;
import 'package:pdf_learner_v2/views/web/html_types.dart' as html;
import 'package:js/js.dart';

/// 웹 환경에서 사용하는 유틸리티 함수들
class WebUtils {
  /// 페이지 새로고침
  static void refreshPage() {
    if (kIsWeb) {
      html.window.location.reload();
    }
  }
  
  /// URL 공유 (웹 환경)
  static void shareUrl(String url) {
    if (kIsWeb) {
      try {
        // Navigator.share API 사용 가능 여부 확인
        bool canShareUrl = false;
        try {
          canShareUrl = js_util.callMethod(html.window.navigator, 'canShare', [{'url': url}]) ?? false;
        } catch (e) {
          // canShare 메서드가 없거나 사용할 수 없는 경우
          canShareUrl = false;
        }
        
        if (canShareUrl) {
          // Web Share API 사용
          js_util.callMethod(html.window.navigator, 'share', [{'url': url}]);
        } else {
          // 공유 API를 지원하지 않는 경우 클립보드에 복사
          html.window.navigator.clipboard?.writeText(url);
          // 메시지를 표시하는 코드는 여기에 구현해야 함
        }
      } catch (e) {
        debugPrint('URL 공유 오류: $e');
        // 공유 실패 시 클립보드에 복사
        html.window.navigator.clipboard?.writeText(url);
      }
    }
  }
  
  /// 파일 다운로드 (웹 환경)
  static void downloadFile(String url, String filename) {
    if (!kIsWeb) return;

    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
  }
  
  /// URL에서 PDF 파일 다운로드하여 바이트 배열로 반환
  static Future<Uint8List?> downloadPdfFromUrl(String url) async {
    if (kIsWeb) {
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
  static void downloadPdfToUser(String url, String filename) {
    if (kIsWeb) {
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
  }

  /// 로컬 스토리지에서 데이터 로드
  static dynamic loadFromLocalStorage(String key) {
    if (!kIsWeb) return null;
    return html.window.localStorage[key];
  }

  /// 로컬 스토리지에 데이터 저장
  static void saveToLocalStorage(String key, dynamic data) {
    if (!kIsWeb) return;
    html.window.localStorage[key] = data.toString();
  }

  /// 로컬 스토리지에서 데이터 삭제
  static void removeFromLocalStorage(String key) {
    if (!kIsWeb) return;
    html.window.localStorage.remove(key);
  }

  /// 로컬 스토리지 클리어
  static void clearLocalStorage() {
    if (kIsWeb) {
      html.window.localStorage.clear();
    }
  }

  /// 클립보드에 텍스트 복사
  static void copyToClipboard(String text) {
    if (kIsWeb) {
      html.window.navigator.clipboard?.writeText(text);
    }
  }

  /// 파일 선택 대화상자 열기
  static Future<Map<String, dynamic>?> pickFile(List<String> allowedExtensions) async {
    if (!kIsWeb) return null;

    final completer = Completer<Map<String, dynamic>?>();
    final input = html.FileUploadInputElement()
      ..accept = allowedExtensions.join(',')
      ..multiple = false;

    html.document.body!.children.add(input);
    input.click();
    html.document.body!.children.remove(input);

    final reader = html.FileReader();
    reader.onLoad.listen((event) {
      completer.complete({
        'name': input.files!.first.name,
        'type': input.files!.first.type,
        'size': input.files!.first.size,
        'lastModified': DateTime.fromMillisecondsSinceEpoch(input.files!.first.lastModified.millisecondsSinceEpoch),
        'data': reader.result,
      });
    });

    reader.onError.listen((event) {
      completer.completeError('파일을 읽는 중 오류가 발생했습니다.');
    });

    reader.readAsArrayBuffer(html.Blob([input.files!.first], input.files!.first.type));

    return completer.future;
  }

  /// 여러 파일 선택 대화상자 열기
  static Future<List<Map<String, dynamic>>?> pickMultipleFiles(List<String> allowedExtensions) async {
    if (kIsWeb) {
      try {
        // 파일 입력 요소 생성
        final input = html.FileUploadInputElement();
        input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
        input.multiple = true;
        input.click();

        // 파일 선택 완료 대기
        final completer = Completer<List<Map<String, dynamic>>?>();
        
        input.onChange.listen((event) {
          if (input.files?.isNotEmpty ?? false) {
            final result = <Map<String, dynamic>>[];
            final fileCount = input.files!.length;
            var processedCount = 0;
            
            for (final file in input.files!) {
              // 파일 읽기
              final reader = html.FileReader();
              reader.readAsArrayBuffer(file);
              
              reader.onLoad.listen((event) {
                try {
                  final bytes = (reader.result as dynamic).asUint8List().toList();
                  
                  // Blob URL 생성
                  final blob = html.Blob([bytes], file.type);
                  final blobUrl = html.Url.createObjectUrlFromBlob(blob);
                  
                  result.add({
                    'name': file.name,
                    'size': file.size,
                    'mimeType': file.type,
                    'lastModified': DateTime.fromMillisecondsSinceEpoch(file.lastModified ?? 0),
                    'bytes': bytes,
                    'url': blobUrl,
                  });
                } catch (e) {
                  debugPrint('파일 처리 오류: $e');
                } finally {
                  processedCount++;
                  if (processedCount >= fileCount) {
                    completer.complete(result);
                  }
                }
              });
              
              reader.onError.listen((event) {
                debugPrint('파일 읽기 오류');
                processedCount++;
                if (processedCount >= fileCount) {
                  completer.complete(result);
                }
              });
            }
          } else {
            completer.complete([]);
          }
        });
        
        // 취소 또는 타임아웃 처리
        input.onAbort.listen((event) => completer.complete([]));
        
        return completer.future;
      } catch (e) {
        debugPrint('파일 선택 오류: $e');
      }
    }
    return [];
  }

  /// Blob URL 생성
  static String createBlobUrl(List<int> bytes, String mimeType) {
    if (!kIsWeb) return '';
    final blob = html.Blob(bytes, mimeType);
    return html.Blob.createObjectUrlFromBlob(blob);
  }
  
  /// Base64에서 Blob URL 생성
  static String createBlobUrlFromBase64(String base64Data, String mimeType) {
    if (kIsWeb) {
      try {
        final bytes = base64Decode(base64Data);
        return createBlobUrl(bytes, mimeType);
      } catch (e) {
        debugPrint('Base64 변환 오류: $e');
      }
    }
    return '';
  }
  
  /// URL에서 파일 다운로드
  static Future<void> downloadFileFromUrl(String url, String filename) async {
    if (kIsWeb) {
      try {
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
      } catch (e) {
        debugPrint('파일 다운로드 오류: $e');
      }
    }
  }

  static bool isWeb() {
    return identical(0, 0.0);
  }

  static String createBlobUrl(Uint8List bytes, String mimeType) {
    if (!isWeb()) return '';
    final blob = html.Blob(bytes, mimeType);
    return html.Blob.createObjectUrlFromBlob(blob);
  }

  static void revokeBlobUrl(String url) {
    if (!isWeb()) return;
    // Blob URL 해제는 브라우저가 자동으로 처리
  }

  static bool existsInLocalStorage(String key) {
    if (!isWeb()) return false;
    return html.window.localStorage.containsKey(key);
  }

  static String? loadFromLocalStorage(String key) {
    if (!isWeb()) return null;
    return html.window.localStorage[key];
  }

  static void saveToLocalStorage(String key, String value) {
    if (!isWeb()) return;
    html.window.localStorage[key] = value;
  }

  static void removeFromLocalStorage(String key) {
    if (!isWeb()) return;
    html.window.localStorage.remove(key);
  }

  static Uint8List? loadBytesFromLocalStorage(String key) {
    if (!isWeb()) return null;
    final base64Data = loadFromLocalStorage(key);
    if (base64Data == null) return null;
    return base64Decode(base64Data);
  }

  static void saveBytesToLocalStorage(String key, Uint8List bytes) {
    if (!isWeb()) return;
    final base64Data = base64Encode(bytes);
    saveToLocalStorage(key, base64Data);
  }

  static String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List? base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    if (!isWeb()) return;

    final blob = html.Blob(bytes, 'application/octet-stream');
    final url = html.Blob.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    
    revokeBlobUrl(url);
  }

  static Future<String?> pickFile() async {
    if (!isWeb()) return null;

    final completer = Completer<String?>();
    final input = html.FileUploadInputElement();
    
    input.onChange.listen((event) {
      final files = input.files;
      if (files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        
        reader.onLoad.listen((event) {
          final result = reader.result;
          if (result is String) {
            completer.complete(result);
          } else {
            completer.complete(null);
          }
        });
        
        reader.onError.listen((event) {
          completer.complete(null);
        });
        
        final blob = html.Blob([file], file.type);
        reader.readAsDataUrl(blob);
      } else {
        completer.complete(null);
      }
    });
    
    input.click();
    return completer.future;
  }

  static Future<Uint8List?> pickFileAsBytes() async {
    if (!isWeb()) return null;

    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement();
    
    input.onChange.listen((event) {
      final files = input.files;
      if (files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        
        reader.onLoad.listen((event) {
          final result = reader.result;
          if (result is Uint8List) {
            completer.complete(result);
          } else {
            completer.complete(null);
          }
        });
        
        reader.onError.listen((event) {
          completer.complete(null);
        });
        
        final blob = html.Blob([file], file.type);
        reader.readAsArrayBuffer(blob);
      } else {
        completer.complete(null);
      }
    });
    
    input.click();
    return completer.future;
  }

  static Future<void> saveFile(Uint8List bytes, String fileName, String mimeType) async {
    if (!isWeb()) return;

    final blob = html.Blob(bytes, mimeType);
    final url = html.Blob.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    
    revokeBlobUrl(url);
  }

  static Future<void> downloadFileAsBytes(Uint8List bytes, String fileName) async {
    if (!isWeb()) return;

    final blob = html.Blob(bytes, 'application/octet-stream');
    final url = html.Blob.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }

  static Future<String?> saveFile(Uint8List bytes, String fileName) async {
    if (!isWeb()) return null;

    final blob = html.Blob(bytes, 'application/octet-stream');
    final url = html.Blob.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    return url;
  }

  static Future<String?> saveFileAsBase64(String filePath, String base64Data) async {
    if (!isWeb()) return null;
    saveToLocalStorage('file_$filePath', base64Data);
    return filePath;
  }

  static String? loadFileAsBase64(String filePath) {
    if (!isWeb()) return null;
    return loadFromLocalStorage(filePath) as String?;
  }

  static void deleteFileAsBase64(String filePath) {
    if (!isWeb()) return;
    removeFromLocalStorage(filePath);
  }
} 