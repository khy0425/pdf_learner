import 'dart:io';
import 'dart:typed_data';
import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';
import '../../core/utils/result.dart';
import '../../presentation/models/pdf_file_info.dart';

/// PDF 레포지토리 인터페이스
abstract class PDFRepository {
  /// 모든 PDF 문서 가져오기
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// 특정 PDF 문서 가져오기
  Future<Result<PDFDocument>> getDocument(String id);
  
  /// PDF 문서 저장
  Future<Result<PDFDocument>> saveDocument(PDFDocument document);
  
  /// PDF 문서 생성
  Future<Result<PDFDocument>> createDocument(PDFDocument document);
  
  /// PDF 문서 삭제
  Future<Result<bool>> deleteDocument(String documentId);
  
  /// 문서 북마크 목록 가져오기
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// 특정 북마크 가져오기
  Future<Result<PDFBookmark>> getBookmark(String id);
  
  /// 북마크 저장
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark);
  
  /// 북마크 생성
  Future<Result<PDFBookmark>> createBookmark(PDFBookmark bookmark);
  
  /// 북마크 삭제
  Future<Result<bool>> deleteBookmark(String bookmarkId);
  
  /// 마지막으로 읽은 페이지 저장
  Future<Result<int>> saveLastReadPage(String documentId, int page);
  
  /// 마지막으로 읽은 페이지 가져오기
  Future<Result<int>> getLastReadPage(String documentId);
  
  /// 문서 검색
  Future<Result<List<PDFDocument>>> searchDocuments(String query);
  
  /// 문서 정렬
  Future<Result<List<PDFDocument>>> sortDocuments(
    List<PDFDocument> documents,
    String sortBy,
    bool ascending,
  );
  
  /// PDF 파일 다운로드
  Future<Result<Uint8List>> downloadPdf(String url);
  
  /// PDF 파일 저장
  Future<Result<String>> savePdfFile(Uint8List bytes, String fileName);
  
  /// 최근 문서 조회
  Future<Result<List<PDFDocument>>> getRecentDocuments(int limit);
  
  /// 즐겨찾기 문서 조회
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  
  /// PDF 문서 업데이트
  Future<Result<PDFDocument>> updateDocument(PDFDocument document);
  
  /// 샘플 PDF 로드
  Future<Uint8List?> loadSamplePdf();
  
  /// 로컬 PDF 파일 로드
  Future<Uint8List?> loadLocalPdf(String filePath);
  
  /// PDF 파일 선택 및 업로드
  Future<Result<PDFDocument?>> pickAndUploadPDF();
  
  /// 파일 시스템에서 PDF 파일 목록 가져오기
  Future<List<PdfFileInfo>> getPdfFiles();
  
  /// PDF 파일 추가
  Future<PdfFileInfo> addPdf(PdfFileInfo pdfInfo, Uint8List fileData);
  
  /// PDF 파일 삭제
  Future<void> deletePdf(String pdfId);
} 