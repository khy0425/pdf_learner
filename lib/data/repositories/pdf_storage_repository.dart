import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/pdf_document.dart';
import '../services/file_storage_service.dart';
import '../utils/web_utils.dart';

/// PDF 파일 저장소
class PDFStorageRepository {
  final FileStorageService _storageService;
  
  PDFStorageRepository({
    required FileStorageService storageService,
  }) : _storageService = storageService;
  
  /// URL에서 PDF 다운로드 및 저장
  Future<String?> downloadAndSaveFromUrl(String url, String title) async {
    try {
      if (kIsWeb) {
        // 웹에서는 URL을 그대로 반환
        return url;
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
        return await _storageService.savePdfBytes(bytes, fileName);
      }
      return null;
    } catch (e) {
      debugPrint('URL에서 PDF 다운로드 중 오류: $e');
      return null;
    }
  }
  
  /// 파일에서 PDF 저장
  Future<String?> saveFromFile(File file, String title) async {
    try {
      if (kIsWeb) {
        // 웹에서는 지원되지 않음
        return null;
      }
      
      final pdfBytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      return await _storageService.savePdfBytes(pdfBytes, fileName);
    } catch (e) {
      debugPrint('파일에서 PDF 저장 중 오류: $e');
      return null;
    }
  }
  
  /// 바이트 데이터에서 PDF 저장
  Future<String?> saveFromBytes(Uint8List bytes, String title) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
      
      if (kIsWeb) {
        // 웹에서는 blob URL 생성
        return WebUtils.createBlobUrl(bytes, 'application/pdf');
      } else {
        return await _storageService.savePdfBytes(bytes, fileName);
      }
    } catch (e) {
      debugPrint('바이트에서 PDF 저장 중 오류: $e');
      return null;
    }
  }
  
  /// PDF 파일 삭제
  Future<bool> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 blob URL 해제
        WebUtils.revokeBlobUrl(filePath);
        return true;
      } else {
        return await _storageService.deleteFile(filePath);
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// PDF 파일을 바이트 배열로 다운로드
  Future<Uint8List> downloadPdfAsBytes(String filePath) async {
    try {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        // URL인 경우 HTTP 요청으로 다운로드
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      } else if (kIsWeb) {
        // 웹에서 로컬 스토리지의 문서인 경우
        if (WebUtils.existsInLocalStorage(filePath)) {
          final bytes = WebUtils.loadBytesFromLocalStorage(filePath);
          if (bytes != null) {
            return bytes;
          }
        }
        throw Exception('웹 환경에서 파일을 찾을 수 없습니다: $filePath');
      } else {
        // 로컬 파일인 경우
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
        throw Exception('파일을 찾을 수 없습니다: $filePath');
      }
    } catch (e) {
      debugPrint('PDF 다운로드 중 오류: $e');
      rethrow;
    }
  }
} 