import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';
import '../services/file_storage_service.dart';
import '../utils/web_utils.dart';

/// PDF 문서 저장소
class PDFDocumentRepository {
  // 문서 목록
  List<PDFDocument> _documents = [];
  
  // 서비스 의존성
  final FileStorageService _storageService;
  
  // 스트림 컨트롤러
  final _documentsStreamController = StreamController<List<PDFDocument>>.broadcast();
  
  /// 생성자
  PDFDocumentRepository({
    required FileStorageService storageService,
  }) : _storageService = storageService {
    _init();
  }
  
  /// 문서 목록 스트림
  Stream<List<PDFDocument>> get documentsStream => _documentsStreamController.stream;
  
  /// 문서 목록
  List<PDFDocument> get documents => List.unmodifiable(_documents);
  
  /// 초기화
  Future<void> _init() async {
    try {
      await loadDocuments();
    } catch (e) {
      debugPrint('PDF 문서 저장소 초기화 오류: $e');
    }
  }
  
  /// 모든 문서 가져오기
  Future<List<PDFDocument>> getAllDocuments() async {
    await loadDocuments();
    return documents;
  }
  
  /// 문서 목록 로드
  Future<List<PDFDocument>> loadDocuments() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 로드
        final webDocuments = await _loadDocumentsFromWebStorage();
        _documents = webDocuments;
      } else {
        // 네이티브 환경에서는 파일 시스템에서 로드
        _documents = await _storageService.getDocuments();
      }
      
      _notifyDocumentsChanged();
      return _documents;
    } catch (e) {
      debugPrint('문서 목록 로드 중 오류: $e');
      _documents = [];
      return [];
    }
  }
  
  /// 웹 환경에서 문서 로드
  Future<List<PDFDocument>> _loadDocumentsFromWebStorage() async {
    if (kIsWeb) {
      try {
        final documentsJson = WebUtils.loadFromLocalStorage('pdf_documents');
        
        if (documentsJson != null) {
          final List<dynamic> jsonList = documentsJson;
          return jsonList.map((json) => PDFDocument.fromJson(json)).toList();
        }
      } catch (e) {
        debugPrint('웹 스토리지에서 문서 로드 중 오류: $e');
      }
    }
    return [];
  }
  
  /// 웹 환경에서 문서 저장
  Future<void> _saveDocumentsToWebStorage(List<PDFDocument> documents) async {
    if (kIsWeb) {
      try {
        final jsonList = documents.map((doc) => doc.toJson()).toList();
        WebUtils.saveToLocalStorage('pdf_documents', jsonList);
      } catch (e) {
        debugPrint('웹 스토리지에 문서 저장 중 오류: $e');
      }
    }
  }
  
  /// 문서 목록 변경 알림
  void _notifyDocumentsChanged() {
    _documentsStreamController.add(_documents);
  }
  
  /// 문서 업데이트
  Future<bool> updateDocument(PDFDocument document) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index == -1) {
        return false;
      }
      
      _documents[index] = document;
      await _saveDocuments();
      _notifyDocumentsChanged();
      return true;
    } catch (e) {
      debugPrint('문서 업데이트 중 오류: $e');
      return false;
    }
  }
  
  /// 문서 삭제
  Future<bool> deleteDocument(PDFDocument document) async {
    try {
      _documents.removeWhere((doc) => doc.id == document.id);
      await _saveDocuments();
      _notifyDocumentsChanged();
      return true;
    } catch (e) {
      debugPrint('문서 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// ID로 문서 검색
  Future<PDFDocument?> getDocumentById(String documentId) async {
    try {
      if (_documents.isEmpty) {
        await loadDocuments();
      }
      
      return _documents.firstWhere(
        (doc) => doc.id == documentId,
        orElse: () => throw Exception('문서를 찾을 수 없습니다: $documentId'),
      );
    } catch (e) {
      debugPrint('ID로 문서 검색 중 오류: $e');
      return null;
    }
  }
  
  /// 저장된 문서 목록 업데이트
  Future<void> _saveDocuments() async {
    try {
      if (kIsWeb) {
        await _saveDocumentsToWebStorage(_documents);
      } else {
        await _storageService.saveDocuments(_documents);
      }
    } catch (e) {
      debugPrint('문서 목록 저장 오류: $e');
    }
  }
  
  /// 리소스 해제
  void dispose() {
    _documentsStreamController.close();
  }
} 