import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../../core/utils/gc_utils.dart';
import '../../../core/services/pdf_service.dart';
import '../../data/datasources/pdf_local_datasource.dart';

/// PDF 뷰어의 상태를 나타내는 열거형
enum PDFViewerState {
  initial,
  loading,
  loaded,
  error,
  disposed
}

/// PDF 뷰어의 에러 상태를 나타내는 열거형
enum PDFViewerError {
  none,
  documentNotFound,
  loadFailed,
  saveFailed,
  bookmarkFailed,
  invalidPage
}

/// PDF 뷰어 뷰모델
/// 
/// PDF 문서의 로딩, 페이지 이동, 북마크 관리 등의 기능을 제공합니다.
/// 
/// 주요 기능:
/// - PDF 문서 로드 및 표시
/// - 페이지 탐색
/// - 북마크 관리
/// - 즐겨찾기 관리
/// - 메모리 관리
/// 
/// 사용 예시:
/// ```dart
/// final viewModel = PDFViewerViewModel(repository, pdfService);
/// await viewModel.loadDocument('document_id');
/// ```
class PDFViewerViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  final PDFService _pdfService;
  final PDFLocalDataSource _localDataSource;
  
  // 상태 관리
  PDFViewerState _state = PDFViewerState.initial;
  PDFViewerError _error = PDFViewerError.none;
  String _errorMessage = '';
  
  // PDF 문서 관련
  PDFDocument? _document;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = false;
  
  // 북마크 관련
  List<PDFBookmark> _bookmarks = [];
  
  // 페이지 캐시
  final Map<int, List<int>> _pageCache = {};
  static const int _maxCacheSize = 5;
  
  // 생성자
  PDFViewerViewModel({
    required PDFRepository repository,
    required PDFService pdfService,
    required PDFLocalDataSource localDataSource,
  }) : _repository = repository,
       _pdfService = pdfService,
       _localDataSource = localDataSource;
  
  // Getters
  PDFViewerState get state => _state;
  PDFViewerError get error => _error;
  String get errorMessage => _errorMessage;
  PDFDocument? get document => _document;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  List<PDFBookmark> get bookmarks => _bookmarks;
  
  /// PDF 문서를 로드합니다.
  Future<void> loadDocument(String id) async {
    try {
      _setLoading(true);
      _clearError();
      notifyListeners();

      final document = await _repository.getDocument(id);
      if (document != null) {
        _document = document;
        _totalPages = document.totalPages;
        _currentPage = document.currentPage;
      } else {
        _setError(PDFViewerError.documentNotFound, '문서를 찾을 수 없습니다.');
      }
    } catch (e) {
      _setError(PDFViewerError.loadFailed, '문서 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// 페이지를 변경합니다.
  Future<void> changePage(int pageNumber) async {
    if (_state != PDFViewerState.loaded || _isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // 페이지 유효성 검사
      if (pageNumber < 1 || pageNumber > _totalPages) {
        _setError(PDFViewerError.invalidPage, '유효하지 않은 페이지 번호입니다.');
        return;
      }
      
      // 페이지 이동
      final success = await _pdfService.goToPage(pageNumber);
      if (!success) {
        _setError(PDFViewerError.loadFailed, '페이지 이동에 실패했습니다.');
        return;
      }
      
      _currentPage = pageNumber;
      
      // 페이지 캐시 관리
      await _managePageCache();
      
      notifyListeners();
    } catch (e) {
      _setError(PDFViewerError.loadFailed, '페이지 변경 중 오류가 발생했습니다: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 북마크를 추가합니다.
  Future<void> addBookmark({String? note}) async {
    if (_state != PDFViewerState.loaded || _document == null) return;
    
    try {
      final bookmark = PDFBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: _document!.id,
        pageNumber: _currentPage,
        note: note,
        createdAt: DateTime.now(),
      );
      
      final success = await _localDataSource.saveBookmark(_document!.id, bookmark);
      if (!success) {
        _setError(PDFViewerError.bookmarkFailed, '북마크 저장에 실패했습니다.');
        return;
      }
      
      _bookmarks.add(bookmark);
      notifyListeners();
    } catch (e) {
      _setError(PDFViewerError.bookmarkFailed, '북마크 추가 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 북마크를 삭제합니다.
  Future<void> deleteBookmark(String bookmarkId) async {
    if (_state != PDFViewerState.loaded || _document == null) return;
    
    try {
      final success = await _localDataSource.deleteBookmark(_document!.id, bookmarkId);
      if (!success) {
        _setError(PDFViewerError.bookmarkFailed, '북마크 삭제에 실패했습니다.');
        return;
      }
      
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
      notifyListeners();
    } catch (e) {
      _setError(PDFViewerError.bookmarkFailed, '북마크 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 즐겨찾기 상태를 토글합니다.
  Future<void> toggleFavorite() async {
    if (_state != PDFViewerState.loaded || _document == null) return;
    
    try {
      final updatedDocument = _document!.copyWith(
        isFavorite: !_document!.isFavorite,
      );
      
      final success = await _localDataSource.updateDocument(updatedDocument);
      if (!success) {
        _setError(PDFViewerError.saveFailed, '즐겨찾기 상태 변경에 실패했습니다.');
        return;
      }
      
      _document = updatedDocument;
      notifyListeners();
    } catch (e) {
      _setError(PDFViewerError.saveFailed, '즐겨찾기 상태 변경 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 리소스를 정리합니다.
  @override
  void dispose() {
    _pdfService.dispose();
    _pageCache.clear();
    _setState(PDFViewerState.disposed);
    super.dispose();
  }
  
  // Private methods
  
  /// 상태를 설정합니다.
  void _setState(PDFViewerState state) {
    _state = state;
    notifyListeners();
  }
  
  /// 에러를 설정합니다.
  void _setError(PDFViewerError error, String message) {
    _error = error;
    _errorMessage = message;
    _state = PDFViewerState.error;
    notifyListeners();
  }
  
  /// 에러를 초기화합니다.
  void _clearError() {
    _error = PDFViewerError.none;
    _errorMessage = '';
  }
  
  /// 북마크를 로드합니다.
  Future<void> _loadBookmarks() async {
    if (_document == null) return;
    
    try {
      _bookmarks = await _localDataSource.getBookmarks(_document!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('북마크 로드 실패: $e');
    }
  }
  
  /// 페이지 캐시를 관리합니다.
  Future<void> _managePageCache() async {
    // 현재 페이지 캐시
    if (!_pageCache.containsKey(_currentPage)) {
      final pageData = await _pdfService.renderPage();
      _pageCache[_currentPage] = pageData;
    }
    
    // 캐시 크기 제한
    if (_pageCache.length > _maxCacheSize) {
      final keysToRemove = _pageCache.keys
          .where((key) => key != _currentPage)
          .take(_pageCache.length - _maxCacheSize);
      
      for (final key in keysToRemove) {
        _pageCache.remove(key);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
} 