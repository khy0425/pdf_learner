import 'dart:typed_data';
import 'package:flutter/material.dart';
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
class PDFViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  
  PDFStatus _status = PDFStatus.initial;
  List<PDFDocument> _documents = [];
  PDFDocument? _selectedDocument;
  String? _error;
  
  // 게스트 모드 지원을 위한 변수
  bool _hasOpenDocument = false;
  
  PDFViewModel(this._repository);
  
  // 게터
  PDFStatus get status => _status;
  List<PDFDocument> get documents => _documents;
  PDFDocument? get selectedDocument => _selectedDocument;
  String? get error => _error;
  bool get isLoading => _status == PDFStatus.loading;
  bool get hasOpenDocument => _hasOpenDocument;
  
  Future<void> loadDocuments() async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      _documents = await _repository.getDocuments();
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
        _selectedDocument = document;
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
      if (_selectedDocument?.id == document.id) {
        _selectedDocument = document;
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
      if (_selectedDocument?.id == id) {
        _selectedDocument = null;
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
  
  Future<PDFDocument?> pickAndUploadPDF() async {
    _status = PDFStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      // 파일 선택
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result == null || result.files.isEmpty) {
        _status = PDFStatus.loaded;
        notifyListeners();
        return null;
      }
      
      final file = result.files.first;
      String? filePath = file.path;
      
      if (filePath == null) {
        _error = '파일 경로를 찾을 수 없습니다.';
        _status = PDFStatus.error;
        notifyListeners();
        return null;
      }
      
      // PDF 문서 생성
      final filename = path.basename(filePath);
      final now = DateTime.now();
      
      final document = PDFDocument(
        id: now.millisecondsSinceEpoch.toString(),
        title: filename.replaceAll('.pdf', ''),
        description: '',
        filePath: filePath,
        fileSize: 0,
        pageCount: 0, // 실제 페이지 수는 나중에 업데이트
        createdAt: now,
        updatedAt: now,
        lastModifiedAt: now,
        version: 1,
        isEncrypted: false,
        encryptionKey: null,
        isShared: false,
        shareId: null,
        shareUrl: null,
        shareExpiresAt: null,
        readingProgress: 0.0,
        lastReadPage: 0,
        totalReadingTime: 0,
        lastReadingTime: 0,
        thumbnailUrl: null,
        isOcrEnabled: false,
        ocrLanguage: null,
        ocrStatus: null,
        isSummarized: false,
        currentPage: 0,
        isFavorite: false,
        isSelected: false,
        readingTime: 0,
        status: PDFDocumentStatus.created,
        importance: PDFDocumentImportance.normal,
        securityLevel: PDFDocumentSecurityLevel.normal,
        tags: [],
        bookmarks: [],
        metadata: {},
      );
      
      // 저장
      await _repository.createDocument(document);
      
      // 문서 목록 새로고침
      await loadDocuments();
      
      return document;
    } catch (e) {
      _error = e.toString();
      _status = PDFStatus.error;
      notifyListeners();
      return null;
    }
  }
  
  void setSelectedDocument(PDFDocument document) {
    _selectedDocument = document;
    _hasOpenDocument = true;
    notifyListeners();
  }
  
  void clearSelectedDocument() {
    _selectedDocument = null;
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
} 