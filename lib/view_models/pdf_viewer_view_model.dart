import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../view_models/pdf_view_model.dart';

/// PDF 뷰어 화면의 ViewModel
/// PDF 뷰어 관련 상태와 로직을 관리합니다.
class PdfViewerViewModel extends ChangeNotifier {
  final PdfViewModel _pdfViewModel;
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPdfLoaded = false;
  Uint8List? _pdfData;
  int _currentPage = 1;
  double _zoomLevel = 1.0;
  
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
  int get currentPage => _currentPage;
  double get zoomLevel => _zoomLevel;
  
  PdfViewerViewModel({required PdfViewModel pdfViewModel}) 
      : _pdfViewModel = pdfViewModel;
  
  /// PDF 데이터 로드
  Future<void> loadPdfData(String pdfId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final pdfData = await _pdfViewModel.getPdfData(pdfId);
      
      if (pdfData == null) {
        throw Exception('PDF 데이터를 불러올 수 없습니다.');
      }
      
      _pdfData = pdfData;
      _isPdfLoaded = true;
      
      debugPrint('PDF 데이터 로드 완료: ${pdfData.length} 바이트');
    } catch (e) {
      debugPrint('PDF 데이터 로드 오류: $e');
      _setError(e.toString());
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