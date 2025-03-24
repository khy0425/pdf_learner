import 'dart:io';
import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';

/// PDF 문서 관리를 위한 리포지토리 인터페이스
abstract class PDFRepository {
  /// 문서 가져오기
  Future<PDFDocument?> getDocument(String id);
  
  /// 문서 목록 가져오기
  Future<List<PDFDocument>> getDocuments();
  
  /// PDF 파일 가져오기
  Future<PDFDocument> importPDF(File file);
  
  /// 문서 업데이트
  Future<void> updateDocument(PDFDocument document);
  
  /// 문서 삭제
  Future<void> deleteDocument(String id);
  
  /// 북마크 목록 가져오기
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  
  /// 북마크 추가
  Future<void> addBookmark(PDFBookmark bookmark);
  
  /// 북마크 삭제
  Future<void> deleteBookmark(String bookmarkId);
  
  /// 리소스 정리
  void dispose();

  Future<PDFDocument> addDocument(PDFDocument document);
  Future<PDFDocument> updateDocument(PDFDocument document);
  Future<bool> deleteDocument(String id);
} 