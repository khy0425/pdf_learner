import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PDF 서비스 인터페이스
/// 
/// PDF 파일의 열기, 닫기, 페이지 이동, 렌더링 등의 기능을 제공합니다.
abstract class PDFService {
  /// PDF 파일을 엽니다.
  Future<bool> openPDF(File file);

  /// 현재 열린 PDF 파일의 총 페이지 수를 반환합니다.
  Future<int> getPageCount();

  /// 현재 페이지 번호를 반환합니다.
  Future<int> getCurrentPage();

  /// 지정된 페이지로 이동합니다.
  Future<bool> goToPage(int pageNumber);

  /// 현재 페이지를 렌더링합니다.
  Future<List<int>> renderPage();

  /// 현재 페이지의 텍스트를 추출합니다.
  Future<String> extractText();

  /// PDF 파일의 메타데이터를 반환합니다.
  Future<Map<String, dynamic>> getMetadata();

  /// PDF 파일 내에서 텍스트를 검색합니다.
  Future<List<Map<String, dynamic>>> searchText(String query);

  /// PDF 파일을 닫습니다.
  Future<bool> closePDF();

  /// 리소스를 해제합니다.
  void dispose();

  // PDF 문서 관련 메서드
  Future<List<PDFDocument>> getDocuments();
  Future<PDFDocument?> getDocument(String id);
  Future<void> createDocument(PDFDocument document);
  Future<void> updateDocument(PDFDocument document);
  Future<void> deleteDocument(String id);
  Future<PDFDocument> importPDF(File file);
  Future<void> saveDocument(PDFDocument document);

  // 북마크 관련 메서드
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId);
  Future<void> createBookmark(PDFBookmark bookmark);
  Future<void> updateBookmark(PDFBookmark bookmark);
  Future<void> deleteBookmark(String documentId, String bookmarkId);
  Future<void> saveBookmark(PDFBookmark bookmark);

  // 파일 관련 메서드
  Future<String> uploadPDFFile(Uint8List file);
  Future<void> deletePDFFile(String filePath);

  // 검색 및 필터링 메서드
  Future<List<PDFDocument>> searchDocuments(String query);
  Future<List<PDFDocument>> getFavoriteDocuments();
  Future<List<PDFDocument>> getRecentDocuments();

  // 문서 상태 업데이트 메서드
  Future<bool> toggleFavorite(String id);
  Future<void> updateReadingProgress(String id, double progress);
  Future<void> updateCurrentPage(String id, int page);
  Future<void> updateReadingTime(String id, int seconds);

  // 동기화 메서드
  Future<void> syncWithRemote();

  // PDF 파일 처리 관련 메서드
  Future<int> getPageCount(String filePath);
  Future<String> extractText(String filePath, int pageNumber);
}

@LazySingleton(as: PDFService)
class PDFServiceImpl implements PDFService {
  final PDFRepository _pdfRepository;
  final StorageService _storageService;
  final SharedPreferences _prefs;
  File? _currentFile;
  int _currentPage = 0;
  int _totalPages = 0;
  Map<String, dynamic>? _metadata;

  PDFServiceImpl(this._pdfRepository, this._storageService, this._prefs);

  // PDF 문서 관련 메서드
  @override
  Future<List<PDFDocument>> getDocuments() async {
    return await _pdfRepository.getDocuments();
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    return await _pdfRepository.getDocument(id);
  }

  @override
  Future<void> createDocument(PDFDocument document) async {
    await _pdfRepository.createDocument(document);
  }

  @override
  Future<void> updateDocument(PDFDocument document) async {
    await _pdfRepository.updateDocument(document);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _pdfRepository.deleteDocument(id);
  }

  @override
  Future<PDFDocument> importPDF(File file) async {
    return await _pdfRepository.importPDF(file);
  }

  @override
  Future<void> saveDocument(PDFDocument document) async {
    await _pdfRepository.saveDocument(document);
  }

  // 북마크 관련 메서드
  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    return await _pdfRepository.getBookmarks(documentId);
  }

  @override
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId) async {
    return await _pdfRepository.getBookmark(documentId, bookmarkId);
  }

  @override
  Future<void> createBookmark(PDFBookmark bookmark) async {
    await _pdfRepository.createBookmark(bookmark);
  }

  @override
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    await _pdfRepository.updateBookmark(bookmark);
  }

  @override
  Future<void> deleteBookmark(String documentId, String bookmarkId) async {
    await _pdfRepository.deleteBookmark(documentId, bookmarkId);
  }

  @override
  Future<void> saveBookmark(PDFBookmark bookmark) async {
    await _pdfRepository.saveBookmark(bookmark);
  }

  // 파일 관련 메서드
  @override
  Future<String> uploadPDFFile(Uint8List file) async {
    return await _pdfRepository.uploadPDFFile(file);
  }

  @override
  Future<void> deletePDFFile(String filePath) async {
    await _pdfRepository.deletePDFFile(filePath);
  }

  // 검색 및 필터링 메서드
  @override
  Future<List<PDFDocument>> searchDocuments(String query) async {
    return await _pdfRepository.searchDocuments(query);
  }

  @override
  Future<List<PDFDocument>> getFavoriteDocuments() async {
    return await _pdfRepository.getFavoriteDocuments();
  }

  @override
  Future<List<PDFDocument>> getRecentDocuments() async {
    return await _pdfRepository.getRecentDocuments();
  }

  // 문서 상태 업데이트 메서드
  @override
  Future<bool> toggleFavorite(String id) async {
    return await _pdfRepository.toggleFavorite(id);
  }

  @override
  Future<void> updateReadingProgress(String id, double progress) async {
    await _pdfRepository.updateReadingProgress(id, progress);
  }

  @override
  Future<void> updateCurrentPage(String id, int page) async {
    await _pdfRepository.updateCurrentPage(id, page);
  }

  @override
  Future<void> updateReadingTime(String id, int seconds) async {
    await _pdfRepository.updateReadingTime(id, seconds);
  }

  // 동기화 메서드
  @override
  Future<void> syncWithRemote() async {
    await _pdfRepository.syncWithRemote();
  }

  // PDF 파일 처리 관련 메서드
  @override
  Future<int> getPageCount(String filePath) async {
    if (kIsWeb) {
      return 1; // 웹에서는 기본값
    } else if (filePath.isNotEmpty && File(filePath).existsSync()) {
      return await _pdfRepository.getPageCount(filePath);
    }
    return 1; // 기본값
  }

  @override
  Future<String> extractText(String filePath, int pageNumber) async {
    if (kIsWeb) {
      return '웹 환경에서 텍스트 추출은 아직 구현되지 않았습니다.';
    } else if (filePath.isNotEmpty && File(filePath).existsSync()) {
      return await _pdfRepository.extractText(filePath, pageNumber);
    }
    return '텍스트를 추출할 수 없습니다.';
  }

  @override
  Future<bool> openPDF(File file) async {
    try {
      _currentFile = file;
      _currentPage = 0;
      _totalPages = await getPageCount(file.path);
      _metadata = await getMetadata();
      
      // 마지막으로 열었던 페이지 복원
      final lastPage = await _storageService.getLastOpenedPage(file.path);
      if (lastPage != null) {
        _currentPage = lastPage;
      }
      
      return true;
    } catch (e) {
      print('PDF 파일 열기 실패: $e');
      return false;
    }
  }

  @override
  Future<int> getPageCount() async {
    if (_currentFile == null) return 0;
    return await getPageCount(_currentFile!.path);
  }

  @override
  Future<int> getCurrentPage() async {
    return _currentPage;
  }

  @override
  Future<bool> goToPage(int pageNumber) async {
    if (_currentFile == null || pageNumber < 0 || pageNumber >= _totalPages) {
      return false;
    }
    _currentPage = pageNumber;
    
    // 현재 페이지 저장
    if (_currentFile != null) {
      await _storageService.setLastOpenedPage(_currentFile!.path, pageNumber);
    }
    
    return true;
  }

  @override
  Future<List<int>> renderPage() async {
    if (_currentFile == null) return [];
    // TODO: PDF 페이지 렌더링 로직 구현
    return [];
  }

  @override
  Future<String> extractText() async {
    if (_currentFile == null) return '';
    return await extractText(_currentFile!.path, _currentPage);
  }

  @override
  Future<Map<String, dynamic>> getMetadata() async {
    if (_currentFile == null) return {};
    return await _pdfRepository.getMetadata(_currentFile!.path);
  }

  @override
  Future<List<Map<String, dynamic>>> searchText(String query) async {
    if (_currentFile == null) return [];
    final results = await searchText(_currentFile!.path, query);
    return results.map((text) => {'text': text}).toList();
  }

  @override
  Future<bool> closePDF() async {
    try {
      _currentFile = null;
      _currentPage = 0;
      _totalPages = 0;
      _metadata = null;
      return true;
    } catch (e) {
      print('PDF 파일 닫기 실패: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _currentFile = null;
    _currentPage = 0;
    _totalPages = 0;
    _metadata = null;
  }
} 