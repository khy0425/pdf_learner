import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';
import '../utils/web_utils.dart';

/// PDF 웹 저장소
class PDFWebRepository {
  /// 웹 환경에서 PDF 문서 추가
  Future<PDFDocument?> addDocumentFromUrl(String url, String title) async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('웹에서 URL로 문서 추가: $url');
      
      // 썸네일 URL 생성 (PDF URL에서 가능한 경우)
      String thumbnailPath = '';
      
      // Adobe PDF인 경우 썸네일 추정
      if (url.contains('adobe.com') && url.endsWith('.pdf')) {
        thumbnailPath = url.replaceAll('.pdf', '.jpg');
      }
      // arXiv PDF인 경우 썸네일 추정
      else if (url.contains('arxiv.org/pdf/')) {
        final paperIdMatch = RegExp(r'(\d+\.\d+)').firstMatch(url);
        if (paperIdMatch != null) {
          final paperId = paperIdMatch.group(1);
          thumbnailPath = 'https://arxiv.org/html/${paperId}v1/x1.png';
        }
      }
      
      // 문서 객체 생성
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: url,
        thumbnailPath: thumbnailPath,
        totalPages: 1, // 페이지 수는 계산할 수 없으므로 기본값 설정
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        bookmarks: [],
      );
      
      return document;
    } catch (e) {
      debugPrint('URL에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 웹 환경에서 PDF 문서 추가 (바이트 데이터)
  Future<PDFDocument?> addDocumentFromBytes(Uint8List bytes, String title) async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('웹에서 바이트 배열로 문서 추가: $title (크기: ${bytes.length} 바이트)');
      
      String blobUrl = '';
      
      try {
        // WebUtils를 사용하여 Blob URL 생성
        blobUrl = WebUtils.createBlobUrl(bytes, 'application/pdf');
        debugPrint('Blob URL 생성 성공: ${blobUrl.substring(0, min(50, blobUrl.length))}...');
        
        // 문서 객체 생성
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          filePath: blobUrl,
          thumbnailPath: '',
          totalPages: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFavorite: false,
          bookmarks: [],
        );
        
        return document;
      } catch (e) {
        debugPrint('Blob URL 생성 오류: $e');
        
        // 오류 시 base64 데이터로 저장 시도
        try {
          final base64Data = WebUtils.bytesToBase64(bytes);
          final document = PDFDocument(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            filePath: 'data:application/pdf;base64,$base64Data',
            thumbnailPath: '',
            totalPages: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isFavorite: false,
            bookmarks: [],
          );
          
          return document;
        } catch (e2) {
          debugPrint('Base64 인코딩 저장 오류: $e2');
          return null;
        }
      }
    } catch (e) {
      debugPrint('바이트에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 웹 환경에서 PDF 문서 삭제
  Future<bool> deleteDocument(PDFDocument document) async {
    if (!kIsWeb) return false;
    
    try {
      // Blob URL 해제
      if (document.filePath.startsWith('blob:')) {
        WebUtils.revokeBlobUrl(document.filePath);
      }
      
      // 북마크 데이터 삭제
      WebUtils.removeFromLocalStorage('pdf_bookmarks_${document.id}');
      
      return true;
    } catch (e) {
      debugPrint('웹 문서 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 두 수 중 작은 값 반환
  int min(int a, int b) => a < b ? a : b;
} 