import 'dart:io';
import 'dart:typed_data';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

/// PDF 문서와 북마크 관리를 위한 레포지토리 인터페이스
abstract class PDFRepository {
  /// 모든 PDF 문서 조회
  Future<List<PDFDocument>> getDocuments();
  
  /// 특정 ID로 문서 조회
  Future<PDFDocument?> getDocument(String id);
  
  /// 새 문서 생성
  Future<void> createDocument(PDFDocument document);
  
  /// 문서 정보 업데이트
  Future<void> updateDocument(PDFDocument document);
  
  /// 문서 삭제
  Future<void> deleteDocument(String id);
  
  /// 특정 문서의 모든 북마크 조회
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  
  /// 특정 북마크 조회
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId);
  
  /// 새 북마크 생성
  Future<void> createBookmark(PDFBookmark bookmark);
  
  /// 북마크 정보 업데이트
  Future<void> updateBookmark(PDFBookmark bookmark);
  
  /// 북마크 삭제
  Future<void> deleteBookmark(String documentId, String bookmarkId);
  
  /// PDF 파일 업로드
  Future<String> uploadPDFFile(Uint8List file);
  
  /// PDF 파일 삭제
  Future<void> deletePDFFile(String filePath);
  
  /// PDF 페이지 수 가져오기
  Future<int> getPageCount(String filePath);
  
  /// PDF에서 텍스트 추출
  Future<String> extractText(String filePath, int pageNumber);
  
  /// PDF 메타데이터 조회
  Future<Map<String, dynamic>> getMetadata(String filePath);
  
  /// 리소스 정리
  void dispose();
} 