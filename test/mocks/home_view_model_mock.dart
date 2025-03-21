import 'package:flutter/foundation.dart';
import 'auth_view_model_mock.dart';

/// PDF 파일 모델
class PdfFileModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;
  final int pageCount;
  final String thumbnailPath;
  final bool isFavorite;
  final DateTime? lastOpenedAt;
  
  PdfFileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    this.pageCount = 0,
    this.thumbnailPath = '',
    this.isFavorite = false,
    this.lastOpenedAt,
  });
  
  PdfFileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? createdAt,
    int? pageCount,
    String? thumbnailPath,
    bool? isFavorite,
    DateTime? lastOpenedAt,
  }) {
    return PdfFileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}

/// HomeViewModel 모의 클래스
class MockHomeViewModel extends ChangeNotifier {
  final MockAuthViewModel _authViewModel;
  List<PdfFileModel> _pdfFiles = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String _searchQuery = '';
  
  List<PdfFileModel> get pdfFiles => _searchQuery.isEmpty 
    ? _pdfFiles 
    : _pdfFiles.where((pdf) => 
        pdf.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  MockAuthViewModel get authViewModel => _authViewModel;
  
  MockHomeViewModel({MockAuthViewModel? authViewModel}) 
    : _authViewModel = authViewModel ?? MockAuthViewModel() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 샘플 PDF 파일 목록 생성
    _pdfFiles = [
      PdfFileModel(
        id: 'sample-pdf-1',
        name: '샘플 PDF 1.pdf',
        path: '/path/to/sample1.pdf',
        size: 1024 * 1024 * 2, // 2MB
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        pageCount: 10,
        isFavorite: true,
        lastOpenedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PdfFileModel(
        id: 'sample-pdf-2',
        name: '샘플 PDF 2.pdf',
        path: '/path/to/sample2.pdf',
        size: 1024 * 1024 * 1, // 1MB
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        pageCount: 5,
      ),
      PdfFileModel(
        id: 'sample-pdf-3',
        name: '테스트 문서.pdf',
        path: '/path/to/test.pdf',
        size: 1024 * 1024 * 3, // 3MB
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        pageCount: 15,
      ),
    ];
    
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }
  
  /// 검색 쿼리 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// PDF 파일 추가
  Future<void> addPdfFile(PdfFileModel pdfFile) async {
    _isLoading = true;
    notifyListeners();
    
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    _pdfFiles.add(pdfFile);
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// PDF 파일 삭제
  Future<void> deletePdfFile(String id) async {
    _isLoading = true;
    notifyListeners();
    
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    _pdfFiles.removeWhere((pdf) => pdf.id == id);
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// PDF 파일 즐겨찾기 토글
  Future<void> toggleFavorite(String id) async {
    final index = _pdfFiles.indexWhere((pdf) => pdf.id == id);
    if (index == -1) return;
    
    _pdfFiles[index] = _pdfFiles[index].copyWith(
      isFavorite: !_pdfFiles[index].isFavorite,
    );
    
    notifyListeners();
  }
  
  /// PDF 파일 이름 변경
  Future<void> renamePdfFile(String id, String newName) async {
    _isLoading = true;
    notifyListeners();
    
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    final index = _pdfFiles.indexWhere((pdf) => pdf.id == id);
    if (index != -1) {
      _pdfFiles[index] = _pdfFiles[index].copyWith(name: newName);
    }
    
    _isLoading = false;
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