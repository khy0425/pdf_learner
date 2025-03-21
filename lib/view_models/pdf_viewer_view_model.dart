import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../view_models/pdf_file_view_model.dart';
import '../services/pdf_service.dart';
import '../services/ai_service.dart';

/// PDF 페이지 모델
class PdfPageModel {
  final int pageNumber;
  final String text;
  final List<String> annotations;
  final List<String> highlights;
  bool isBookmarked;
  
  PdfPageModel({
    required this.pageNumber,
    this.text = '',
    this.annotations = const [],
    this.highlights = const [],
    this.isBookmarked = false,
  });
  
  PdfPageModel copyWith({
    int? pageNumber,
    String? text,
    List<String>? annotations,
    List<String>? highlights,
    bool? isBookmarked,
  }) {
    return PdfPageModel(
      pageNumber: pageNumber ?? this.pageNumber,
      text: text ?? this.text,
      annotations: annotations ?? this.annotations,
      highlights: highlights ?? this.highlights,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// PDF 요약 모델
class SummaryModel {
  final String content;
  final DateTime createdAt;
  final String apiModel;
  
  SummaryModel({
    required this.content,
    required this.createdAt,
    required this.apiModel,
  });
}

/// PDF 뷰어 화면의 ViewModel
/// PDF 뷰어 관련 상태와 로직을 관리합니다.
class PdfViewerViewModel extends ChangeNotifier {
  final PdfFileViewModel _pdfViewModel;
  final PDFService _pdfService = PDFService();
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPdfLoaded = false;
  Uint8List? _pdfData;
  int _currentPage = 1;
  double _zoomLevel = 1.0;
  bool _isHighlightMode = false;
  List<String> _bookmarks = [];
  List<PdfPageModel> _pages = [];
  SummaryModel? _summary;
  
  // 확대/축소 관련 상수
  static const double _minZoomLevel = 0.5;
  static const double _maxZoomLevel = 3.0;
  static const double _zoomStep = 0.05;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String? get error => hasError ? errorMessage : null;
  bool get isPdfLoaded => _isPdfLoaded;
  Uint8List? get pdfData => _pdfData;
  Uint8List? get pdfBytes => _pdfData;
  int get currentPage => _currentPage;
  double get zoomLevel => _zoomLevel;
  bool get isHighlightMode => _isHighlightMode;
  List<String> get bookmarks => _bookmarks;
  List<PdfPageModel> get pages => _pages;
  int get pageCount => _pages.length;
  bool get isTextExtractionComplete => _isPdfLoaded && !_isLoading;
  SummaryModel? get summary => _summary;
  
  PdfViewerViewModel({required PdfFileViewModel pdfViewModel}) 
      : _pdfViewModel = pdfViewModel {
    _initializePages();
  }
  
  /// 페이지 초기화
  void _initializePages() {
    // PDF가 로드되기 전에 빈 페이지 모델을 생성
    _pages = List.generate(
      15, // 기본값, 실제 PDF 로드 후 업데이트됨
      (index) => PdfPageModel(
        pageNumber: index + 1,
        text: '페이지 ${index + 1}의 텍스트 내용입니다.',
        isBookmarked: index == 0 || index == 5, // 첫 페이지와 6번째 페이지는 북마크 설정
      ),
    );
  }
  
  /// PDF 데이터 로드
  Future<void> loadPdfData(String pdfId) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (pdfId.isEmpty) {
        debugPrint('PDF ID가 비어 있습니다.');
        throw Exception('유효하지 않은 PDF ID입니다.');
      }
      
      final pdfData = await _pdfViewModel.getPdfData(pdfId);
      
      if (pdfData == null) {
        debugPrint('가져온 PDF 데이터가 null입니다.');
        throw Exception('PDF 데이터를 불러올 수 없습니다.');
      }
      
      if (pdfData.isEmpty) {
        debugPrint('가져온 PDF 데이터가 비어 있습니다.');
        throw Exception('PDF 데이터가 비어 있습니다.');
      }
      
      _pdfData = pdfData;
      _isPdfLoaded = true;
      
      // 실제 PDF 로딩 후 페이지 정보 업데이트
      _updatePagesFromPdf();
      
      debugPrint('PDF 데이터 로드 완료: ${pdfData.length} 바이트');
    } catch (e) {
      debugPrint('PDF 데이터 로드 오류: $e');
      _setError(e.toString());
      _isPdfLoaded = false;
      _pdfData = null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 로드 후 페이지 정보 업데이트
  void _updatePagesFromPdf() {
    // 여기서는 실제 PDF에서 페이지 정보를 추출하는 로직이 구현되어야 함
    // 현재는 mock 데이터와 일관성을 유지하기 위해 기본 구현만 제공
    final pageCount = _pdfViewModel.getPageCount(); // 실제로는 PDF에서 추출
    
    _pages = List.generate(
      pageCount > 0 ? pageCount : 15,
      (index) => PdfPageModel(
        pageNumber: index + 1,
        text: '페이지 ${index + 1}의 텍스트 내용입니다. 이것은 테스트용 텍스트입니다.',
        annotations: index % 3 == 0 ? ['주석 ${index + 1}-1', '주석 ${index + 1}-2'] : [],
        highlights: index % 2 == 0 ? ['중요 내용 ${index + 1}'] : [],
        isBookmarked: index == 0 || index == 5,
      ),
    );
  }
  
  /// 페이지 이동
  void goToPage(int page) {
    if (page < 1 || page > _pages.length) return;
    _currentPage = page;
    notifyListeners();
  }
  
  /// 다음 페이지로 이동
  void nextPage() {
    if (_currentPage < _pages.length) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  /// 이전 페이지로 이동
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  /// 현재 페이지 설정
  void setCurrentPage(int page) {
    goToPage(page);
  }
  
  /// 확대 레벨 설정
  void setZoomLevel(double level) {
    if (level < _minZoomLevel || level > _maxZoomLevel) return;
    _zoomLevel = level;
    notifyListeners();
  }
  
  /// 확대
  void zoomIn() {
    _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoomLevel, _maxZoomLevel);
    notifyListeners();
  }
  
  /// 축소
  void zoomOut() {
    _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoomLevel, _maxZoomLevel);
    notifyListeners();
  }
  
  /// 하이라이트 모드 토글
  void toggleHighlightMode() {
    _isHighlightMode = !_isHighlightMode;
    notifyListeners();
  }
  
  /// 북마크 토글
  void toggleBookmark(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _pages.length) {
      return;
    }
    
    final pageIndex = pageNumber - 1;
    final newIsBookmarked = !_pages[pageIndex].isBookmarked;
    
    // PdfPageModel 객체 업데이트
    _pages[pageIndex] = _pages[pageIndex].copyWith(
      isBookmarked: newIsBookmarked,
    );
    
    // 기존 bookmarks 배열 관리 (이전 방식과의 호환성용)
    final pageKey = 'page_$pageNumber';
    if (newIsBookmarked) {
      if (!_bookmarks.contains(pageKey)) {
        _bookmarks.add(pageKey);
      }
    } else {
      _bookmarks.remove(pageKey);
    }
    
    notifyListeners();
  }
  
  /// 현재 페이지 북마크 토글 (편의 메서드)
  void toggleCurrentBookmark() {
    toggleBookmark(_currentPage);
  }
  
  /// 주석 추가
  Future<void> addAnnotation(int pageNumber, String annotation) async {
    if (pageNumber < 1 || pageNumber > _pages.length || annotation.isEmpty) {
      return;
    }
    
    final pageIndex = pageNumber - 1;
    final updatedAnnotations = List<String>.from(_pages[pageIndex].annotations)
      ..add(annotation);
    
    _pages[pageIndex] = _pages[pageIndex].copyWith(
      annotations: updatedAnnotations,
    );
    
    notifyListeners();
  }
  
  /// 하이라이트 추가
  Future<void> addHighlight(int pageNumber, String highlight) async {
    if (pageNumber < 1 || pageNumber > _pages.length || highlight.isEmpty) {
      return;
    }
    
    final pageIndex = pageNumber - 1;
    final updatedHighlights = List<String>.from(_pages[pageIndex].highlights)
      ..add(highlight);
    
    _pages[pageIndex] = _pages[pageIndex].copyWith(
      highlights: updatedHighlights,
    );
    
    notifyListeners();
  }
  
  /// 텍스트 검색
  void searchText(String text) {
    if (_pdfData == null || text.isEmpty) {
      return;
    }
    
    // 실제 검색 로직은 SfPdfViewer 위젯에서 처리됨
    notifyListeners();
  }
  
  /// 검색 결과 초기화
  void clearSearch() {
    notifyListeners();
  }
  
  /// AI 요약 생성
  Future<void> generateSummary([String? pdfId]) async {
    try {
      _setLoading(true);
      
      // 실제 구현에서는 AI 서비스를 통해 요약 생성
      final pdfIdentifier = pdfId ?? _pdfViewModel.id;
      final summaryContent = await _aiService.generateSummary(pdfIdentifier);
      
      _summary = SummaryModel(
        content: summaryContent ?? 
          '이 문서에 관한 AI 요약입니다. 총 ${_pages.length} 페이지로 구성되어 있으며, 주요 내용은 테스트 데이터입니다.',
        createdAt: DateTime.now(),
        apiModel: 'gemini-pro',
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('요약 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 퀴즈 생성
  Future<void> generateQuiz(String pdfId) async {
    try {
      _setLoading(true);
      
      // 실제 구현에서는 AI 서비스를 통해 퀴즈 생성
      final quiz = await _aiService.generateQuiz(pdfId);
      
      // 퀴즈 결과 처리 로직 추가
      
      _setLoading(false);
    } catch (e) {
      _setError('퀴즈 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }
  
  void setError(String error) {
    _setError(error);
  }
  
  /// 오류 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
  
  void clearError() {
    _clearError();
  }
} 