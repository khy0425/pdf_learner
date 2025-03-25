import 'dart:io';
import 'dart:typed_data';
import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';

/// PDF 문서 관리를 위한 리포지토리 인터페이스
abstract class PDFRepository {
  /// 문서 관련 메서드
  Future<List<PDFDocument>> getDocuments();
  Future<PDFDocument?> getDocument(String documentId);
  Future<void> createDocument(PDFDocument document);
  Future<void> updateDocument(PDFDocument document);
  Future<void> deleteDocument(String documentId);
  
  /// 북마크 관련 메서드
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  Future<PDFBookmark?> getBookmark(String bookmarkId);
  Future<void> createBookmark(PDFBookmark bookmark);
  Future<void> updateBookmark(PDFBookmark bookmark);
  Future<void> deleteBookmark(String bookmarkId);
  
  /// 파일 관련 메서드
  Future<String> uploadPDFFile(String filePath, String fileName, {Uint8List? bytes});
  Future<void> deletePDFFile(String fileUrl);
  
  /// PDF 처리 관련 메서드
  Future<int> getPageCount(String filePath);
  Future<String> extractText(String filePath, int pageNumber);
  
  /// 리소스 정리
  void dispose();
} 