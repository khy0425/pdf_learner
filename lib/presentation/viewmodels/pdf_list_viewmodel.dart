import 'dart:async';
import '../../domain/models/pdf_document.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/storage/storage_service.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/utils/web_utils.dart';

/// PDF 목록 뷰 상태
enum PDFListViewState {
  /// 초기 상태
  initial,
  
  /// 로딩 중
  loading,
  
  /// 성공 상태
  success,
  
  /// 오류 상태
  error,
}

/// PDF 문서 목록 뷰모델
class PDFListViewModel extends BaseViewModel {
  final PDFRepository _repository;
  // ignore: unused_field
  final StorageService _storageService;
  
  // 상태 변수
  List<PDFDocument> _documents = [];
  List<PDFDocument> _filteredDocuments = [];
  String _searchQuery = '';
  bool _isGridView = true;
  // ignore: unused_field
  PDFListViewState _state = PDFListViewState.initial;
  // ignore: unused_field
  String _errorMessage = '';
  
  // 생성자
  PDFListViewModel({
    required PDFRepository repository,
    required StorageService storageService,
  }) : 
    _repository = repository,
    _storageService = storageService;
  
  // 게터
  List<PDFDocument> get documents => _searchQuery.isEmpty
      ? _documents
      : _filteredDocuments;
  bool get isGridView => _isGridView;
  String get searchQuery => _searchQuery;
  
  // 초기화
  Future<void> init() async {
    setLoading(true);
    await loadDocuments();
    setLoaded();
  }
  
  // 문서 목록 로드
  Future<void> loadDocuments() async {
    _setState(PDFListViewState.loading);
    
    try {
      final result = await _repository.getDocuments();
      
      if (result.isSuccess) {
        _documents = result.data ?? [];
        _filteredDocuments = List.from(_documents);
        _setState(PDFListViewState.success);
      } else {
        _setError('문서 로드 실패: ${result.error}');
      }
    } catch (e) {
      _setError('문서 로드 중 오류: $e');
    }
  }
  
  // 문서 검색
  void searchDocuments(String query) {
    _searchQuery = query;
    _searchDocuments(query);
    notifyListeners();
  }
  
  // 내부 검색 처리
  void _searchDocuments(String query) {
    if (query.isEmpty) {
      _filteredDocuments = List.from(_documents);
      return;
    }
    
    _filteredDocuments = _documents.where((document) {
      final title = document.title.toLowerCase();
      final desc = document.description?.toLowerCase() ?? '';
      final q = query.toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }
  
  // 최신순 정렬
  void sortByDateAdded() {
    _documents.sort((a, b) {
      final aCreatedAt = a.createdAt;
      final bCreatedAt = b.createdAt;
      
      if (bCreatedAt == null && aCreatedAt == null) {
        return 0;
      } else if (bCreatedAt == null) {
        return -1;
      } else if (aCreatedAt == null) {
        return 1;
      }
      return bCreatedAt.compareTo(aCreatedAt);
    });
    _searchDocuments(_searchQuery);
    notifyListeners();
  }
  
  // 제목순 정렬
  void sortByTitle() {
    _documents.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    _searchDocuments(_searchQuery);
    notifyListeners();
  }
  
  // 크기순 정렬
  void sortBySize() {
    _documents.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    _searchDocuments(_searchQuery);
    notifyListeners();
  }
  
  // 즐겨찾기 토글
  Future<void> toggleFavorite(PDFDocument document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    // 기존 문서 객체를 유지하여 오류 발생 시 복원할 수 있도록 합니다
    final originalDocument = document;
    
    // 새 문서 객체를 생성하여 isFavorite 값을 반전시킵니다
    final updatedDocument = PDFDocument(
      id: document.id,
      title: document.title,
      filePath: document.filePath,
      fileSize: document.fileSize,
      pageCount: document.pageCount,
      lastReadPage: document.lastReadPage,
      readingProgress: document.readingProgress,
      isFavorite: !document.isFavorite,
      createdAt: document.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      // 기타 필요한 속성들 복사
      author: document.author,
      description: document.description,
      thumbnailPath: document.thumbnailPath,
      status: document.status,
      category: document.category,
      accessLevel: document.accessLevel,
    );
    
    try {
      // UI 즉시 업데이트
      _documents[index] = updatedDocument;
      _searchDocuments(_searchQuery);
      notifyListeners();
      
      // 실제 저장
      final result = await _repository.updateDocument(updatedDocument);
      
      if (result.isSuccess) {
        // 성공 시 아무 작업 안함
      } else {
        // 실패 시 복원
        _documents[index] = originalDocument;
        _searchDocuments(_searchQuery);
        notifyListeners();
        _setError("즐겨찾기 변경 실패: ${result.error}");
      }
    } catch (e) {
      // 실패 시 복원
      _documents[index] = originalDocument;
      _searchDocuments(_searchQuery);
      notifyListeners();
      _setError(e.toString());
    }
  }
  
  // 문서 이름 변경
  Future<void> renameDocument(PDFDocument document, String newTitle) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    // 기존 문서 객체를 유지
    final originalDocument = document;
    
    // 새 문서 객체 생성
    final updatedDocument = PDFDocument(
      id: document.id,
      title: newTitle,
      filePath: document.filePath,
      fileSize: document.fileSize,
      pageCount: document.pageCount,
      lastReadPage: document.lastReadPage,
      readingProgress: document.readingProgress,
      isFavorite: document.isFavorite,
      createdAt: document.createdAt,
      updatedAt: DateTime.now(),
      // 기타 필요한 속성들 복사
      author: document.author,
      description: document.description,
      thumbnailPath: document.thumbnailPath,
      status: document.status,
      category: document.category,
      accessLevel: document.accessLevel,
    );
    
    try {
      // UI 즉시 업데이트
      _documents[index] = updatedDocument;
      _searchDocuments(_searchQuery);
      notifyListeners();
      
      // 실제 저장
      final result = await _repository.updateDocument(updatedDocument);
      
      if (result.isSuccess) {
        // 성공 시 아무 작업 안함
      } else {
        // 실패 시 복원
        _documents[index] = originalDocument;
        _searchDocuments(_searchQuery);
        notifyListeners();
        _setError("문서 이름 변경 실패: ${result.error}");
      }
    } catch (e) {
      // 실패 시 복원
      _documents[index] = originalDocument;
      _searchDocuments(_searchQuery);
      notifyListeners();
      _setError(e.toString());
    }
  }
  
  // 문서 삭제
  Future<void> deleteDocument(PDFDocument document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    try {
      // UI 즉시 업데이트
      final removedDocument = _documents.removeAt(index);
      _searchDocuments(_searchQuery);
      notifyListeners();
      
      // 실제 삭제
      final result = await _repository.deleteDocument(document.id);
      
      if (result.isSuccess) {
        // 성공 시 아무 작업 안함
      } else {
        // 실패 시 복원
        _documents.insert(index, removedDocument);
        _searchDocuments(_searchQuery);
        notifyListeners();
        _setError("문서 삭제 실패: ${result.error}");
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // 문서 공유
  Future<void> shareDocument(PDFDocument document) async {
    try {
      // 웹 환경의 경우 다운로드
      final webUtils = WebUtils();
      if (webUtils.isWeb) {
        webUtils.downloadFile(document.downloadUrl, document.title);
      } else {
        // 모바일 환경의 경우 공유
        final filePath = document.filePath;
        await webUtils.shareUrl(filePath);
      }
    } catch (e) {
      setError(e.toString());
    }
  }
  
  // 보기 모드 전환
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }
  
  // 문서 즐겨찾기 목록 가져오기
  List<PDFDocument> getFavorites() {
    return _documents.where((doc) => doc.isFavorite).toList();
  }
  
  // 최근 문서 목록 가져오기
  List<PDFDocument> getRecentDocuments() {
    final sorted = List<PDFDocument>.from(_documents);
    sorted.sort((a, b) {
      final aUpdatedAt = a.updatedAt;
      final bUpdatedAt = b.updatedAt;
      
      if (bUpdatedAt == null && aUpdatedAt == null) {
        return 0;
      } else if (bUpdatedAt == null) {
        return -1;
      } else if (aUpdatedAt == null) {
        return 1;
      }
      return bUpdatedAt.compareTo(aUpdatedAt);
    });
    return sorted.take(5).toList();
  }
  
  /// 상태 설정
  void _setState(PDFListViewState newState) {
    _state = newState;
    notifyListeners();
  }

  /// 오류 설정
  void _setError(String message) {
    _errorMessage = message;
    _setState(PDFListViewState.error);
  }
} 