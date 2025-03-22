import 'dart:async';
// 플랫폼에 따라 다른 임포트
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 웹이 아닌 경우에만 path_provider 임포트
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_document.dart';
import '../repositories/pdf_repository.dart';

enum SortOption {
  nameAZ,
  nameZA,
  dateNewest,
  dateOldest,
}

class DocumentListViewModel extends ChangeNotifier {
  List<PDFDocument> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  SortOption _sortOption = SortOption.dateNewest;
  String _searchQuery = '';
  final PdfRepository _repository;
  
  // 생성자에서 저장소 주입 받기
  DocumentListViewModel({PdfRepository? repository}) 
      : _repository = repository ?? PdfRepository();

  // 게터
  List<PDFDocument> get documents => _filteredDocuments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  bool get hasDocuments => _documents.isNotEmpty;
  bool get hasFilteredDocuments => _filteredDocuments.isNotEmpty;

  // 검색 및 정렬이 적용된 문서 목록
  List<PDFDocument> get _filteredDocuments {
    List<PDFDocument> result = List.from(_documents);
    
    // 검색 필터링
    if (_searchQuery.isNotEmpty) {
      result = result.where((doc) => 
        doc.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    // 정렬
    switch (_sortOption) {
      case SortOption.nameAZ:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameZA:
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.dateNewest:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.dateOldest:
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }
    
    return result;
  }

  // 문서 목록 로드
  Future<void> loadDocuments() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _documents = await _repository.getDocuments();
      notifyListeners();
    } catch (e) {
      _errorMessage = '문서 목록을 불러오는 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // 새 PDF 문서 추가
  Future<PDFDocument?> addDocument(File file) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final fileName = file.path.split('/').last;
      
      if (kIsWeb) {
        // 웹 환경에서는 파일 시스템 접근이 제한적이므로 저장소를 직접 사용
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName.replaceAll('.pdf', ''),
          fileName: fileName,
          fileSize: 0, // 웹에서는 파일 크기를 알 수 없음
          filePath: file.path, // 웹에서는 파일 경로를 URL로 사용
          pageCount: 1, // 웹에서는 페이지 수를 알 수 없음
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          accessCount: 0,
        );
        
        // 저장
        await _repository.saveDocument(document);
        
        // 목록 새로고침
        await loadDocuments();
        
        return document;
      } else {
        // 네이티브 환경에서는 파일 시스템 접근
        final fileSize = await file.length();
        final directory = await getApplicationDocumentsDirectory();
        final targetPath = '${directory.path}/pdf_documents/$fileName';
        
        // 파일 존재 여부 확인
        final existingFile = File(targetPath);
        if (await existingFile.exists()) {
          // 중복 파일 처리 (이름 변경 또는 교체)
          await existingFile.delete();
        }
        
        // 파일 복사
        final copiedFile = await file.copy(targetPath);
        
        // 새 문서 생성
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName.replaceAll('.pdf', ''),
          fileName: fileName,
          fileSize: fileSize,
          filePath: copiedFile.path,
          pageCount: await _getPageCount(copiedFile.path),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          accessCount: 0,
        );
        
        // 저장
        await _repository.saveDocument(document);
        
        // 목록 새로고침
        await loadDocuments();
        
        return document;
      }
    } catch (e) {
      _errorMessage = '문서 추가 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 파일 선택 및 추가
  Future<PDFDocument?> pickAndAddDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        return await addDocument(file);
      }
      
      return null;
    } catch (e) {
      _errorMessage = '파일 선택 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return null;
    }
  }

  // 페이지 수 가져오기 (실제로는 PDF 라이브러리 사용)
  Future<int> _getPageCount(String filePath) async {
    try {
      // 실제 구현에서는 PDF 라이브러리를 사용해서 페이지 수를 가져옵니다.
      // 예제 코드이므로 고정 값 반환
      return 10;
    } catch (e) {
      debugPrint('페이지 수 가져오기 실패: $e');
      return 1; // 기본값
    }
  }

  // 문서 삭제
  Future<bool> deleteDocument(String id) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // 문서 찾기
      final document = _documents.firstWhere((doc) => doc.id == id);
      
      if (!kIsWeb) {
        // 네이티브 환경에서만 파일 삭제 시도
        final file = File(document.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // 저장소에서 삭제
      await _repository.deleteDocument(id);
      
      // 목록 새로고침
      await loadDocuments();
      
      return true;
    } catch (e) {
      _errorMessage = '문서 삭제 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 로컬 파일에서 PDF 추가
  Future<PDFDocument?> addPdfFromFile(String filePath) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      if (kIsWeb) {
        // 웹에서는 URL 기반 파일 처리
        // 웹에서 file_picker를 통해 얻은 파일은 사실 blob URL로 처리 가능
        // 이 URL을 PDF 뷰어에서 직접 사용
        final fileName = filePath.split('/').last;
        final fileSize = 1024 * 1024; // 가상 크기 (1MB)
        
        // 웹용 PDF 문서 생성
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName.replaceAll('.pdf', ''),
          filePath: filePath, // 웹에서는 filePath가 URL 형태
          fileName: fileName,
          fileSize: fileSize,
          pageCount: 10, // 기본값
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );
        
        // 저장 및 목록 새로고침
        await _repository.saveDocument(document);
        await loadDocuments();
        return document;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('파일이 존재하지 않습니다: $filePath');
      }
      
      // PDF 저장소를 통해 문서 임포트
      final document = await _repository.importPdfFile(filePath: filePath);
      
      if (document != null) {
        // 목록 새로고침
        await loadDocuments();
        return document;
      } else {
        throw Exception('PDF 파일을 임포트할 수 없습니다');
      }
    } catch (e) {
      _errorMessage = '문서 추가 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // URL에서 PDF 추가
  Future<PDFDocument?> addPdfFromUrl(String url) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // URL 검증 - 확장자가 .pdf가 아니어도 허용 (리디렉션이나 파라미터가 있는 URL 지원)
      // 실제 구현에서는 서버에서 Content-Type 확인 등 더 정교한 검증 필요
      
      // PDF 저장소를 통해 URL에서 문서 생성
      final document = await _repository.createPdfFromUrl(url);
      
      if (document != null) {
        // 목록 새로고침
        await loadDocuments();
        return document;
      } else {
        throw Exception('URL에서 PDF 파일을 가져올 수 없습니다');
      }
    } catch (e) {
      _errorMessage = 'URL에서 문서 추가 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 문서 업데이트
  Future<bool> updateDocument(PDFDocument document) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _repository.saveDocument(document);
      await loadDocuments();
      return true;
    } catch (e) {
      _errorMessage = '문서 업데이트 중 오류가 발생했습니다: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 정렬 옵션 변경
  void setSortOption(SortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  // 검색어 설정
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // 검색 초기화
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 오류 메시지 초기화
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
} 