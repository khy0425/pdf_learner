import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

/// PDF 상태
enum PDFStatus {
  initial,
  loading,
  loaded,
  error
}

/// PDF 뷰모델
@injectable
class PDFViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  
  PDFStatus _status = PDFStatus.initial;
  List<PDFDocument> _documents = [];
  PDFDocument? _currentDocument;
  String? _error;
  
  PDFViewModel(this._repository);
  
  // 게터
  PDFStatus get status => _status;
  List<PDFDocument> get documents => _documents;
  PDFDocument? get currentDocument => _currentDocument;
  List<PDFBookmark> get bookmarks => _currentDocument?.bookmarks ?? [];
  String? get error => _error;
  bool get isLoading => _status == PDFStatus.loading;
  
  Future<void> loadDocuments() async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      final docs = await _repository.getDocuments();
      _documents = docs;
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> loadDocument(String id) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      final document = await _repository.getDocument(id);
      if (document != null) {
        _currentDocument = document;
        _status = PDFStatus.loaded;
      } else {
        _error = '문서를 찾을 수 없습니다.';
        _status = PDFStatus.error;
      }
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> createDocument(PDFDocument document) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.createDocument(document);
      await loadDocuments();
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
      notifyListeners();
    }
  }
  
  Future<void> updateDocument(PDFDocument document) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.updateDocument(document);
      
      // 현재 문서 업데이트
      if (_currentDocument?.id == document.id) {
        _currentDocument = document;
      }
      
      // 문서 목록 업데이트
      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        _documents[index] = document;
      }
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> deleteDocument(String id) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.deleteDocument(id);
      
      // 현재 문서인 경우 초기화
      if (_currentDocument?.id == id) {
        _currentDocument = null;
      }
      
      // 문서 목록에서 제거
      _documents.removeWhere((doc) => doc.id == id);
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> createBookmark(PDFBookmark bookmark) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.createBookmark(bookmark);
      
      // 현재 문서의 북마크 업데이트
      if (_currentDocument != null && _currentDocument!.id == bookmark.documentId) {
        final updatedBookmarks = [...(_currentDocument!.bookmarks), bookmark];
        _currentDocument = _currentDocument!.copyWith(bookmarks: updatedBookmarks);
      }
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.updateBookmark(bookmark);
      
      // 현재 문서의 북마크 업데이트
      if (_currentDocument != null) {
        final updatedBookmarks = _currentDocument!.bookmarks.map((b) => 
          b.id == bookmark.id ? bookmark : b
        ).toList();
        
        _currentDocument = _currentDocument!.copyWith(bookmarks: updatedBookmarks);
      }
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> deleteBookmark(String bookmarkId) async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.deleteBookmark(bookmarkId);
      
      // 현재 문서의 북마크 업데이트
      if (_currentDocument != null) {
        final updatedBookmarks = _currentDocument!.bookmarks
            .where((b) => b.id != bookmarkId)
            .toList();
        
        _currentDocument = _currentDocument!.copyWith(bookmarks: updatedBookmarks);
      }
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<int> getPageCount(String filePath) async {
    try {
      return await _repository.getPageCount(filePath);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }
  
  Future<String> extractText(String filePath, int pageNumber) async {
    try {
      return await _repository.extractText(filePath, pageNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return '';
    }
  }
  
  void setCurrentDocument(PDFDocument document) {
    _currentDocument = document;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    if (_status == PDFStatus.error) {
      _status = _documents.isNotEmpty ? PDFStatus.loaded : PDFStatus.initial;
    }
    notifyListeners();
  }
  
  // PDF 파일 선택 및 추가
  Future<void> pickAndAddPDF() async {
    try {
      _status = PDFStatus.loading;
      _error = null;
      notifyListeners();
      
      // 파일 피커 열기
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 웹 환경인 경우
        if (kIsWeb) {
          if (file.bytes != null) {
            final fileName = file.name;
            final fileUrl = await _repository.uploadPDFFile('', fileName, bytes: file.bytes);
            
            // 새 문서 생성
            final newDocument = PDFDocument(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: path.basenameWithoutExtension(fileName),
              description: '',
              filePath: fileUrl,
              fileSize: file.size,
              pageCount: 0, // 나중에 업데이트
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              version: 1,
              isEncrypted: false,
              isShared: false,
              isFavorite: false,
              isSelected: false,
              isOcrEnabled: false,
              isSummarized: false,
              readingProgress: 0.0,
              lastReadPage: 0,
              totalReadingTime: 0,
              lastReadingTime: 0,
              readingTime: 0,
              currentPage: 0,
              bookmarks: [],
              tags: [],
              metadata: {},
              status: PDFDocumentStatus.initial,
              importance: PDFDocumentImportance.medium,
              securityLevel: PDFDocumentSecurityLevel.none,
            );
            
            await createDocument(newDocument);
          }
        } 
        // 네이티브 환경인 경우
        else if (file.path != null) {
          final filePath = file.path!;
          final fileName = file.name;
          final fileUrl = await _repository.uploadPDFFile(filePath, fileName);
          
          // 새 문서 생성
          final newDocument = PDFDocument(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: path.basenameWithoutExtension(fileName),
            description: '',
            filePath: fileUrl,
            fileSize: file.size,
            pageCount: await getPageCount(filePath),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            version: 1,
            isEncrypted: false,
            isShared: false,
            isFavorite: false,
            isSelected: false,
            isOcrEnabled: false,
            isSummarized: false,
            readingProgress: 0.0,
            lastReadPage: 0,
            totalReadingTime: 0,
            lastReadingTime: 0,
            readingTime: 0,
            currentPage: 0,
            bookmarks: [],
            tags: [],
            metadata: {},
            status: PDFDocumentStatus.initial,
            importance: PDFDocumentImportance.medium,
            securityLevel: PDFDocumentSecurityLevel.none,
          );
          
          await createDocument(newDocument);
        }
      }
      
      _status = PDFStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
    } finally {
      notifyListeners();
    }
  }
  
  // 즐겨찾기 토글
  Future<void> toggleFavorite(String documentId) async {
    try {
      // 문서 찾기
      final docIndex = _documents.indexWhere((doc) => doc.id == documentId);
      if (docIndex == -1) {
        _error = '문서를 찾을 수 없습니다.';
        notifyListeners();
        return;
      }
      
      // 업데이트할 문서
      final document = _documents[docIndex];
      final updatedDocument = document.copyWith(
        isFavorite: !document.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      // 문서 업데이트
      await updateDocument(updatedDocument);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 