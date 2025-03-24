import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/thumbnail_service.dart';
import '../services/file_storage_service.dart';
import '../utils/web_utils.dart';

/// PDF 썸네일 저장소
class PDFThumbnailRepository {
  final ThumbnailService _thumbnailService;
  final FileStorageService _storageService;
  
  PDFThumbnailRepository({
    required ThumbnailService thumbnailService,
    required FileStorageService storageService,
  }) : _thumbnailService = thumbnailService,
       _storageService = storageService;
  
  /// PDF 파일에서 썸네일 생성
  Future<String?> generateThumbnail(Uint8List pdfBytes, String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 썸네일 생성 로직이 다름
        return await _generateWebThumbnail(pdfBytes);
      } else {
        return await _thumbnailService.generateThumbnail(pdfBytes, filePath);
      }
    } catch (e) {
      debugPrint('썸네일 생성 중 오류: $e');
      return null;
    }
  }
  
  /// 웹 환경에서 썸네일 생성
  Future<String?> _generateWebThumbnail(Uint8List pdfBytes) async {
    try {
      // 웹에서는 썸네일을 base64로 저장
      final thumbnailBytes = await _thumbnailService.generateThumbnailBytes(pdfBytes);
      if (thumbnailBytes != null) {
        return WebUtils.bytesToBase64(thumbnailBytes);
      }
      return null;
    } catch (e) {
      debugPrint('웹 썸네일 생성 중 오류: $e');
      return null;
    }
  }
  
  /// 썸네일 삭제
  Future<bool> deleteThumbnail(String thumbnailPath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 썸네일이 base64로 저장되어 있으므로 별도 삭제 불필요
        return true;
      } else {
        return await _storageService.deleteFile(thumbnailPath);
      }
    } catch (e) {
      debugPrint('썸네일 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 썸네일 URL 가져오기
  String? getThumbnailUrl(String thumbnailPath) {
    if (kIsWeb) {
      // 웹에서는 base64 데이터를 data URL로 변환
      return thumbnailPath.startsWith('data:') 
          ? thumbnailPath 
          : 'data:image/jpeg;base64,$thumbnailPath';
    } else {
      // 네이티브에서는 파일 경로를 그대로 사용
      return thumbnailPath;
    }
  }
} 