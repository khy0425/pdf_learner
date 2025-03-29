import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../screens/pdf_viewer_screen.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/base/result.dart';
import '../../domain/services/pdf_service.dart' as domain_pdf;
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/storage/storage_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/pdf/pdf_service.dart'; // PDF 서비스
import '../../core/utils/web_utils.dart';
import '../../core/utils/resource_manager.dart';
import '../../core/models/note.dart';
import '../../core/utils/conditional_file_picker.dart' as conditional;
import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';

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
  final domain_pdf.PDFService _pdfService;
  final FirebaseService _firebaseService;
  final AnalyticsService _analyticsService;
  final StorageService _storageService;
  
  PDFStatus _status = PDFStatus.initial;
  List<PDFDocument> _documents = [];
  List<PDFBookmark> _bookmarks = [];
  PDFDocument? _currentDocument;
  int _currentPage = 0;
  bool _isLoading = false;
  String? _error;
  
  // 게스트 모드 지원을 위한 변수
  bool _hasOpenDocument = false;
  bool _isGuestUser = false; // 미회원 사용자 여부
  
  final ResourceManager _resourceManager = ResourceManager();
  
  List<Note> _notes = [];
  List<String> _recentPdfs = [];
  Map<String, int> _lastReadPages = {};
  
  PDFViewModel({
    required PDFRepository repository,
    required domain_pdf.PDFService pdfService,
    required FirebaseService firebaseService,
    required AnalyticsService analyticsService,
    required StorageService storageService,
  })  : _repository = repository,
        _pdfService = pdfService,
        _firebaseService = firebaseService,
        _analyticsService = analyticsService,
        _storageService = storageService {
    // 웹 유틸리티 초기화
    if (!GetIt.instance.isRegistered<WebUtils>()) {
      WebUtils.registerSingleton();
    }
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    await loadDocuments();
  }
  
  // 게터
  PDFStatus get status => _status;
  List<PDFDocument> get documents => _documents;
  List<PDFBookmark> get bookmarks => _bookmarks;
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
      final webUtils = GetIt.I<WebUtils>();
      return webUtils.getRemainingDaysForPdf(fileId);
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
      final webUtils = GetIt.I<WebUtils>();
      return webUtils.isExpired(fileId);
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
      final webUtils = GetIt.I<WebUtils>();
      
      for (final doc in _documents) {
        if (webUtils.isExpired(doc.filePath)) {
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
      final result = await _repository.saveDocument(document);
      
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
          _bookmarks = [];
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
  
  @override
  Future<PDFDocument?> pickAndUploadPDF() async {
    setLoading();
    
    try {
      // 웹 환경인지 확인
      bool isWeb = kIsWeb;
      
      // 파일 선택
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
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
        totalPages: pageCount,
        fileSize: fileBytes?.length ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        currentPage: 0,
        readingProgress: 0.0,
        isFavorite: false,
        isSelected: false,
        readingTime: 0,
        status: PDFDocumentStatus.added,
        importance: PDFImportanceLevel.medium,
        securityLevel: PDFSecurityLevel.none,
        tags: [],
        metadata: {},
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
  Future<void> _savePdfBytesToStorage(String id, Uint8List pdfBytes) async {
    if (kIsWeb) {
      try {
        final webUtils = GetIt.I<WebUtils>();
        await webUtils.saveBytesToIndexedDB(id, pdfBytes);
      } catch (e) {
        debugPrint('IndexedDB 저장 오류: $e');
        _error = e.toString();
        notifyListeners();
      }
    } else {
      try {
        // 로컬 저장소에 저장
        final directory = await getApplicationDocumentsDirectory();
        final pdfPath = '${directory.path}/pdfs/$id.pdf';
        final file = File(pdfPath);
        
        // 디렉토리가 없으면 생성
        final dir = Directory('${directory.path}/pdfs');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        await file.writeAsBytes(pdfBytes);
      } catch (e) {
        debugPrint('파일 저장 오류: $e');
        _error = e.toString();
        notifyListeners();
      }
    }
  }
  
  @protected
  Future<Uint8List?> _getPdfBytesFromStorage(String id) async {
    if (kIsWeb) {
      try {
        final webUtils = GetIt.I<WebUtils>();
        return await webUtils.getBytesFromIndexedDB(id);
      } catch (e) {
        debugPrint('IndexedDB 로드 오류: $e');
        _error = e.toString();
        notifyListeners();
        return null;
      }
    } else {
      try {
        // 로컬 저장소에서 로드
        final directory = await getApplicationDocumentsDirectory();
        final pdfPath = '${directory.path}/pdfs/$id.pdf';
        final file = File(pdfPath);
        
        if (await file.exists()) {
          return await file.readAsBytes();
        }
        return null;
      } catch (e) {
        debugPrint('파일 로드 오류: $e');
        _error = e.toString();
        notifyListeners();
        return null;
      }
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
  
  /// 문서 즐겨찾기 토글
  Future<void> toggleFavorite(dynamic documentOrId) async {
    try {
      String id;
      
      // documentOrId가 PDFDocument인지 String인지 확인
      if (documentOrId is PDFDocument) {
        id = documentOrId.id;
      } else if (documentOrId is String) {
        id = documentOrId;
      } else {
        throw ArgumentError('문서 객체 또는 문서 ID를 전달해주세요.');
      }
      
      // 로컬 상태 업데이트
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index == -1) {
        debugPrint('문서를 찾을 수 없습니다: $id');
        return;
      }
      
      // 상태 토글
      final document = _documents[index];
      
      // 직접 새 PDFDocument 객체 생성
      final updatedDocument = PDFDocument(
        id: document.id,
        title: document.title,
        filePath: document.filePath,
        fileSize: document.fileSize,
        pageCount: document.pageCount,
        author: document.author,
        description: document.description,
        downloadUrl: document.downloadUrl,
        status: document.status,
        thumbnailPath: document.thumbnailPath,
        isFavorite: !document.isFavorite,
        createdAt: document.createdAt,
        updatedAt: DateTime.now(),
        lastAccessedAt: document.lastAccessedAt,
        lastReadPage: document.lastReadPage,
        currentPage: document.currentPage,
        totalPages: document.totalPages,
        readingProgress: document.readingProgress,
        tags: document.tags,
        accessLevel: document.accessLevel,
        category: document.category,
        isSelected: document.isSelected,
        importance: document.importance,
        securityLevel: document.securityLevel,
        source: document.source,
        metadata: document.metadata,
      );
      
      // 문서 목록 업데이트
      _documents[index] = updatedDocument;
      notifyListeners();
      
      // 저장소 업데이트
      final result = await _repository.updateDocument(updatedDocument);
      
      if (result.isFailure) {
        // 실패 시 롤백
        _documents[index] = document;
        notifyListeners();
        
        _setError('즐겨찾기 업데이트에 실패했습니다: ${result.error}');
      }
    } catch (e) {
      _setError('즐겨찾기 토글 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 문서 열림 상태를 설정합니다
  void setOpenDocument(bool isOpen) {
    _hasOpenDocument = isOpen;
    notifyListeners();
  }
  
  /// PDF 바이트 데이터 가져오기
  Future<Uint8List?> getPDFBytes(String filePath) async {
    try {
      // 웹 스토리지에서 데이터 가져오기 (web_ 접두사가 있는 경우)
      if (filePath.startsWith('web_')) {
        final webUtils = GetIt.I<WebUtils>();
        return await webUtils.getBytesFromIndexedDB(filePath);
      }
      
      // URL인 경우 다운로드
      if (filePath.startsWith('http')) {
        final tempDocument = PDFDocument(
          id: const Uuid().v4(),
          title: 'Downloaded PDF',
          filePath: '',
          downloadUrl: filePath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now()
        );
        
        final result = await _repository.downloadPdf(tempDocument);
        return result.isSuccess ? result.data : null;
      }
      
      // 로컬 파일 경로인 경우
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      
      debugPrint('PDF 파일을 찾을 수 없습니다: $filePath');
      return null;
    } catch (e) {
      debugPrint('PDF 바이트 데이터 가져오기 중 오류: $e');
      return null;
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
      _bookmarks = result.data!;
      notifyListeners();
    } else {
      _setError('북마크 로드 실패: ${result.error}');
    }
  }
  
  // Bookmark 관련 메소드
  Future<void> _loadBookmarks() async {
    try {
      final data = await _storageService.getJson('bookmarks');
      if (data != null) {
        final List<dynamic> bookmarkJsonList = data['bookmarks'] as List<dynamic>;
        _bookmarks = bookmarkJsonList
            .map((json) => PDFBookmark.fromMap(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('북마크 로드 오류: $e');
    }
  }
  
  /// 북마크 저장
  Future<void> _saveBookmarks() async {
    try {
      final data = {
        'bookmarks': _bookmarks.map((b) => b.toMap()).toList(),
      };
      await _storageService.setJson('bookmarks', data);
    } catch (e) {
      debugPrint('북마크 저장 오류: $e');
    }
  }
  
  // Note 관련 메소드
  Future<void> _loadNotes() async {
    try {
      final data = await _storageService.getJson('notes');
      if (data != null) {
        final List<dynamic> noteJsonList = data['notes'] as List<dynamic>;
        _notes = noteJsonList
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('노트 로드 오류: $e');
    }
  }
  
  /// 노트 저장
  Future<void> _saveNotes() async {
    try {
      final data = {
        'notes': _notes.map((n) => n.toJson()).toList(),
      };
      await _storageService.setJson('notes', data);
    } catch (e) {
      debugPrint('노트 저장 오류: $e');
    }
  }
  
  // 최근 본 PDF 관련 메소드
  Future<void> _loadRecentPdfs() async {
    try {
      final data = await _storageService.getJson('recent_pdfs');
      if (data != null) {
        final List<dynamic> recentPdfJsonList = data['recent_pdfs'] as List<dynamic>;
        _recentPdfs = recentPdfJsonList.cast<String>();
      }
    } catch (e) {
      debugPrint('최근 PDF 로드 오류: $e');
    }
  }
  
  /// 최근 PDF 저장
  Future<void> _saveRecentPdfs() async {
    try {
      final data = {
        'recent_pdfs': _recentPdfs,
      };
      await _storageService.setJson('recent_pdfs', data);
    } catch (e) {
      debugPrint('최근 PDF 저장 오류: $e');
    }
  }
  
  // 마지막으로 읽은 페이지 관련 메소드
  Future<void> _loadLastReadPages() async {
    try {
      final data = await _storageService.getJson('last_read_pages');
      if (data != null) {
        final Map<String, dynamic> lastReadMap = data['last_read_pages'] as Map<String, dynamic>;
        _lastReadPages = lastReadMap.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('마지막으로 읽은 페이지 로드 오류: $e');
    }
  }
  
  /// 마지막으로 읽은 페이지 저장
  Future<void> _saveLastReadPages() async {
    try {
      final data = {
        'last_read_pages': _lastReadPages,
      };
      await _storageService.setJson('last_read_pages', data);
    } catch (e) {
      debugPrint('마지막으로 읽은 페이지 저장 오류: $e');
    }
  }

  /// PDF 파일을 URL에서 추가
  Future<void> addPDFFromUrl(String url) async {
    if (url.isEmpty) {
      return;
    }
    
    _setLoading(true);
    
    try {
      // URL에서 PDF 다운로드
      final result = await _repository.downloadPdfFromUrl(url);
      
      if (result.isSuccess && result.data != null) {
        final bytes = result.data!;
        
        // 파일명 추출 (URL에서)
        String fileName = Uri.parse(url).pathSegments.last;
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName = '$fileName.pdf';
        }
        
        // 문서 생성
        final document = PDFDocument(
          id: const Uuid().v4(),
          title: fileName.replaceAll('.pdf', ''),
          description: '온라인 PDF',
          filePath: url,
          downloadUrl: url,
          pageCount: 0,
          currentPage: 1,
          readingProgress: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          isFavorite: false,
          isSelected: false,
          tags: [],
          fileSize: bytes.length,
        );
        
        // 문서 저장
        final saveResult = await _repository.saveDocument(document);
        
        if (saveResult.isSuccess) {
          // 문서 목록 새로고침
          await loadDocuments();
        } else {
          _setError('PDF 저장에 실패했습니다: ${saveResult.error}');
        }
      } else {
        throw Exception(result.error?.toString() ?? 'PDF 다운로드 실패');
      }
    } catch (e) {
      _setError('PDF 추가 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 문서 정렬
  List<PDFDocument> _sortDocumentsList(List<PDFDocument> documents, String sortBy, bool ascending) {
    switch (sortBy) {
      case 'title':
        documents.sort((a, b) => ascending 
            ? a.title.compareTo(b.title) 
            : b.title.compareTo(a.title));
        break;
      case 'date':
        documents.sort((a, b) {
          final DateTime aDate = a.createdAt ?? DateTime(1970);
          final DateTime bDate = b.createdAt ?? DateTime(1970);
          return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
        break;
      case 'lastOpened':
        documents.sort((a, b) {
          final DateTime aDate = a.lastAccessedAt ?? a.createdAt ?? DateTime(1970);
          final DateTime bDate = b.lastAccessedAt ?? b.createdAt ?? DateTime(1970);
          return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
        break;
      default:
        documents.sort((a, b) {
          final DateTime aDate = a.updatedAt ?? DateTime(1970);
          final DateTime bDate = b.updatedAt ?? DateTime(1970);
          return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
    }
    return documents;
  }
  
  /// 문서 정렬 (간단 버전) - document_list_screen.dart에서 사용
  void sortDocuments(String sortBy) {
    bool ascending = true;
    
    switch (sortBy) {
      case 'name':
        _documents = _sortDocumentsList(_documents, 'title', ascending);
        break;
      case 'date':
        _documents = _sortDocumentsList(_documents, 'date', false); // 최신순
        break;
      case 'favorite':
        // 즐겨찾기 항목 우선 정렬
        _documents.sort((a, b) => b.isFavorite ? 1 : -1);
        break;
      default:
        _documents = _sortDocumentsList(_documents, 'lastOpened', false); // 최근 열람순
    }
    
    notifyListeners();
  }

  /// 문서 목록 새로고침
  Future<void> refreshDocuments() async {
    await loadDocuments();
  }

  Future<void> _checkCacheSize() async {
    try {
      if (kIsWeb) {
        // 웹에서는 WebUtils의 cleanupExpiredFiles 메서드 호출
        final webUtils = GetIt.I<WebUtils>();
        webUtils.cleanupExpiredFiles();
      } else {
        // 네이티브에서는 캐시 디렉토리 정리
        // 직접 구현하거나 별도의 유틸리티 함수 사용
      }
    } catch (e) {
      debugPrint('캐시 크기 확인 오류: $e');
    }
  }

  /// 북마크 공유
  Future<Result<String>> shareBookmark(String id) async {
    try {
      final webUtils = GetIt.I<WebUtils>();
      
      // 북마크 가져오기
      final bookmark = _bookmarks.firstWhere((b) => b.id == id, orElse: () => throw Exception('북마크를 찾을 수 없습니다'));
      
      // 공유 URL 생성
      // PDF 파일을 클라우드에 업로드하고 공유 링크 반환
      return Result.success('https://example.com/shared/${bookmark.id}'); // 예시 URL
    } catch (e) {
      return Result.failure(Exception('북마크 공유 중 오류가 발생했습니다: $e'));
    }
  }

  /// 마지막으로 읽은 페이지 저장
  Future<void> saveLastReadPage(String documentId, int pageNumber) async {
    _lastReadPages[documentId] = pageNumber;
    await _saveLastReadPages();
    notifyListeners();
  }

  /// 북마크 생성 링크 가져오기
  Future<Result<String>> getBookmarkShareableLink(String id) async {
    try {
      // 북마크 찾기
      final bookmark = _bookmarks.firstWhere((b) => b.id == id, orElse: () => throw Exception('북마크를 찾을 수 없습니다'));
      
      // API를 통해 공유 링크 생성 (예시)
      // 실제로는 Firebase Dynamic Links 등을 사용해 공유 가능한 URL 생성
      return Result.success('https://example.com/shared/${bookmark.id}'); // 예시 URL
    } catch (e) {
      return Result.failure(Exception('공유 링크 생성 실패: $e'));
    }
  }
} 