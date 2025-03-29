import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/base/result.dart';
import 'dart:io' as io;

/// PDF 문서 로컬 데이터 소스 인터페이스
abstract class PDFLocalDataSource {
  /// 모든 PDF 문서를 가져옵니다.
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// ID로 특정 PDF 문서를 가져옵니다.
  Future<Result<PDFDocument?>> getDocument(String id);
  
  /// PDF 문서를 저장합니다.
  Future<Result<void>> saveDocument(PDFDocument document);
  
  /// PDF 문서를 삭제합니다.
  Future<Result<bool>> deleteDocument(String id);
  
  /// PDF 문서에 대한 모든 북마크를 가져옵니다.
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// 모든 북마크를 가져옵니다.
  Future<Result<List<PDFBookmark>>> getAllBookmarks();
  
  /// ID로 특정 북마크를 가져옵니다.
  Future<Result<PDFBookmark?>> getBookmark(String id);
  
  /// 북마크를 저장합니다.
  Future<Result<String>> saveBookmark(PDFBookmark bookmark);
  
  /// 북마크를 삭제합니다.
  Future<Result<bool>> deleteBookmark(String id);
  
  /// 검색어를 저장합니다.
  Future<Result<bool>> addSearchQuery(String query);
  
  /// 검색 기록을 가져옵니다.
  Future<Result<List<String>>> getSearchHistory();
  
  /// 검색 기록을 삭제합니다.
  Future<Result<bool>> clearSearchHistory();
  
  /// 캐시를 정리합니다.
  Future<Result<void>> clearCache();
  
  /// 파일을 저장합니다.
  Future<Result<String>> saveFile(String path, Uint8List bytes);
  
  /// 파일을 삭제합니다.
  Future<Result<bool>> deleteFile(String path);
  
  /// 파일 존재 여부를 확인합니다.
  Future<Result<bool>> fileExists(String path);
  
  /// 파일 크기를 가져옵니다.
  Future<Result<int>> getFileSize(String path);
  
  /// 즐겨찾기한 문서를 가져옵니다.
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  
  /// 마지막으로 읽은 페이지를 가져옵니다.
  Future<Result<int>> getLastReadPage(String documentId);
  
  /// 마지막으로 읽은 페이지를 저장합니다.
  Future<Result<bool>> saveLastReadPage(String documentId, int page);
  
  /// PDF 파일을 가져옵니다.
  Future<Result<PDFDocument>> importPDF(io.File file);
  
  /// 북마크 즐겨찾기 상태를 토글합니다.
  Future<Result<bool>> toggleBookmarkFavorite(String id);
  
  /// 문서의 즐겨찾기 상태를 토글합니다.
  Future<Result<bool>> toggleFavorite(String id);
  
  /// 리소스를 해제합니다.
  void dispose();
} 