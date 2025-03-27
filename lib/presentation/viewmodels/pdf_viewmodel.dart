import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/base/result.dart';
import '../../core/utils/resource_manager.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../services/firebase_service.dart';
import '../../services/analytics/analytics_service.dart';
import 'package:injectable/injectable.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/utils/web_storage_utils.dart';
import '../../core/models/bookmark.dart';
import '../../core/models/note.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/conditional_file_picker.dart';

/// PDF 상태
enum PDFStatus {
  initial,
  loading,
  success,
  error
}

/// PDF 뷰모델
@injectable
class PDFViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  final FirebaseService _firebaseService;
  final AnalyticsService _analyticsService;
  final StorageService _storageService;
  
  PDFStatus _status = PDFStatus.initial;
  List<PDFDocument> _documents = [];
  List<PDFBookmark> _pdfBookmarks = [];
  PDFDocument? _currentDocument;
  int _currentPage = 0;
  bool _isLoading = false;
  String? _error;
  
  // 게스트 모드 지원을 위한 변수
  bool _hasOpenDocument = false;
  bool _isGuestUser = false; // 미회원 사용자 여부
  
  final ResourceManager _resourceManager = ResourceManager();
  
  List<Bookmark> _bookmarks = [];
  List<Note> _notes = [];
  List<String> _recentPdfs = [];
  Map<String, int> _lastReadPages = {};
  
  PDFViewModel({
    required PDFRepository repository,
    required FirebaseService firebaseService,
    required AnalyticsService analyticsService,
    required StorageService storageService,
  })  : _repository = repository,
        _firebaseService = firebaseService,
        _analyticsService = analyticsService,
        _storageService = storageService {
    _loadBookmarks();
    _loadNotes();
    _loadRecentPdfs();
    _loadLastReadPages();
  }
  
  // 게터
  PDFStatus get status => _status;
  List<PDFDocument> get documents => _documents;
  List<PDFBookmark> get bookmarks => _pdfBookmarks;
  PDFDocument? get currentDocument => _currentDocument;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOpenDocument => _hasOpenDocument;
  bool get isGuestUser => _isGuestUser; // 미회원 사용자 상태 게터
  
  // 현재 선택된 PDF 문서
  PDFDocument? get document => _currentDocument;
  
  /// 미회원 상태 설정
  void setGuestUser(bool isGuest) {
    _isGuestUser = isGuest;
    notifyListeners();
  }
  
  /// 현재 문서의 만료 일수 가져오기 (미회원만 해당)
  int? getCurrentDocumentExpirationDays() {
    if (!_isGuestUser || _currentDocument == null) return null;
    
    try {
      final fileId = _currentDocument!.filePath;
      return WebStorageUtils.getRemainingDaysForPdf(fileId);
    } catch (e) {
      debugPrint('만료일 계산 오류: $e');
      return null;
    }
  }
  
  /// 현재 문서가 만료되었는지 확인 (미회원만 해당)
  bool isCurrentDocumentExpired() {
    if (!_isGuestUser || _currentDocument == null) return false;
    
    try {
      final fileId = _currentDocument!.filePath;
      return WebStorageUtils.isExpired(fileId);
    } catch (e) {
      debugPrint('만료 확인 오류: $e');
      return false;
    }
  }
  
  /// 모든 만료된 문서 제거
  Future<void> cleanupExpiredDocuments() async {
    if (!_isGuestUser) return;
    
    try {
      // 만료된 문서 필터링
      final expiredDocIds = <String>[];
      
      for (final doc in _documents) {
        if (WebStorageUtils.isExpired(doc.filePath)) {
          expiredDocIds.add(doc.id);
        }
      }
      
      // 만료된 문서 삭제
      for (final docId in expiredDocIds) {
        await deleteDocument(docId);
      }
      
      if (expiredDocIds.isNotEmpty) {
        debugPrint('만료된 문서 ${expiredDocIds.length}개 정리 완료');
      }
    } catch (e) {
      debugPrint('만료 문서 정리 중 오류: $e');
    }
  }
  
  /// PDF 문서 목록 가져오기
  Future<void> loadDocuments() async {
    _setStatus(PDFStatus.loading);

    try {
      // 미회원 사용자인 경우 만료된 문서 정리
      if (_isGuestUser) {
        await cleanupExpiredDocuments();
      }
      
      final result = await _repository.getDocuments();
      if (result.isSuccess) {
        _documents = result.data ?? [];
        _setStatus(PDFStatus.success);
      } else {
        _setStatus(PDFStatus.error);
      }
    } catch (e) {
      _setStatus(PDFStatus.error);
    }
  }

  /// 특정 문서 가져오기
  Future<Result<PDFDocument>> loadDocument(String documentId) async {
    setLoading();

    try {
      final result = await _repository.getDocument(documentId);
      
      if (result.isSuccess) {
        _currentDocument = result.getOrNull();
        setLoaded();
        return Result.success(_currentDocument!);
      } else {
        setError(result.error?.toString() ?? "문서 로드 실패");
        return Result.failure(Exception("문서 로드 실패"));
      }
    } catch (e) {
      setError(e.toString());
      return Result.failure(Exception(e.toString()));
    }
  }
  
  Future<void> createDocument(PDFDocument document) async {
    setLoading();
    
    try {
      final result = await _repository.createDocument(document);
      
      if (result.isSuccess) {
        await loadDocuments();
      } else {
        setError(result.error?.toString() ?? "문서 생성 실패");
      }
    } catch (e) {
      setError(e.toString());
    }
  }
  
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    setLoading();
    
    try {
      final result = await _repository.updateDocument(document);
      
      if (result.isSuccess) {
        // 현재 문서 업데이트
        if (_currentDocument?.id == document.id) {
          _currentDocument = document;
        }
        
        // 문서 목록 업데이트
        final index = _documents.indexWhere((doc) => doc.id == document.id);
        if (index != -1) {
          _documents[index] = document;
        }
        
        setLoaded();
        return Result.success(document);
      } else {
        setError(result.error?.toString() ?? "문서 업데이트 실패");
        return Result.failure(result.error ?? Exception("문서 업데이트 실패"));
      }
    } catch (e) {
      setError(e.toString());
      return Result.failure(Exception(e.toString()));
    }
  }
  
  Future<void> deleteDocument(String id) async {
    setLoading();
    
    try {
      final result = await _repository.deleteDocument(id);
      
      if (result.isSuccess) {
        // 현재 문서인 경우 초기화
        if (_currentDocument?.id == id) {
          _currentDocument = null;
          _pdfBookmarks = [];
          _currentPage = 0;
        }
        
        // 문서 목록에서 제거
        _documents.removeWhere((doc) => doc.id == id);
        
        setLoaded();
      } else {
        setError(result.error?.toString() ?? "문서 삭제 실패");
      }
    } catch (e) {
      setError(e.toString());
    }
  }
  
  Future<PDFDocument?> pickAndUploadPDF() async {
    setLoading();
    
    try {
      // 웹 환경인지 확인
      bool isWeb = kIsWeb;
      
      // 파일 선택
      FilePickerResult? result = await ConditionalFilePicker.pickFiles(
        type: FilePickerType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result == null || result.files.isEmpty) {
        setLoaded();
        return null;
      }
      
      final file = result.files.first;
      
      // 파일 정보 처리
      String fileName = file.name;
      String? filePath;
      int pageCount = 0;
      Uint8List? fileBytes;
      
      if (isWeb) {
        // 웹 환경에서는 파일 바이트 데이터 사용
        fileBytes = file.bytes;
        if (fileBytes == null) {
          setError('파일 데이터를 읽을 수 없습니다.');
          return null;
        }
        
        // 웹에서는 메모리에 있는 데이터로 페이지 수 계산
        pageCount = await _getPdfPageCount(fileBytes);
        
        // 파일 경로 대신 고유 ID 생성 (파일명 포함)
        filePath = 'web_${DateTime.now().millisecondsSinceEpoch}_${fileName}';
        
        // 웹 환경에서 바이트 데이터 저장 (로컬 스토리지나 IndexedDB 등)
        await _savePdfBytesToStorage(filePath, fileBytes);
      } else {
        // 네이티브 환경에서 파일 시스템 사용
        filePath = file.path;
        if (filePath == null) {
          setError('파일 경로를 가져올 수 없습니다.');
          return null;
        }
        
        // 로컬 파일 정보 읽기
        final pdfFile = File(filePath);
        fileBytes = await pdfFile.readAsBytes();
        
        // 페이지 수 계산
        pageCount = await _getPdfPageCount(fileBytes);
      }
      
      // PDF 문서 객체 생성
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: fileName.replaceAll('.pdf', ''),
        description: '',
        filePath: filePath ?? '',
        pageCount: pageCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentPage: 0,
        readingProgress: 0.0,
        isFavorite: false,
        isSelected: false,
        readingTime: 0,
        status: PDFDocumentStatus.created,
        importance: PDFDocumentImportance.medium,
        securityLevel: PDFDocumentSecurityLevel.none,
        tags: [],
        bookmarks: [],
        metadata: {},
        fileSize: fileBytes?.length ?? 0,
      );
      
      // 문서 저장
      await createDocument(document);
      
      // 리소스 관리
      _resourceManager.cacheBytes('pdf_${document.id}', fileBytes);
      
      setLoaded();
      return document;
    } catch (e) {
      setError('PDF 선택 및 업로드 중 오류 발생: $e');
      return null;
    }
  }
  
  @protected
  Future<int> _getPdfPageCount(Uint8List bytes) async {
    try {
      // Syncfusion PDF 라이브러리 사용
      final PdfDocument pdfDocument = PdfDocument(inputBytes: bytes);
      final pageCount = pdfDocument.pages.count;
      pdfDocument.dispose(); // 메모리 해제
      return pageCount;
    } catch (e) {
      debugPrint('PDF 페이지 수 계산 중 오류: $e');
      return 0;
    }
  }
  
  @protected
  Future<void> _savePdfBytesToStorage(String filePath, Uint8List bytes) async {
    try {
      // 웹 환경에서 바이트 데이터 저장
      await WebStorageUtils.saveBytesToIndexedDB(filePath, bytes, isGuest: _isGuestUser);
      debugPrint('PDF 저장 성공: $filePath (${bytes.length} 바이트)${_isGuestUser ? " (미회원 임시 저장)" : ""}');
    } catch (e) {
      debugPrint('PDF 저장 오류: $e');
      setError('PDF 저장 오류: $e');
    }
  }
  
  @override
  void dispose() {
    _resourceManager.clearCache();
    super.dispose();
  }
  
  void setSelectedDocument(PDFDocument document) {
    _currentDocument = document;
    _hasOpenDocument = true;
    notifyListeners();
  }
  
  void clearSelectedDocument() {
    _currentDocument = null;
    _hasOpenDocument = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// PDF 파일을 선택하고 추가합니다
  Future<void> pickAndAddPDF() async {
    try {
      final document = await pickAndUploadPDF();
      if (document != null) {
        loadDocuments(); // 문서 목록 새로고침
        setSelectedDocument(document); // 선택한 문서 설정
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 즐겨찾기 상태를 토글합니다
  Future<void> toggleFavorite(String documentId) async {
    try {
      // 현재 문서 찾기
      final documentIndex = _documents.indexWhere((doc) => doc.id == documentId);
      if (documentIndex == -1) return;
      
      final document = _documents[documentIndex];
      final updatedDocument = document.copyWith(
        isFavorite: !document.isFavorite,
      );
      
      // 즉시 UI 업데이트를 위해 로컬 상태 변경
      _documents[documentIndex] = updatedDocument;
      notifyListeners();
      
      // 백엔드 업데이트
      await updateDocument(updatedDocument);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 문서 열림 상태를 설정합니다
  void setOpenDocument(bool isOpen) {
    _hasOpenDocument = isOpen;
    notifyListeners();
  }
  
  /// 스토리지에서 PDF 데이터 가져오기
  Future<Uint8List?> getPdfBytesFromStorage(String filePath) async {
    try {
      // 웹 스토리지에서 데이터 가져오기 (web_ 접두사가 있는 경우)
      if (filePath.startsWith('web_')) {
        try {
          // 미회원 문서가 만료되었는지 확인
          if (_isGuestUser && WebStorageUtils.isExpired(filePath)) {
            debugPrint('미회원 PDF가 만료되었습니다: $filePath');
            setError('저장된 PDF가 만료되었습니다. 회원가입 후 영구적으로 저장할 수 있습니다.');
            // 만료된 데이터 삭제
            await WebStorageUtils.deleteBytesFromIndexedDB(filePath);
            return null;
          }
          
          final bytes = await WebStorageUtils.getBytesFromIndexedDB(filePath);
          if (bytes != null) {
            debugPrint('IndexedDB에서 PDF 로드 성공: $filePath');
            
            // 미회원 사용자면 만료 정보 로그
            if (_isGuestUser) {
              final days = WebStorageUtils.getRemainingDaysForPdf(filePath);
              debugPrint('미회원 PDF 만료까지 $days일 남음: $filePath');
            }
            
            return bytes;
          } else {
            debugPrint('IndexedDB에서 PDF를 찾을 수 없음, 샘플 PDF 로드: $filePath');
            // 친절한 오류 메시지 표시
            setError('저장된 PDF를 찾을 수 없어 샘플 PDF를 로드합니다.');
            // 샘플 PDF 로드
            return await loadSamplePdf();
          }
        } catch (e) {
          debugPrint('웹 스토리지에서 PDF 로드 오류: $e');
          setError('PDF 로드 중 오류가 발생하여 샘플 PDF를 로드합니다.');
          // 오류 발생 시 샘플 PDF 로드
          return await loadSamplePdf();
        }
      }
      
      // 일반 경로인 경우 리포지토리에서 다운로드
      final result = await _repository.downloadPdf(filePath);
      
      if (result.isSuccess) {
        return result.data;
      } else {
        setError('${result.error?.toString() ?? "PDF 다운로드 실패"}, 샘플 PDF를 로드합니다.');
        // 다운로드 실패 시 샘플 PDF 로드
        return await loadSamplePdf();
      }
    } catch (e) {
      setError('$e, 샘플 PDF를 로드합니다.');
      // 오류 발생 시 샘플 PDF 로드
      return await loadSamplePdf();
    }
  }
  
  /// 샘플 PDF 로드하기
  Future<Uint8List?> loadSamplePdf() async {
    try {
      // 원격 URL에서 샘플 PDF 다운로드
      const sampleUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
      
      final response = await http.get(Uri.parse(sampleUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        setError('샘플 PDF를 로드할 수 없습니다. 상태 코드: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      setError('샘플 PDF 로드 중 오류 발생: $e');
      return null;
    }
  }
  
  // 상태 변경 헬퍼 메서드
  void setLoading() {
    _setLoading(true);
  }
  
  void setLoaded() {
    _setLoading(false);
  }
  
  void setError(String message) {
    _setError(message);
  }
  
  void setStatus(PDFStatus status) {
    _setStatus(status);
  }
  
  void _setStatus(PDFStatus status) {
    _status = status;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _setStatus(PDFStatus.loading);
    }
    notifyListeners();
  }
  
  // 북마크 로드
  Future<void> loadBookmarks(String documentId) async {
    _error = null;
    
    final result = await _repository.getBookmarks(documentId);
    
    if (result.isSuccess) {
      _pdfBookmarks = result.data!;
      notifyListeners();
    } else {
      _setError('북마크 로드 실패: ${result.error}');
    }
  }
  
  /// PDF 북마크 추가 (리포지토리)
  Future<Result<PDFBookmark>> _addPdfBookmark(PDFBookmark bookmark) async {
    setLoading();
    
    try {
      final result = await _repository.createBookmark(bookmark);
      
      if (result.isSuccess) {
        // 로컬 북마크 목록 업데이트
        final index = _pdfBookmarks.indexWhere((bm) => bm.id == bookmark.id);
        
        if (index >= 0) {
          _pdfBookmarks[index] = result.data!;
        } else {
          _pdfBookmarks.add(result.data!);
        }
        
        setLoaded();
        return Result.success(result.data!);
      } else {
        setError(result.error?.toString() ?? "북마크 추가 실패");
        return Result.failure(result.error ?? Exception("북마크 추가 실패"));
      }
    } catch (e) {
      setError(e.toString());
      return Result.failure(Exception(e.toString()));
    }
  }
  
  /// 북마크 추가 (로컬 저장소)
  Future<void> addLocalBookmark(String pdfPath, int page, {String? title, String? description}) async {
    // 현재 시간으로 북마크 생성
    final newBookmark = Bookmark(
      pdfPath: pdfPath,
      page: page,
      createdAt: DateTime.now(),
      title: title ?? 'Page $page',
      description: description,
    );
    
    // 이미 같은 페이지에 북마크가 있는지 확인
    final existingBookmark = _bookmarks.any(
      (bookmark) => bookmark.pdfPath == pdfPath && bookmark.page == page
    );
    
    if (!existingBookmark) {
      _bookmarks.add(newBookmark);
      await _saveBookmarks();
      notifyListeners();
    }
  }
  
  /// 북마크 삭제 (로컬 저장소)
  Future<void> removeLocalBookmark(String pdfPath, int page) async {
    _bookmarks.removeWhere((b) => b.pdfPath == pdfPath && b.page == page);
    await _saveBookmarks();
    notifyListeners();
  }
  
  // 북마크 삭제
  Future<void> deleteBookmark(String bookmarkId) async {
    _error = null;
    
    final result = await _repository.deleteBookmark(bookmarkId);
    
    if (result.isSuccess) {
      // 로컬 북마크 목록에서 제거
      _pdfBookmarks.removeWhere((bm) => bm.id == bookmarkId);
      notifyListeners();
    } else {
      _setError('북마크 삭제 실패: ${result.error}');
    }
  }
  
  // 현재 페이지 설정
  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      
      // 현재 문서가 있으면 마지막 읽은 페이지 저장
      if (_currentDocument != null) {
        saveLastReadPage(_currentDocument!.id, page);
      }
      
      notifyListeners();
    }
  }
  
  // 마지막으로 읽은 페이지 로드
  Future<void> loadLastReadPage(String documentId) async {
    final result = await _repository.getLastReadPage(documentId);
    
    if (result.isSuccess) {
      _currentPage = result.data!;
      notifyListeners();
    }
  }
  
  /// 마지막으로 읽은 페이지 저장 (리포지토리)
  Future<void> _saveRepositoryLastReadPage(String documentId, int page) async {
    await _repository.saveLastReadPage(documentId, page);
    
    // 로컬 상태 업데이트
    _currentPage = page;
    notifyListeners();
  }
  
  /// 마지막으로 읽은 페이지 저장
  Future<void> saveLastReadPage(String pdfPath, int page) async {
    // 리포지토리에 저장 (ID 형식이 맞는 경우)
    if (_currentDocument != null && _currentDocument!.id == pdfPath) {
      await _saveRepositoryLastReadPage(pdfPath, page);
    }
    
    // 로컬 맵에 저장
    _lastReadPages[pdfPath] = page;
    
    // SharedPreferences에 저장
    await _saveLastReadPages();
    
    // 현재 페이지 갱신
    _currentPage = page;
    notifyListeners();
  }
  
  /// URL에서 PDF 다운로드
  Future<Uint8List?> downloadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        setError('PDF 다운로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      setError('PDF 다운로드 중 오류: $e');
      return null;
    }
  }
  
  /// 로컬 PDF 파일 로드
  Future<Uint8List?> loadLocalPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        setError('파일을 찾을 수 없습니다: $filePath');
        return null;
      }
    } catch (e) {
      setError('로컬 PDF 로드 중 오류: $e');
      return null;
    }
  }
  
  // Bookmark 관련 메소드
  Future<void> _loadBookmarks() async {
    _setLoading(true);
    try {
      final data = await _storageService.read('bookmarks');
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        _bookmarks = decoded.map((e) => Bookmark.fromJson(e)).toList();
      }
    } catch (e) {
      _setError('북마크 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _saveBookmarks() async {
    try {
      final data = json.encode(_bookmarks.map((e) => e.toJson()).toList());
      await _storageService.write('bookmarks', data);
    } catch (e) {
      _setError('북마크 저장 중 오류 발생: $e');
    }
  }
  
  // Note 관련 메소드
  Future<void> _loadNotes() async {
    _setLoading(true);
    try {
      final data = await _storageService.read('notes');
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        _notes = decoded.map((e) => Note.fromJson(e)).toList();
      }
    } catch (e) {
      _setError('노트 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> addNote(String pdfPath, int page, String content) async {
    final note = Note(
      pdfPath: pdfPath,
      page: page,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 동일한 PDF, 페이지에 이미 노트가 있는지 확인
    final existingIndex = _notes.indexWhere(
      (n) => n.pdfPath == pdfPath && n.page == page
    );
    
    if (existingIndex >= 0) {
      // 기존 노트 업데이트
      _notes[existingIndex] = _notes[existingIndex].copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
    } else {
      // 새 노트 추가
      _notes.add(note);
    }
    
    await _saveNotes();
    notifyListeners();
  }
  
  Future<void> removeNote(String pdfPath, int page) async {
    _notes.removeWhere((n) => n.pdfPath == pdfPath && n.page == page);
    await _saveNotes();
    notifyListeners();
  }
  
  Future<void> _saveNotes() async {
    try {
      final data = json.encode(_notes.map((e) => e.toJson()).toList());
      await _storageService.write('notes', data);
    } catch (e) {
      _setError('노트 저장 중 오류 발생: $e');
    }
  }
  
  // 최근 본 PDF 관련 메소드
  Future<void> _loadRecentPdfs() async {
    _setLoading(true);
    try {
      final data = await _storageService.read('recent_pdfs');
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        _recentPdfs = List<String>.from(decoded);
      }
    } catch (e) {
      _setError('최근 PDF 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> addRecentPdf(String pdfPath) async {
    // 이미 있으면 제거 후 맨 앞에 추가
    _recentPdfs.remove(pdfPath);
    _recentPdfs.insert(0, pdfPath);
    
    // 최대 10개만 유지
    if (_recentPdfs.length > 10) {
      _recentPdfs = _recentPdfs.sublist(0, 10);
    }
    
    await _saveRecentPdfs();
    notifyListeners();
  }
  
  Future<void> _saveRecentPdfs() async {
    try {
      final data = json.encode(_recentPdfs);
      await _storageService.write('recent_pdfs', data);
    } catch (e) {
      _setError('최근 PDF 저장 중 오류 발생: $e');
    }
  }
  
  // 마지막으로 읽은 페이지 관련 메소드
  Future<void> _loadLastReadPages() async {
    _setLoading(true);
    try {
      final data = await _storageService.read('last_read_pages');
      if (data != null) {
        final Map<String, dynamic> decoded = json.decode(data);
        _lastReadPages = decoded.map(
          (key, value) => MapEntry(key, value as int)
        );
      }
    } catch (e) {
      _setError('마지막 읽은 페이지 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _saveLastReadPages() async {
    try {
      final data = json.encode(_lastReadPages);
      await _storageService.write('last_read_pages', data);
    } catch (e) {
      _setError('마지막 읽은 페이지 저장 중 오류 발생: $e');
    }
  }
  
  // PDF 파일 가져오기 메소드
  Future<List<FileSystemEntity>> getPdfFiles() async {
    _setLoading(true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final entities = await FileUtils.getPdfFiles(directory.path);
      return entities;
    } catch (e) {
      _setError('PDF 파일 로드 중 오류 발생: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
} 