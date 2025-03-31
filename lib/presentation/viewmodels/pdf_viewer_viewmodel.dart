import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/base/base_viewmodel.dart';
import '../../core/base/result.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/pdf/pdf_service.dart';
import '../../data/datasources/pdf_local_data_source.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pdf_viewmodel.dart';

/// PDF 문서 뷰어 상태
enum PDFViewerStatus {
  /// 초기 상태
  initial,
  
  /// 문서 로딩 중
  loading,
  
  /// 문서 로드 성공
  success,
  
  /// 문서 로드 오류
  error,
}

/// PDF 뷰어 뷰모델
@injectable
class PDFViewerViewModel extends BaseViewModel {
  /// PDF 리포지토리
  final PDFRepository _repository;
  
  /// PDF 서비스
  final PDFService _pdfService;
  
  /// PDF 로컬 데이터 소스
  final PDFLocalDataSource _localDataSource;
  
  /// PDF 뷰모델
  final PDFViewModel _pdfViewModel;
  
  /// 인증 뷰모델
  final AuthViewModel _authViewModel;
  
  /// 현재 PDF 문서
  PDFDocument? _document;
  
  /// 문서 ID
  final String? _documentId;
  
  /// 북마크 목록
  List<PDFBookmark> _bookmarks = [];
  
  /// 현재 페이지
  int _currentPage = 0;
  
  /// 총 페이지 수
  int _totalPages = 0;
  
  /// 선택된 텍스트
  String _selectedText = '';
  
  /// 선택된 페이지
  int _selectedPage = 0;
  
  /// 노트 목록
  List<PDFBookmark> _notes = [];
  
  /// 뷰어 상태
  PDFViewerStatus _status = PDFViewerStatus.initial;
  
  /// 에러 메시지
  String _errorMessage = '';
  
  bool _isFullScreen = false;
  bool _isBookmarksVisible = false;
  
  /// 생성자
  PDFViewerViewModel({
    required PDFRepository pdfRepository,
    required PDFViewModel pdfViewModel,
    required AuthViewModel authViewModel,
    required PDFService pdfService,
    required PDFLocalDataSource localDataSource,
    PDFDocument? initialDocument,
    String? documentId,
  })  : _repository = pdfRepository,
        _pdfViewModel = pdfViewModel,
        _authViewModel = authViewModel,
        _pdfService = pdfService,
        _localDataSource = localDataSource,
        _document = initialDocument,
        _documentId = documentId {
    _initialize();
  }
  
  /// 현재 문서 getter
  PDFDocument? get document => _document;
  
  /// 북마크 목록 getter
  List<PDFBookmark> get bookmarks => _bookmarks;
  
  /// 현재 페이지 getter
  int get currentPage => _currentPage;
  
  /// 총 페이지 수 getter
  int get totalPages => _totalPages;
  
  /// 뷰어 상태 getter
  PDFViewerStatus get status => _status;
  
  /// 에러 메시지 getter
  @override
  String get errorMessage => _errorMessage;
  
  bool get isFullScreen => _isFullScreen;
  bool get isBookmarksVisible => _isBookmarksVisible;
  
  /// AuthViewModel getter
  AuthViewModel get authViewModel => _authViewModel;
  
  /// 현재 사용자
  User? get currentUser => _authViewModel.currentUser != null 
      ? FirebaseAuth.instance.currentUser 
      : null;
  
  /// 게스트 모드 여부
  bool get isGuestMode => _authViewModel.isGuestMode;
  
  /// 로그인한 사용자 여부
  bool get hasAuthUser => _authViewModel.currentUser != null;
  
  /// 전체 화면 모드 설정
  void setFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }
  
  /// 북마크 패널 표시 여부 설정
  void setBookmarksVisible(bool value) {
    _isBookmarksVisible = value;
    notifyListeners();
  }
  
  /// 광고 시청 후 보상
  Future<void> rewardAfterAd() async {
    await _authViewModel.rewardAfterAd();
  }
  
  /// 현재 페이지 저장
  Future<void> saveCurrentPage(int page) async {
    if (_document == null || page <= 0) return;
    
    _currentPage = page;
    
    // 문서 정보 업데이트
    final updatedDocument = _document!.copyWith(currentPage: page);
    _document = updatedDocument;
    
    // 저장
    await _pdfViewModel.updateDocument(updatedDocument);
    
    notifyListeners();
  }
  
  /// PDF 파일 로드하기
  Future<Uint8List> loadPdf() async {
    if (_document == null) {
      throw Exception('문서가 로드되지 않았습니다.');
    }
    
    try {
      final result = await _pdfService.loadPdf(_document!.filePath);
      return result;
    } catch (e) {
      throw Exception('PDF 로드 실패: $e');
    }
  }
  
  /// 즐겨찾기 토글
  Future<Result<PDFDocument>> toggleFavorite() async {
    if (_document == null) {
      return Result.failure(Exception('문서가 없습니다.'));
    }
    
    try {
      // 상태 반전
      final updatedDocument = _document!.copyWith(
        isFavorite: !(_document!.isFavorite),
        updatedAt: DateTime.now(),
      );
      
      // 저장
      final result = await _pdfViewModel.updateDocument(updatedDocument);
      if (result.isSuccess) {
        _document = updatedDocument;
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      return Result.failure(Exception(e.toString()));
    }
  }
  
  /// 북마크 추가하기
  Future<Result<PDFBookmark>> addBookmark({
    required String title,
    required String note,
    required String selectedText,
    required int page,
  }) async {
    if (_document == null) {
      return Result.failure(Exception('문서가 없습니다.'));
    }
    
    try {
      // 북마크 생성
      final bookmark = PDFBookmark(
        id: const Uuid().v4(),
        documentId: _document!.id,
        title: title,
        note: note,
        page: page,
        textContent: selectedText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 북마크 저장
      final result = await _repository.saveBookmark(bookmark);
      
      if (result.isSuccess) {
        _bookmarks.add(result.data!);
        notifyListeners();
        return Result.success(result.data!);
      } else {
        return Result.failure(result.error ?? Exception('북마크 저장 실패'));
      }
    } catch (e) {
      return Result.failure(Exception(e.toString()));
    }
  }
  
  /// AI 기능 사용 처리 메서드
  void useSummarize() {
    if (_authViewModel.isGuestMode) {
      _authViewModel.useSummarize();
    }
  }
  
  void useChat() {
    if (_authViewModel.isGuestMode) {
      _authViewModel.useChat();
    }
  }
  
  void useQuiz() {
    if (_authViewModel.isGuestMode) {
      _authViewModel.useQuiz();
    }
  }
  
  void useMindmap() {
    if (_authViewModel.isGuestMode) {
      _authViewModel.useMindmap();
    }
  }
  
  /// 문서 로드
  Future<Result<PDFDocument?>> loadDocument(String documentId) async {
    _setStatus(PDFViewerStatus.loading);
    
    try {
      final documentResult = await _repository.getDocument(documentId);
      
      if (documentResult.isSuccess) {
        _document = documentResult.getOrNull();
        
        if (_document != null) {
          await _loadDocumentData();
          await _loadBookmarks();
          _currentPage = await _loadLastReadPage();
          _setSuccess();
          return Result.success(_document);
        } else {
          _setError('문서를 찾을 수 없습니다.');
          return Result.failure(Exception('문서를 찾을 수 없습니다.'));
        }
      } else {
        final error = documentResult.error ?? Exception('문서 로드 실패');
        _setError(error.toString());
        return Result.failure(error);
      }
    } catch (e) {
      _setError('문서 로드 중 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  /// 문서 상세 데이터 로드
  Future<void> _loadDocumentData() async {
    if (_document == null) return;
    
    // 문서의 총 페이지 수 확인
    if (_document!.pageCount <= 0) {
      try {
        final int pageCount = await _pdfService.getPageCount(_document!.filePath);
        if (pageCount > 0) {
          _totalPages = pageCount;
          _document = _document!.copyWith(pageCount: pageCount);
          await _repository.saveDocument(_document!);
        }
      } catch (e) {
        debugPrint('PDF 페이지 수 확인 실패: $e');
      }
    } else {
      _totalPages = _document!.pageCount;
    }
  }
  
  /// 마지막으로 읽은 페이지 로드
  Future<int> _loadLastReadPage() async {
    if (_document == null) return 0;
    
    try {
      final result = await _localDataSource.getLastReadPage(_document!.id);
      if (result.isSuccess) {
        final lastReadPage = result.data;
        if (lastReadPage > 0 && lastReadPage <= _totalPages) {
          _currentPage = lastReadPage;
          return lastReadPage;
        }
      }
      // 유효한 페이지를 가져오지 못하면 첫 페이지로 설정
      _currentPage = 1;
      return 1;
    } catch (e) {
      // 오류 발생 시 첫 페이지로 설정
      debugPrint('마지막 읽은 페이지 로드 오류: $e');
      _currentPage = 1;
      return 1;
    }
  }
  
  /// 문서의 모든 북마크 로드
  Future<void> loadBookmarks() async {
    if (_document == null) return;
    
    _setStatus(PDFViewerStatus.loading);
    _errorMessage = '';
    
    try {
      final bookmarksResult = await _repository.getBookmarks(_document!.id);
      
      if (bookmarksResult.isSuccess) {
        _bookmarks = bookmarksResult.data ?? [];
        notifyListeners();
      } else {
        _setError(bookmarksResult.error?.toString() ?? '북마크 로드 실패');
      }
    } catch (e) {
      _setError('북마크 로드 오류: $e');
    } finally {
      _setStatus(PDFViewerStatus.success);
    }
  }
  
  /// 북마크 생성하기
  Future<void> createBookmark(PDFBookmark bookmark) async {
    _setStatus(PDFViewerStatus.loading);
    _errorMessage = '';
    
    try {
      final result = await _repository.saveBookmark(bookmark);
      
      if (result.isSuccess) {
        _bookmarks.add(result.data!);
        notifyListeners();
      } else {
        _setError(result.error?.toString() ?? '북마크 생성 실패');
      }
    } catch (e) {
      _setError('북마크 생성 오류: $e');
    } finally {
      _setStatus(PDFViewerStatus.success);
    }
  }
  
  /// 북마크 삭제하기
  Future<void> deleteBookmark(String bookmarkId) async {
    _setStatus(PDFViewerStatus.loading);
    _errorMessage = '';
    
    try {
      final result = await _repository.deleteBookmark(bookmarkId);
      
      if (result.isSuccess) {
        _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
        notifyListeners();
      } else {
        _setError(result.error?.toString() ?? '북마크 삭제 실패');
      }
    } catch (e) {
      _setError('북마크 삭제 오류: $e');
    } finally {
      _setStatus(PDFViewerStatus.success);
    }
  }
  
  /// 상태 설정
  void _setStatus(PDFViewerStatus status) {
    _status = status;
    
    switch (status) {
      case PDFViewerStatus.loading:
        setLoading(true);
        break;
      case PDFViewerStatus.success:
        setLoading(false);
        clearError();
        break;
      case PDFViewerStatus.error:
        // 오류는 _setError 메서드에서 처리됩니다.
        break;
      case PDFViewerStatus.initial:
        resetState();
        break;
    }
    
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String message) {
    _status = PDFViewerStatus.error;
    setError(message);
  }
  
  /// 성공 상태 설정
  void _setSuccess() {
    _status = PDFViewerStatus.success;
    _errorMessage = '';
    notifyListeners();
  }
  
  /// 페이지 변경
  Future<void> changePage(int page) async {
    if (_document == null || page < 1 || page > _totalPages) return;
    
    _currentPage = page;
    await _saveLastReadPage();
    notifyListeners();
  }
  
  /// 다음 페이지로 이동
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await changePage(_currentPage + 1);
    }
  }
  
  /// 이전 페이지로 이동
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await changePage(_currentPage - 1);
    }
  }
  
  /// 마지막으로 읽은 페이지 저장
  Future<void> _saveLastReadPage() async {
    if (_document == null) return;
    
    try {
      final result = await _localDataSource.saveLastReadPage(_document!.id, _currentPage);
      if (result.isFailure) {
        debugPrint('마지막 읽은 페이지 저장 실패: ${result.error}');
      }
    } catch (e) {
      debugPrint('마지막 읽은 페이지 저장 중 오류: $e');
    }
  }
  
  /// 문서 공유
  Future<void> shareDocument() async {
    if (_document == null || _document!.filePath.isEmpty) return;
    
    try {
      // 문서가 내장 메모리에 있는 경우
      if (File(_document!.filePath).existsSync()) {
        await Share.shareXFiles([XFile(_document!.filePath)], text: _document!.title);
        return;
      }
      
      // 원격 문서인 경우 다운로드 후 공유
      if (_document!.downloadUrl.isNotEmpty) {
        _setStatus(PDFViewerStatus.loading);
        
        final result = await _pdfService.downloadPdf(_document!.downloadUrl);
        
        if (result.isSuccess) {
          final filePath = result.getOrNull();
          if (filePath != null && filePath.isNotEmpty) {
            await Share.shareXFiles([XFile(filePath)], text: _document!.title);
          }
        }
        
        _setStatus(PDFViewerStatus.success);
      }
    } catch (e) {
      _setError('문서 공유 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 문서 파일 저장
  Future<bool> saveDocumentToDevice() async {
    if (_document == null || _document!.filePath.isEmpty) {
      _setError('저장할 문서가 없습니다.');
      return false;
    }
    
    try {
      // 권한 확인
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _setError('저장 권한이 거부되었습니다.');
        return false;
      }
      
      // 저장 경로 가져오기
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _setError('저장 디렉토리를 찾을 수 없습니다.');
        return false;
      }
      
      // 원본 파일
      final sourceFile = File(_document!.filePath);
      if (!await sourceFile.exists()) {
        // 다운로드 URL이 있는 경우 다운로드
        if (_document!.downloadUrl.isNotEmpty) {
          _setStatus(PDFViewerStatus.loading);
          
          final result = await _pdfService.downloadPdf(_document!.downloadUrl);
          
          if (result.isSuccess) {
            final filePath = result.getOrNull();
            if (filePath != null && filePath.isNotEmpty) {
              final downloadedFile = File(filePath);
              final targetPath = '${directory.path}/${_document!.title}.pdf';
              await downloadedFile.copy(targetPath);
              _setStatus(PDFViewerStatus.success);
              return true;
            }
          } else {
            _setError('파일 다운로드 실패: ${result.error?.toString() ?? '알 수 없는 오류'}');
            return false;
          }
          
          _setStatus(PDFViewerStatus.success);
          return false;
        } else {
          _setError('파일을 찾을 수 없고 다운로드 URL도 없습니다.');
          return false;
        }
      }
      
      // 대상 파일 경로
      final targetPath = '${directory.path}/${_document!.title}.pdf';
      
      // 파일 복사
      await sourceFile.copy(targetPath);
      return true;
    } catch (e) {
      _setError('문서 저장 중 오류가 발생했습니다: $e');
      return false;
    }
  }
  
  /// PDF 파일 다운로드
  Future<Uint8List?> downloadPdf(String url) async {
    try {
      _setStatus(PDFViewerStatus.loading);
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _setStatus(PDFViewerStatus.success);
        return response.bodyBytes;
      } else {
        _setError('PDF 다운로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _setError('PDF 다운로드 중 오류: $e');
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
        _setError('파일을 찾을 수 없습니다: $filePath');
        return null;
      }
    } catch (e) {
      _setError('PDF 로드 중 오류: $e');
      return null;
    }
  }
  
  /// 샘플 PDF 로드
  Future<Uint8List?> loadSamplePdf() async {
    try {
      final result = await _repository.loadSamplePdf();
      if (result.isSuccess) {
        return result.data;
      } else {
        _setError(result.error?.toString() ?? '샘플 PDF 로드 실패');
        return null;
      }
    } catch (e) {
      _setError('샘플 PDF 로드 중 오류: $e');
      return null;
    }
  }
  
  /// 리소스 해제
  @override
  void dispose() {
    // 마지막으로 읽은 페이지 저장
    if (_document != null) {
      _saveLastReadPage();
    }
    
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    if (_document == null) return;
    
    // 이미 로컬에 있는 경우 건너뜀
    if (await File(_document!.filePath).exists()) return;
    
    // 다운로드 URL이 있는 경우에만 다운로드
    if (_document!.downloadUrl.isNotEmpty) {
      try {
        _setStatus(PDFViewerStatus.loading);
        
        final result = await _pdfService.downloadPdf(_document!.downloadUrl);
        
        if (result.isSuccess) {
          final filePath = result.getOrNull();
          
          if (filePath != null && filePath.isNotEmpty) {
            // 문서 업데이트
            _document = _document!.copyWith(
              filePath: filePath,
              updatedAt: DateTime.now(),
            );
            
            await _repository.saveDocument(_document!);
            _setSuccess();
          }
        } else {
          _setError(result.error?.toString() ?? '다운로드 실패');
        }
      } catch (e) {
        _setError('다운로드 오류: $e');
      }
    }
  }

  Future<void> _initialize() async {
    _setStatus(PDFViewerStatus.loading);
    
    try {
      // 문서 ID가 있으면 해당 문서를 로드
      if (_documentId != null && _documentId!.isNotEmpty) {
        final result = await _loadDocumentById(_documentId!);
        if (result.isFailure) {
          throw result.error ?? Exception('문서 로드 실패');
        }
      } 
      // 이미 문서가 제공된 경우 추가 정보 로드
      else if (_document != null) {
        await _loadDocumentData();
        await _loadBookmarks();
        _currentPage = await _loadLastReadPage();
        _setStatus(PDFViewerStatus.success);
      }
      // 문서와 ID가 모두 없는 경우 오류 처리
      else {
        throw Exception('문서 정보가 부족합니다.');
      }
    } catch (e) {
      debugPrint('PDF 뷰어 초기화 오류: $e');
      _setError('초기화 중 오류: $e');
    }
  }

  Future<Result<PDFDocument>> _loadDocumentById(String documentId) async {
    try {
      _setStatus(PDFViewerStatus.loading);
      
      final documentResult = await _repository.getDocument(documentId);
      
      if (documentResult.isSuccess) {
        _document = documentResult.getOrNull();
        
        if (_document != null) {
          await _loadBookmarks();
          _currentPage = await _loadLastReadPage();
          _setStatus(PDFViewerStatus.success);
          return Result.success(_document!);
        } else {
          throw Exception('문서를 찾을 수 없습니다.');
        }
      } else {
        throw documentResult.error ?? Exception('문서 로드 실패');
      }
    } catch (e) {
      _setError('문서 ID로 로드 중 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  /// 북마크 목록 로드 (비공개 메소드)
  Future<void> _loadBookmarks() async {
    if (_document == null) return;
    
    try {
      final bookmarksResult = await _repository.getBookmarks(_document!.id);
      
      if (bookmarksResult.isSuccess) {
        _bookmarks = bookmarksResult.data ?? [];
      } else {
        debugPrint('북마크 로드 실패: ${bookmarksResult.error}');
        _bookmarks = [];
      }
    } catch (e) {
      debugPrint('북마크 로드 오류: $e');
      _bookmarks = [];
    }
  }

  // 텍스트 선택 메서드
  void selectText(String selectedText, int pageNumber) {
    _selectedText = selectedText;
    _selectedPage = pageNumber;
    debugPrint('선택된 텍스트: $selectedText, 페이지: $pageNumber');
    notifyListeners();
  }
  
  // 노트 추가 메서드
  Future<bool> addNote({
    required String documentId,
    required String title,
    required String content,
    required int page,
    required String selectedText,
    Color color = Colors.yellow,
  }) async {
    try {
      if (selectedText.isEmpty) {
        return false;
      }
      
      final bookmark = PDFBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: documentId,
        title: title,
        page: page,
        content: content,
        textContent: selectedText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: PDFBookmarkType.note,
        color: color.value,
      );
      
      await _repository.saveBookmark(bookmark);
      // 노트 목록 업데이트
      if (_documentId != null && _documentId!.isNotEmpty) {
        final result = await _repository.getBookmarks(_documentId!);
        _notes = result.data?.where((b) => b.type == PDFBookmarkType.note).toList() ?? [];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// 노트 저장
  Future<void> _saveNotes() async {
    // 노트는 북마크로 저장되므로 별도 구현 불필요
  }
} 