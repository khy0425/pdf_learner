import 'dart:async';
import 'dart:math';
// 플랫폼에 따라 다른 임포트
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 웹이 아닌 경우에만 path_provider 임포트
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../models/pdf_document.dart';
import '../models/sort_option.dart';
import '../repositories/pdf_repository.dart';
import '../services/file_picker_service.dart';

/// 문서 목록을 관리하는 뷰모델
class DocumentListViewModel extends ChangeNotifier {
  final PdfRepository _repository;
  final FilePickerService _filePickerService = FilePickerService();
  
  // 데이터 상태
  List<PDFDocument> _documents = [];
  List<PDFDocument> _filteredDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateNewest;
  
  DocumentListViewModel({
    required PdfRepository repository,
  }) : _repository = repository;
  
  // 게터
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<PDFDocument> get documents => List.unmodifiable(_documents);
  List<PDFDocument> get filteredDocuments => List.unmodifiable(_filteredDocuments);
  
  /// 문서 목록 로드
  Future<void> loadDocuments() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 저장소에서 모든 문서 가져오기
      _documents = await _repository.getAllDocuments();
      
      // 필터 및 정렬 적용
      _applyFiltersAndSort();
      
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('문서 목록 로드 중 오류 발생: $e');
    }
    notifyListeners();
  }
  
  /// 필터 및 정렬 적용
  void _applyFiltersAndSort() {
    // 원본 문서 리스트 복사
    List<PDFDocument> tempDocuments = List.from(_documents);
    
    // 검색어로 필터링
    if (_searchQuery.isNotEmpty) {
      tempDocuments = tempDocuments.where((doc) => 
        doc.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // 정렬 적용
    tempDocuments.sort((a, b) {
      switch (_sortOption) {
        case SortOption.dateNewest:
          return b.lastOpened.compareTo(a.lastOpened);
        case SortOption.dateOldest:
          return a.lastOpened.compareTo(b.lastOpened);
        case SortOption.nameAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.nameZA:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case SortOption.pageCountAsc:
          return a.pageCount.compareTo(b.pageCount);
        case SortOption.pageCountDesc:
          return b.pageCount.compareTo(a.pageCount);
        case SortOption.addedNewest:
          return b.dateAdded.compareTo(a.dateAdded);
        case SortOption.addedOldest:
          return a.dateAdded.compareTo(b.dateAdded);
      }
    });
    
    // 결과 저장
    _filteredDocuments = tempDocuments;
  }
  
  /// 정렬 옵션 설정
  void setSortOption(SortOption sortOption) {
    _sortOption = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }
  
  /// 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }
  
  /// 검색 초기화
  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }
  
  /// URL에서 PDF 추가
  Future<bool> addPdfFromUrl(String url, String title) async {
    try {
      _isLoading = true;
      notifyListeners();
      final document = await _repository.addDocumentFromUrl(url, title);
      
      if (document != null) {
        await loadDocuments();
        return true;
      }
      
      return false;
    } catch (e) {
      _errorMessage = 'PDF 추가 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 파일에서 PDF 추가
  Future<bool> pickAndAddDocument() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서의 파일 선택
        final filePickerService = FilePickerService();
        final result = await filePickerService.pickPdfFile();
        
        if (result == null) return false;
        
        final fileDetails = filePickerService.getFileDetailsFromPlatformFile(result);
        if (fileDetails == null) return false;
        
        final fileName = fileDetails.name.replaceAll('.pdf', '');
        return await addPdfFromBytes(fileDetails.bytes, fileName);
      } else {
        // 모바일 환경에서의 파일 선택
        final filePickerService = FilePickerService();
        final file = await filePickerService.pickPdfFile();
        
        if (file == null) return false;
        
        final fileName = file.path.split('/').last.replaceAll('.pdf', '');
        return await addPdfFromFile(file, fileName);
      }
    } catch (e) {
      _errorMessage = '파일 선택 중 오류 발생: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 파일에서 PDF 추가 (모바일)
  Future<bool> addPdfFromFile(File file, String title) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 웹 환경에서는 File을 io.File로 변환할 수 없으므로, 바이트 데이터를 사용
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        // List<int>를 Uint8List로 변환
        final uint8Bytes = Uint8List.fromList(bytes);
        final document = await _repository.addDocumentFromBytes(uint8Bytes, title);
        
        if (document != null) {
          await loadDocuments();
          return true;
        }
      } else {
        // 웹이 아닌 환경에서는 io.File로 변환
        io.File ioFile = io.File(file.path);
        final document = await _repository.addDocumentFromFile(ioFile, title);
        
        if (document != null) {
          await loadDocuments();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      _errorMessage = 'PDF 파일 추가 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 바이트 데이터에서 PDF 추가 (웹)
  Future<bool> addPdfFromBytes(Uint8List bytes, String title) async {
    try {
      _isLoading = true;
      notifyListeners();
      final document = await _repository.addDocumentFromBytes(bytes, title);
      
      if (document != null) {
        await loadDocuments();
        return true;
      }
      
      return false;
    } catch (e) {
      _errorMessage = 'PDF 바이트 데이터 추가 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 문서 삭제
  Future<bool> deleteDocument(String documentId) async {
    try {
      final success = await _repository.deleteDocument(documentId);
      if (success) {
        await loadDocuments(); // 목록 갱신
      }
      return success;
    } catch (e) {
      debugPrint('문서 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 문서 이름 변경
  Future<bool> renameDocument(String documentId, String newTitle) async {
    try {
      final success = await _repository.renameDocument(documentId, newTitle);
      if (success) {
        await loadDocuments(); // 목록 갱신
      }
      return success;
    } catch (e) {
      debugPrint('문서 이름 변경 중 오류: $e');
      return false;
    }
  }
  
  /// 검색 기능
  void searchDocuments(String query) {
    setSearchQuery(query);
  }
  
  /// 정렬 기능
  void sortDocuments(SortOption option) {
    if (_sortOption == option) {
      return; // 이미 동일한 정렬 방식이면 재정렬 불필요
    }
    
    _sortOption = option;
    
    switch (option) {
      case SortOption.dateNewest:
        _filteredDocuments.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
        break;
      case SortOption.dateOldest:
        _filteredDocuments.sort((a, b) => a.lastOpened.compareTo(b.lastOpened));
        break;
      case SortOption.nameAZ:
        _filteredDocuments.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.nameZA:
        _filteredDocuments.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.pageCountAsc:
        _filteredDocuments.sort((a, b) => a.pageCount.compareTo(b.pageCount));
        break;
      case SortOption.pageCountDesc:
        _filteredDocuments.sort((a, b) => b.pageCount.compareTo(a.pageCount));
        break;
      case SortOption.addedNewest:
        _filteredDocuments.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOption.addedOldest:
        _filteredDocuments.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
    }
    
    notifyListeners();
  }
} 