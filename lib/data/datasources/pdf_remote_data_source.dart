import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../core/base/result.dart';
import 'dart:async';

/// PDF 원격 데이터 소스 인터페이스
abstract class PDFRemoteDataSource {
  /// 모든 PDF 문서 목록 가져오기
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// ID로 특정 PDF 문서 가져오기
  Future<Result<PDFDocument>> getDocument(String documentId);
  
  /// PDF 문서에 속한 모든 북마크 가져오기
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// 문서 ID와 북마크 ID로 북마크 가져오기
  Future<Result<PDFBookmark>> getBookmarkByIds(String documentId, String bookmarkId);
  
  /// 북마크 ID로 북마크 가져오기
  Future<Result<PDFBookmark?>> getBookmarkById(String id);
  
  /// 새 PDF 문서 추가
  Future<Result<String>> addDocument(PDFDocument document);
  
  /// 문서 생성 (새 API, addDocument와 동일)
  Future<Result<String>> createDocument(PDFDocument document);
  
  /// PDF 문서 업데이트
  Future<Result<bool>> updateDocument(PDFDocument document);
  
  /// PDF 문서 저장 (updateDocument 래퍼)
  Future<Result<void>> saveDocument(PDFDocument document);
  
  /// PDF 문서 삭제
  Future<Result<bool>> deleteDocument(String documentId);
  
  /// 북마크 추가
  Future<Result<String>> addBookmark(PDFBookmark bookmark);
  
  /// 북마크 업데이트
  Future<Result<bool>> updateBookmark(PDFBookmark bookmark);
  
  /// 북마크 저장 (updateBookmark 래퍼)
  Future<Result<void>> saveBookmark(PDFBookmark bookmark);
  
  /// 북마크 삭제
  Future<Result<bool>> deleteBookmark(String documentId, String bookmarkId);
  
  /// 마지막으로 읽은 페이지 저장
  Future<Result<bool>> saveLastReadPage(String documentId, int page);
  
  /// 로컬 문서를 원격 서버와 동기화
  Future<Result<List<PDFDocument>>> syncWithRemote(List<PDFDocument> localDocuments, List<PDFBookmark> localBookmarks);
  
  /// 텍스트로 문서 검색
  Future<Result<List<PDFDocument>>> searchDocuments(String query);
  
  /// 즐겨찾기 토글
  Future<Result<bool>> toggleFavorite(String id);
  
  /// 즐겨찾기된 문서 가져오기
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  
  /// 최근 문서 가져오기
  Future<Result<List<PDFDocument>>> getRecentDocuments();
  
  /// 모든 북마크 가져오기
  Future<Result<List<PDFBookmark>>> getAllBookmarks();
  
  /// 읽기 진행도 업데이트
  Future<Result<void>> updateReadingProgress(String id, double progress);
  
  /// 현재 페이지 업데이트
  Future<Result<void>> updateCurrentPage(String id, int page);
  
  /// 읽기 시간 업데이트
  Future<Result<void>> updateReadingTime(String id, int seconds);
  
  /// 파일 업로드
  Future<Result<String>> uploadFile(String filePath);
  
  /// 파일 다운로드
  Future<Result<String?>> downloadFile(String remoteUrl);
  
  /// PDF 파일 다운로드
  Future<Result<Uint8List>> downloadPdf(String documentId);
  
  /// 파일 삭제
  Future<Result<bool>> deleteFile(String remoteUrl);
  
  /// PDF 파일 가져오기
  Future<Result<PDFDocument>> importPDF(File file);
  
  /// 리소스 해제
  void dispose();
}