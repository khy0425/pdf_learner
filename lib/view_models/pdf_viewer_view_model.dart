import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../view_models/pdf_file_view_model.dart';
import '../services/pdf_service.dart';
import '../services/ai_service.dart';

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
  
  // 확대/축소 관련 상수
  static const double _minZoomLevel = 0.05;
  static const double _maxZoomLevel = 5.0;
  static const double _zoomStep = 0.05;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isPdfLoaded => _isPdfLoaded;
  Uint8List? get pdfData => _pdfData;
  Uint8List? get pdfBytes => _pdfData;
  int get currentPage => _currentPage;
  double get zoomLevel => _zoomLevel;
  bool get isHighlightMode => _isHighlightMode;
  List<String> get bookmarks => _bookmarks;
  
  PdfViewerViewModel({required PdfFileViewModel pdfViewModel}) 
      : _pdfViewModel = pdfViewModel;
  
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
  
  /// 현재 페이지 설정
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }
  
  /// 확대 레벨 설정
  void setZoomLevel(double level) {
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
  void toggleBookmark() {
    final pageKey = 'page_$_currentPage';
    
    if (_bookmarks.contains(pageKey)) {
      _bookmarks.remove(pageKey);
    } else {
      _bookmarks.add(pageKey);
    }
    
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
  Future<void> generateSummary(String pdfId) async {
    try {
      _setLoading(true);
      
      // 실제 구현에서는 AI 서비스를 통해 요약 생성
      final summary = await _aiService.generateSummary(pdfId);
      
      // 요약 결과 처리 로직 추가
      
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
  
  /// 오류 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
} 