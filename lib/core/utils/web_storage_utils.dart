import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// 웹 플랫폼에서만 실제 html 패키지를 가져오고, 그 외 플랫폼에서는 스텁 구현을 사용
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_html.dart' if (dart.library.io) 'web_html_stub.dart' as html;

/// 웹 저장소 유틸리티 클래스
/// localStorage 접근을 위한 유틸리티 함수 제공
class WebStorageUtils {
  static final WebStorageUtils _instance = WebStorageUtils._internal();
  
  factory WebStorageUtils() => _instance;
  
  WebStorageUtils._internal();
  
  /// 미회원 PDF 만료 기간 (일) - 7일
  static const int _guestDataExpirationDays = 7;
  
  /// 로컬 스토리지에 데이터 저장
  static void setItem(String key, String value) {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
    }
  }
  
  /// 로컬 스토리지에서 데이터 가져오기
  static String? getItem(String key) {
    if (kIsWeb) {
      return html.window.localStorage[key];
    }
    return null;
  }
  
  /// 로컬 스토리지에서 항목 제거
  static void removeItem(String key) {
    if (kIsWeb) {
      html.window.localStorage.remove(key);
    }
  }
  
  /// 로컬 스토리지 비우기
  static void clear() {
    if (kIsWeb) {
      html.window.localStorage.clear();
    }
  }
  
  /// PDF(바이트 배열) 데이터 저장
  static Future<bool> savePdfData(String fileId, Uint8List bytes, {bool isGuest = false}) async {
    if (!kIsWeb) return false;
    
    try {
      // 메타데이터 저장
      final metadata = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isGuest': isGuest,
        'expirationDays': isGuest ? _guestDataExpirationDays : 0,
        'fileSize': bytes.length,
      };
      
      // 메타데이터 저장
      setItem('pdf_${fileId}_metadata', json.encode(metadata));
      
      // PDF 데이터를 base64로 인코딩하여 저장
      final base64Data = base64Encode(bytes);
      setItem('pdf_$fileId', base64Data);
      
      return true;
    } catch (e) {
      debugPrint('PDF 데이터 저장 중 오류: $e');
      return false;
    }
  }
  
  /// PDF 데이터 가져오기
  static Future<Uint8List?> loadPdfData(String fileId) async {
    if (!kIsWeb) return null;
    
    try {
      // PDF가 만료되었는지 확인
      if (isPdfExpired(fileId)) {
        // 만료된 경우 데이터 삭제
        await deletePdfData(fileId);
        return null;
      }
      
      // Base64 인코딩된 PDF 데이터 가져오기
      final base64Data = getItem('pdf_$fileId');
      if (base64Data == null) return null;
      
      // Base64 디코딩하여 바이트 배열로 변환
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('PDF 데이터 로드 중 오류: $e');
      return null;
    }
  }
  
  /// PDF 데이터 삭제
  static Future<bool> deletePdfData(String fileId) async {
    if (!kIsWeb) return false;
    
    try {
      // PDF 데이터 삭제
      removeItem('pdf_$fileId');
      // 메타데이터 삭제
      removeItem('pdf_${fileId}_metadata');
      return true;
    } catch (e) {
      debugPrint('PDF 데이터 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// PDF가 만료되었는지 확인
  static bool isPdfExpired(String fileId) {
    return isItemExpired('pdf_$fileId');
  }
  
  /// 항목이 만료되었는지 확인 (범용 메소드)
  static bool isItemExpired(String key) {
    if (!kIsWeb) return false;
    
    final metadataStr = getItem('${key}_metadata');
    if (metadataStr == null) return false;
    
    try {
      final metadata = json.decode(metadataStr) as Map<String, dynamic>;
      final timestamp = metadata['timestamp'] as int;
      final isGuest = metadata['isGuest'] as bool;
      final expirationDays = metadata['expirationDays'] as int;
      
      // 미회원이 아니거나 만료 일수가 0이면 만료되지 않음
      if (!isGuest || expirationDays == 0) return false;
      
      final createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(createdDate).inDays;
      
      return difference >= expirationDays;
    } catch (e) {
      debugPrint('만료 확인 중 오류: $e');
      return false;
    }
  }
  
  /// PDF 만료까지 남은 일수 가져오기
  static int getRemainingDaysForPdf(String fileId) {
    return getRemainingDays('pdf_$fileId');
  }
  
  /// 항목 만료까지 남은 일수 가져오기 (범용 메소드)
  static int getRemainingDays(String key) {
    if (!kIsWeb) return 0;
    
    final metadataStr = getItem('${key}_metadata');
    if (metadataStr == null) return 0;
    
    try {
      final metadata = json.decode(metadataStr) as Map<String, dynamic>;
      final timestamp = metadata['timestamp'] as int;
      final isGuest = metadata['isGuest'] as bool;
      final expirationDays = metadata['expirationDays'] as int;
      
      // 미회원이 아니거나 만료 일수가 0이면 만료되지 않음
      if (!isGuest || expirationDays == 0) return 0;
      
      final createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(createdDate).inDays;
      
      return (expirationDays - difference).clamp(0, expirationDays);
    } catch (e) {
      debugPrint('만료일 계산 중 오류: $e');
      return 0;
    }
  }
  
  /// 만료된 모든 데이터 제거
  static Future<void> removeExpiredData() async {
    if (!kIsWeb) return;
    
    final List<String> keysToRemove = [];
    
    html.window.localStorage.forEach((key, value) {
      if (key.endsWith('_metadata')) {
        final dataKey = key.substring(0, key.length - 9);
        if (isItemExpired(dataKey)) {
          keysToRemove.add(dataKey);
          keysToRemove.add(key);
        }
      }
    });
    
    for (final key in keysToRemove) {
      removeItem(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('만료된 데이터 ${keysToRemove.length ~/ 2}개 제거됨');
    }
  }
  
  /// 모든 PDF 파일 ID 가져오기
  static List<String> getAllPdfIds() {
    if (!kIsWeb) return [];
    
    final List<String> pdfIds = [];
    html.window.localStorage.forEach((key, value) {
      if (key.startsWith('pdf_') && !key.endsWith('_metadata')) {
        pdfIds.add(key.substring(4)); // 'pdf_' 접두사 제거
      }
    });
    
    return pdfIds;
  }
} 