import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';
import '../../core/base/result.dart';

/// PDF 레포지토리 인터페이스
abstract class PDFRepository {
  /// 모든 PDF 문서 목록을 가져옵니다.
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// ID로 특정 PDF 문서를 가져옵니다.
  Future<Result<PDFDocument?>> getDocument(String id);
  
  /// PDF 문서를 저장합니다.
  Future<Result<PDFDocument>> saveDocument(PDFDocument document);
  
  /// PDF 문서를 업데이트합니다.
  Future<Result<PDFDocument>> updateDocument(PDFDocument document);
  
  /// PDF 문서를 삭제합니다.
  Future<Result<bool>> deleteDocument(String id);
  
  /// PDF 문서의 북마크 목록을 가져옵니다.
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// PDF 문서 객체로부터 PDF 파일을 다운로드합니다.
  Future<Result<Uint8List>> downloadPdf(PDFDocument document);

  /// URL로부터 PDF 파일을 다운로드합니다.
  Future<Result<Uint8List>> downloadPdfFromUrl(String url);
  
  Future<Result<bool>> toggleFavorite(String id);
  
  Future<Result<PDFBookmark?>> getBookmark(String id);
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark);
  Future<Result<bool>> deleteBookmark(String id);
  
  Future<Result<int>> getLastReadPage(String documentId);
  Future<Result<void>> saveLastReadPage(String documentId, int page);
  
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  Future<Result<List<PDFDocument>>> getRecentDocuments([int limit = 10]);
  
  Future<Result<List<String>>> getSearchHistory();
  Future<Result<void>> addSearchQuery(String query);
  Future<Result<void>> clearSearchHistory();
  
  Future<Result<void>> syncWithRemote();
  Future<Result<String>> saveFile(Uint8List bytes, String fileName, {String? directory});
  Future<Result<bool>> deleteFile(String path);
  Future<Result<bool>> fileExists(String path);
  Future<Result<int>> getFileSize(String path);
  Future<Result<void>> clearCache();
  
  /// 로컬 파일로부터 PDF를 가져옵니다.
  Future<Result<PDFDocument>> importPDF(io.File file);
  
  /// 샘플 PDF 파일을 로드합니다.
  Future<Result<Uint8List>> loadSamplePdf();
  
  /// 파일 경로에서 PDF 바이트를 가져옵니다
  Future<Result<Uint8List>> getPdfBytes(String filePath);
} 