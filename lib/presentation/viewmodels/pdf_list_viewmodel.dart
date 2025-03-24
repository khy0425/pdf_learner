import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_learner_v2/models/pdf_document.dart';
import 'package:pdf_learner_v2/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/services/storage_service.dart';
import 'package:pdf_learner_v2/utils/web_utils.dart';

class PDFListViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  final StorageService _storageService;
  
  PDFListViewModel({
    required PDFRepository repository,
    required StorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  List<PDFDocument> _documents = [];
  List<PDFDocument> _filteredDocuments = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<PDFDocument> get documents => _searchQuery.isEmpty 
    ? _documents 
    : _filteredDocuments;
  
  bool get isLoading => _isLoading;

  /// 문서 목록 불러오기
  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _documents = await _repository.loadDocuments();
    } catch (e) {
      debugPrint('문서 로드 오류: $e');
      _documents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 문서 검색
  void searchDocuments(String query) {
    _searchQuery = query.toLowerCase().trim();
    
    if (_searchQuery.isEmpty) {
      _filteredDocuments = [];
    } else {
      _filteredDocuments = _documents.where((document) {
        final title = document.title.toLowerCase();
        return title.contains(_searchQuery);
      }).toList();
    }
    
    notifyListeners();
  }

  /// 날짜순 정렬
  void sortDocumentsByDate() {
    _documents.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    notifyListeners();
  }

  /// 이름순 정렬
  void sortDocumentsByName() {
    _documents.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    notifyListeners();
  }

  /// 크기순 정렬
  void sortDocumentsBySize() {
    _documents.sort((a, b) => b.size.compareTo(a.size));
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    notifyListeners();
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(PDFDocument document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    // 즐겨찾기 목록 업데이트
    final updatedDoc = _documents[index].copyWith(
      favorites: document.favorites.isEmpty ? ['default'] : [],
    );
    
    _documents[index] = updatedDoc;
    
    // 저장소에 업데이트
    await _repository.updateDocument(updatedDoc);
    
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    
    notifyListeners();
  }

  /// 문서 이름 변경
  Future<void> renameDocument(PDFDocument document, String newTitle) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    // 이름 업데이트
    final updatedDoc = _documents[index].copyWith(
      title: newTitle,
      dateModified: DateTime.now(),
    );
    
    _documents[index] = updatedDoc;
    
    // 저장소에 업데이트
    await _repository.updateDocument(updatedDoc);
    
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    
    notifyListeners();
  }

  /// 문서 삭제
  Future<void> deleteDocument(PDFDocument document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    
    // 목록에서 삭제
    _documents.removeAt(index);
    
    // 저장소에서 삭제
    await _repository.deleteDocument(document);
    
    if (_searchQuery.isNotEmpty) {
      searchDocuments(_searchQuery);
    }
    
    notifyListeners();
  }

  /// 문서 공유
  Future<void> shareDocument(PDFDocument document) async {
    try {
      if (kIsWeb) {
        // 웹에서는 다운로드로 대체
        await WebUtils.downloadFile(document.url, document.title);
      } else {
        final filePath = await _storageService.getFilePath(document.id);
        await Share.shareFiles([filePath], text: document.title);
      }
    } catch (e) {
      debugPrint('문서 공유 오류: $e');
    }
  }

  /// 문서 선택 및 추가
  Future<void> pickAndAddDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // 웹에서는 bytes를 사용
          if (file.bytes != null) {
            final document = await _repository.addDocument(
              file.name,
              bytes: file.bytes,
            );
            _documents.insert(0, document);
          }
        } else {
          // 네이티브에서는 파일 경로 사용
          if (file.path != null) {
            final document = await _repository.addDocument(
              file.name,
              path: file.path,
            );
            _documents.insert(0, document);
          }
        }
        
        if (_searchQuery.isNotEmpty) {
          searchDocuments(_searchQuery);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('문서 추가 오류: $e');
    }
  }
} 