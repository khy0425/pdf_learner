import 'dart:async';
// 플랫폼에 따라 다른 임포트
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 웹이 아닌 경우에만 path_provider 임포트
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_document.dart';
import '../repositories/pdf_repository.dart';

class PDFViewerViewModel extends ChangeNotifier {
  PDFDocument? _document;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isFullScreen = false;
  double _zoomLevel = 1.0;
  List<PDFAnnotation> _annotations = [];
  List<PDFBookmark> _bookmarks = [];
  String? _searchQuery;
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;
  bool _isNightMode = false;
  bool _isTwoPageView = false;
  final PdfRepository _repository = PdfRepository();

  // 게터
  PDFDocument? get document => _document;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  bool get isFullScreen => _isFullScreen;
  double get zoomLevel => _zoomLevel;
  List<PDFAnnotation> get annotations => _annotations;
  List<PDFBookmark> get bookmarks => _bookmarks;
  String? get searchQuery => _searchQuery;
  List<int> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  bool get isNightMode => _isNightMode;
  bool get isTwoPageView => _isTwoPageView;
  bool get hasDocument => _document != null;
  int get pageCount => _document?.pageCount ?? 0;
  bool get canGoBack => _currentPage > 1;
  bool get canGoForward => _document != null && _currentPage < _document!.pageCount;

  // 문서 로드
  Future<void> loadDocument(String filePath) async {
    setLoading(true);
    
    try {
      if (kIsWeb) {
        debugPrint('웹 환경에서 문서 로드 시작: $filePath');
        
        // 기존 문서 확인
        final existingDoc = await _findExistingDocument(filePath);
        if (existingDoc != null) {
          debugPrint('기존 문서 발견: ${existingDoc.title}');
          _document = existingDoc;
          _currentPage = 1;
          _loadAnnotationsAndBookmarks();
          await _repository.updateRecentDocument(existingDoc.id);
          return;
        }
        
        // 웹 URL 처리
        String url = filePath;
        // URL이 완전한 형태가 아닌 경우 처리
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          debugPrint('완전한 URL이 아님, 조정 시도: $url');
        }
        
        // 웹 환경에서는 리포지토리를 통해 문서 생성
        final fileName = filePath.split('/').last;
        final document = PDFDocument(
          id: const Uuid().v4(),
          title: fileName.replaceAll('.pdf', ''),
          filePath: filePath,
          fileName: fileName,
          fileSize: 0, // 웹에서는 파일 크기를 알 수 없음
          pageCount: await _getPageCount(filePath), // 실제 구현에서는 PDF 라이브러리를 통해 페이지 수 가져오기
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          url: url, // URL 필드 설정
        );
        
        _document = document;
        _currentPage = 1;
        _annotations = [];
        _bookmarks = [];
        
        // 저장소에 문서 저장
        await _repository.saveDocument(document);
        await _repository.updateRecentDocument(document.id);
        debugPrint('웹 환경에서 문서 로드 완료: ${document.title}, URL: ${document.url}');
      } else {
        // 네이티브 환경에서는 파일 시스템 접근
        final File file = File(filePath);
        if (!await file.exists()) {
          throw Exception('파일이 존재하지 않습니다: $filePath');
        }
        
        final fileName = filePath.split('/').last;
        final fileSize = await file.length();
        
        final document = PDFDocument(
          id: const Uuid().v4(),
          title: fileName.replaceAll('.pdf', ''),
          filePath: filePath,
          fileName: fileName,
          fileSize: fileSize,
          pageCount: await _getPageCount(filePath), // 실제 구현에서는 PDF 라이브러리를 통해 페이지 수 가져오기
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );
        
        _document = document;
        _currentPage = 1;
        _annotations = [];
        _bookmarks = [];
        
        // 저장소에 문서 저장
        await _repository.saveDocument(document);
        await _repository.updateRecentDocument(document.id);
      }
      
      // 저장된 설정 로드
      await _loadSettings();
    } catch (e) {
      debugPrint('문서 로드 중 오류 발생: $e');
    } finally {
      setLoading(false);
    }
  }

  // 썸네일 생성
  Future<String?> _generateThumbnail(String filePath) async {
    // 여기서는 실제 PDF 첫 페이지 캡처 로직 구현
    // 예제 코드이므로 실제로는 null 반환
    return null;
  }

  // 페이지 수 가져오기 (실제로는 PDF 라이브러리 사용)
  Future<int> _getPageCount(String filePath) async {
    // 예제 코드이므로 고정 값 반환
    return 10;
  }

  // 기존 문서 검색
  Future<PDFDocument?> _findExistingDocument(String filePath) async {
    try {
      final documents = await _repository.getDocuments();
      return documents.firstWhere(
        (doc) => doc.filePath == filePath,
        orElse: () => throw Exception('No document found'),
      );
    } catch (e) {
      return null;
    }
  }

  // 주석과 북마크 로드
  void _loadAnnotationsAndBookmarks() {
    if (_document == null) return;
    
    // 문서에서 주석과 북마크 로드
    _annotations = List<PDFAnnotation>.from(_document!.annotations);
    _bookmarks = List<PDFBookmark>.from(_document!.bookmarks);
    
    debugPrint('북마크 ${_bookmarks.length}개와 주석 ${_annotations.length}개를 로드했습니다.');
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNightMode = prefs.getBool('pdfNightMode') ?? false;
      _isTwoPageView = prefs.getBool('pdfTwoPageView') ?? false;
      _zoomLevel = prefs.getDouble('pdfZoomLevel') ?? 1.0;
      notifyListeners();
    } catch (e) {
      debugPrint('설정 로드 중 오류 발생: $e');
    }
  }

  // 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pdfNightMode', _isNightMode);
      await prefs.setBool('pdfTwoPageView', _isTwoPageView);
      await prefs.setDouble('pdfZoomLevel', _zoomLevel);
    } catch (e) {
      debugPrint('설정 저장 중 오류 발생: $e');
    }
  }

  // 로딩 상태 변경
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 페이지 이동
  void goToPage(int page) {
    if (_document == null) return;
    
    if (page < 1) {
      page = 1;
    } else if (page > _document!.pageCount) {
      page = _document!.pageCount;
    }
    
    _currentPage = page;
    notifyListeners();
  }

  // 이전 페이지
  void previousPage() {
    if (canGoBack) {
      _currentPage--;
      notifyListeners();
    }
  }

  // 다음 페이지
  void nextPage() {
    if (canGoForward) {
      _currentPage++;
      notifyListeners();
    }
  }

  // 첫 페이지
  void firstPage() {
    goToPage(1);
  }

  // 마지막 페이지
  void lastPage() {
    if (_document != null) {
      goToPage(_document!.pageCount);
    }
  }

  // 확대/축소
  void setZoom(double value) {
    if (value < 0.5) {
      value = 0.5;
    } else if (value > 3.0) {
      value = 3.0;
    }
    
    _zoomLevel = value;
    _saveSettings();
    notifyListeners();
  }

  // 주석 추가
  Future<void> addAnnotation(String content, AnnotationType type, Rect rect) async {
    if (_document == null) return;
    
    final annotation = PDFAnnotation(
      id: const Uuid().v4(),
      pageNumber: _currentPage,
      content: content,
      type: type,
      rect: rect,
      createdAt: DateTime.now(),
    );
    
    _annotations.add(annotation);
    
    // 문서 업데이트
    _document = _document!.copyWith(
      annotations: _annotations,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 북마크 추가
  Future<void> addBookmark(String title) async {
    if (_document == null) return;
    
    // 같은 페이지의 중복 북마크 체크
    final existingBookmark = _bookmarks.any((b) => b.pageNumber == _currentPage);
    if (existingBookmark) {
      throw Exception('이미 이 페이지에 북마크가 있습니다.');
    }
    
    final bookmark = PDFBookmark(
      id: const Uuid().v4(),
      pageNumber: _currentPage,
      title: title.isEmpty ? '페이지 $_currentPage' : title,
      createdAt: DateTime.now(),
    );
    
    _bookmarks.add(bookmark);
    
    // 문서 업데이트
    _document = _document!.copyWith(
      bookmarks: _bookmarks,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 북마크 삭제
  Future<void> removeBookmark(String id) async {
    if (_document == null) return;
    
    _bookmarks.removeWhere((b) => b.id == id);
    
    // 문서 업데이트
    _document = _document!.copyWith(
      bookmarks: _bookmarks,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 주석 삭제
  Future<void> removeAnnotation(String id) async {
    if (_document == null) return;
    
    _annotations.removeWhere((a) => a.id == id);
    
    // 문서 업데이트
    _document = _document!.copyWith(
      annotations: _annotations,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 검색
  Future<void> search(String query) async {
    if (_document == null || query.isEmpty) {
      _searchQuery = null;
      _searchResults = [];
      _currentSearchIndex = -1;
      notifyListeners();
      return;
    }
    
    setLoading(true);
    
    try {
      _searchQuery = query;
      _searchResults = []; // 실제로는 PDF 내 텍스트 검색 결과의 페이지 번호 목록
      _currentSearchIndex = _searchResults.isNotEmpty ? 0 : -1;
      
      // 검색 결과가 있으면 첫 번째 결과로 이동
      if (_currentSearchIndex >= 0) {
        goToPage(_searchResults[_currentSearchIndex]);
      }
    } finally {
      setLoading(false);
    }
  }

  // 다음 검색 결과로 이동
  void nextSearchResult() {
    if (_searchResults.isEmpty || _currentSearchIndex < 0) return;
    
    _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    goToPage(_searchResults[_currentSearchIndex]);
  }

  // 이전 검색 결과로 이동
  void previousSearchResult() {
    if (_searchResults.isEmpty || _currentSearchIndex < 0) return;
    
    _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
    goToPage(_searchResults[_currentSearchIndex]);
  }

  // 검색 중지
  void stopSearch() {
    _searchQuery = null;
    _searchResults = [];
    _currentSearchIndex = -1;
    notifyListeners();
  }

  // 전체 화면 토글
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  // 야간 모드 토글
  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    _saveSettings();
    notifyListeners();
  }

  // 두 페이지 보기 토글
  void toggleTwoPageView() {
    _isTwoPageView = !_isTwoPageView;
    _saveSettings();
    notifyListeners();
  }

  // 문서 정보 업데이트
  Future<void> updateDocumentInfo(String title, String? description) async {
    if (_document == null) return;
    
    _document = _document!.copyWith(
      title: title,
      description: description,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 문서 페이지 수 업데이트
  Future<void> updateDocumentPageCount(int pageCount) async {
    if (_document == null || _document!.pageCount == pageCount) return;
    
    debugPrint('문서 페이지 수 업데이트: ${_document!.pageCount} -> $pageCount');
    
    _document = _document!.copyWith(
      pageCount: pageCount,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveDocument(_document!);
    notifyListeners();
  }

  // 로컬 파일로 PDF 저장
  Future<String?> saveToFile() async {
    if (_document == null) return null;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _document!.fileName;
      final targetPath = '${directory.path}/$fileName';
      
      // 원본 파일 복사
      final sourceFile = File(_document!.filePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        return targetPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('파일 저장 중 오류 발생: $e');
      return null;
    }
  }

  // 문서 삭제
  Future<bool> deleteDocument() async {
    if (_document == null) return false;
    
    try {
      await _repository.deleteDocument(_document!.id);
      _document = null;
      _annotations = [];
      _bookmarks = [];
      _currentPage = 1;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('문서 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// PDF 문서의 Firebase URL 업데이트
  Future<bool> updateDocumentUrl(String firebaseUrl) async {
    if (_document == null) return false;
    
    try {
      debugPrint('문서 URL 업데이트: $firebaseUrl');
      
      _document = _document!.copyWith(
        url: firebaseUrl,
        updatedAt: DateTime.now(),
      );
      
      await _repository.saveDocument(_document!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('문서 URL 업데이트 중 오류: $e');
      return false;
    }
  }
  
  /// Firebase URL에서 PDF 문서 가져오기
  Future<bool> loadDocumentFromFirebaseUrl(String firebaseUrl) async {
    try {
      setLoading(true);
      
      if (firebaseUrl.isEmpty || 
          (!firebaseUrl.startsWith('http://') && 
           !firebaseUrl.startsWith('https://') && 
           !firebaseUrl.startsWith('gs://'))) {
        throw Exception('유효하지 않은 Firebase URL: $firebaseUrl');
      }
      
      // URL에서 파일명 추출
      final filename = firebaseUrl.split('/').last.split('?').first;
      
      // 기존 문서 검색 (동일 URL)
      final documents = await _repository.getDocuments();
      final existingDoc = documents.firstWhere(
        (doc) => doc.url == firebaseUrl,
        orElse: () => throw Exception('No document found'),
      );
      
      if (existingDoc != null) {
        _document = existingDoc;
        _currentPage = 1;
        _loadAnnotationsAndBookmarks();
        await _repository.updateRecentDocument(existingDoc.id);
        notifyListeners();
        return true;
      }
      
      // 새 문서 생성
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: filename.replaceAll('.pdf', ''),
        fileName: filename,
        filePath: firebaseUrl, // 웹에서는 URL을 경로로 사용
        fileSize: 0, // 크기 알 수 없음
        pageCount: 1, // 기본값 (로드 후 업데이트)
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        url: firebaseUrl,
      );
      
      _document = document;
      _currentPage = 1;
      _annotations = [];
      _bookmarks = [];
      
      await _repository.saveDocument(document);
      await _repository.updateRecentDocument(document.id);
      
      return true;
    } catch (e) {
      debugPrint('Firebase URL에서 문서 로드 실패: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    // 필요한 클린업 코드
    super.dispose();
  }
} 