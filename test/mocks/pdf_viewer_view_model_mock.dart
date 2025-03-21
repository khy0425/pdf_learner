import 'package:flutter/foundation.dart';
import 'auth_view_model_mock.dart';
import 'home_view_model_mock.dart';

/// PDF 페이지 모델
class PdfPageModel {
  final int pageNumber;
  final String text;
  final List<String> annotations;
  final List<String> highlights;
  final bool isBookmarked;
  
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

/// 요약 정보 모델
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

/// PdfViewerViewModel 모의 클래스
class MockPdfViewerViewModel extends ChangeNotifier {
  final PdfFileModel _pdfFile;
  final MockAuthViewModel _authViewModel;
  
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _isTextExtractionComplete = false;
  List<PdfPageModel> _pages = [];
  SummaryModel? _summary;
  double _zoomLevel = 1.0;
  
  PdfFileModel get pdfFile => _pdfFile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageCount => _pages.length;
  bool get isTextExtractionComplete => _isTextExtractionComplete;
  List<PdfPageModel> get pages => _pages;
  SummaryModel? get summary => _summary;
  double get zoomLevel => _zoomLevel;
  MockAuthViewModel get authViewModel => _authViewModel;
  
  MockPdfViewerViewModel({
    required PdfFileModel pdfFile,
    MockAuthViewModel? authViewModel,
  }) : _pdfFile = pdfFile,
       _authViewModel = authViewModel ?? MockAuthViewModel() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    // 비동기 작업 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 샘플 페이지 데이터 생성
    _pages = List.generate(
      _pdfFile.pageCount > 0 ? _pdfFile.pageCount : 10,
      (index) => PdfPageModel(
        pageNumber: index + 1,
        text: '페이지 ${index + 1}의 텍스트 내용입니다. 이것은 테스트용 텍스트입니다.',
        annotations: index % 3 == 0 ? ['주석 ${index + 1}-1', '주석 ${index + 1}-2'] : [],
        highlights: index % 2 == 0 ? ['중요 내용 ${index + 1}'] : [],
        isBookmarked: index == 0 || index == 5,
      ),
    );
    
    _isTextExtractionComplete = true;
    _isLoading = false;
    notifyListeners();
  }
  
  /// 페이지 이동
  void goToPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _pages.length) return;
    
    _currentPage = pageNumber;
    notifyListeners();
  }
  
  /// 다음 페이지
  void nextPage() {
    if (_currentPage < _pages.length) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  /// 이전 페이지
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  /// 북마크 토글
  Future<void> toggleBookmark(int pageNumber) async {
    final index = pageNumber - 1;
    if (index < 0 || index >= _pages.length) return;
    
    _pages[index] = _pages[index].copyWith(
      isBookmarked: !_pages[index].isBookmarked,
    );
    
    notifyListeners();
  }
  
  /// 주석 추가
  Future<void> addAnnotation(int pageNumber, String annotation) async {
    final index = pageNumber - 1;
    if (index < 0 || index >= _pages.length) return;
    
    final updatedAnnotations = List<String>.from(_pages[index].annotations)
      ..add(annotation);
    
    _pages[index] = _pages[index].copyWith(
      annotations: updatedAnnotations,
    );
    
    notifyListeners();
  }
  
  /// 하이라이트 추가
  Future<void> addHighlight(int pageNumber, String highlight) async {
    final index = pageNumber - 1;
    if (index < 0 || index >= _pages.length) return;
    
    final updatedHighlights = List<String>.from(_pages[index].highlights)
      ..add(highlight);
    
    _pages[index] = _pages[index].copyWith(
      highlights: updatedHighlights,
    );
    
    notifyListeners();
  }
  
  /// 요약 생성
  Future<void> generateSummary() async {
    _isLoading = true;
    notifyListeners();
    
    // 비동기 작업 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    
    _summary = SummaryModel(
      content: '이 문서는 ${_pdfFile.name}에 관한 내용을 다루고 있습니다. 총 ${_pages.length} 페이지로 구성되어 있으며, 주요 내용은 테스트 데이터입니다.',
      createdAt: DateTime.now(),
      apiModel: 'gemini-pro',
    );
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// 확대/축소 레벨 설정
  void setZoomLevel(double level) {
    if (level < 0.5 || level > 3.0) return;
    
    _zoomLevel = level;
    notifyListeners();
  }
  
  /// 오류 설정 (테스트용)
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  /// 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 