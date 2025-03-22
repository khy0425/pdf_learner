import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_document.dart';

/// PDF 문서 관리를 위한 뷰모델
class PdfViewModel extends ChangeNotifier {
  /// 현재 로드된 PDF 문서 목록
  List<PdfDocument> _documents = [];
  
  /// 현재 선택된 PDF 문서
  PdfDocument? _selectedDocument;
  
  /// 로딩 상태
  bool _isLoading = false;
  
  /// 오류 메시지
  String? _errorMessage;
  
  /// 현재 선택된 페이지
  int _currentPage = 1;
  
  /// 현재 생성 중인 메모 텍스트
  String _memoText = '';

  /// getter 메서드들
  List<PdfDocument> get documents => _documents;
  PdfDocument? get selectedDocument => _selectedDocument;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String get memoText => _memoText;
  
  /// PDF 문서 목록 로드 (초기화)
  Future<void> loadSampleDocuments() async {
    _setLoading(true);
    
    try {
      // 빈 목록으로 초기화
      _documents = [];
      
      _setError(null);
    } catch (e) {
      _setError('PDF 문서 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 파일 선택 및 로드
  Future<void> pickAndLoadPdf() async {
    _setLoading(true);
    
    try {
      // 파일 선택 대화상자 표시
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          final pdfFile = File(file.path!);
          final fileSize = await pdfFile.length();
          
          // 고유 ID 생성
          final uuid = Uuid();
          final id = uuid.v4();
          
          // 문서 객체 생성
          final newDocument = PdfDocument(
            id: id,
            title: file.name.replaceAll('.pdf', ''),
            filePath: file.path,
            fileName: file.name,
            fileSize: fileSize,
            pageCount: 10, // 임시로 10 페이지로 설정, 실제로는 PDF 파싱 필요
          );
          
          // 문서 목록에 추가
          _documents.add(newDocument);
          
          // 현재 선택된 문서로 설정
          selectDocument(newDocument);
          
          _setError(null);
        }
      } else {
        // 사용자가 취소한 경우
        _setError(null);
      }
    } catch (e) {
      _setError('PDF 파일 선택 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 문서 선택
  void selectDocument(PdfDocument document) {
    _selectedDocument = document;
    _currentPage = 1;
    notifyListeners();
  }
  
  /// 페이지 변경
  void setCurrentPage(int page) {
    if (page < 1 || (_selectedDocument != null && page > _selectedDocument!.pageCount)) {
      return;
    }
    
    _currentPage = page;
    notifyListeners();
  }
  
  /// 북마크 추가
  void addBookmark(String title, int pageNumber) {
    if (_selectedDocument == null) return;
    
    // 고유 ID 생성
    final uuid = Uuid();
    final bookmarkId = uuid.v4();
    
    // 북마크 생성
    final bookmark = Bookmark(
      id: bookmarkId,
      title: title,
      pageNumber: pageNumber,
    );
    
    // 새 북마크 목록 생성
    final updatedBookmarks = List<Bookmark>.from(_selectedDocument!.bookmarks)..add(bookmark);
    
    // 새 문서 객체 생성 및 설정
    _selectedDocument = _selectedDocument!.copyWith(
      bookmarks: updatedBookmarks,
    );
    
    // 변경된 문서로 목록 업데이트
    final index = _documents.indexWhere((doc) => doc.id == _selectedDocument!.id);
    if (index >= 0) {
      _documents[index] = _selectedDocument!;
    }
    
    notifyListeners();
  }
  
  /// 북마크 제거
  void removeBookmark(Bookmark bookmark) {
    if (_selectedDocument == null) return;
    
    // 북마크 제거
    final updatedBookmarks = List<Bookmark>.from(_selectedDocument!.bookmarks)
      ..removeWhere((b) => b.id == bookmark.id);
    
    // 새 문서 객체 생성 및 설정
    _selectedDocument = _selectedDocument!.copyWith(
      bookmarks: updatedBookmarks,
    );
    
    // 변경된 문서로 목록 업데이트
    final index = _documents.indexWhere((doc) => doc.id == _selectedDocument!.id);
    if (index >= 0) {
      _documents[index] = _selectedDocument!;
    }
    
    notifyListeners();
  }
  
  /// 주석 추가
  void addAnnotation(String text, int pageNumber, Rect bounds) {
    if (_selectedDocument == null) return;
    
    // 고유 ID 생성
    final uuid = Uuid();
    final annotationId = uuid.v4();
    
    // 주석 생성
    final annotation = Annotation(
      id: annotationId,
      text: text,
      pageNumber: pageNumber,
      bounds: bounds,
    );
    
    // 새 주석 목록 생성
    final updatedAnnotations = List<Annotation>.from(_selectedDocument!.annotations)..add(annotation);
    
    // 새 문서 객체 생성 및 설정
    _selectedDocument = _selectedDocument!.copyWith(
      annotations: updatedAnnotations,
    );
    
    // 변경된 문서로 목록 업데이트
    final index = _documents.indexWhere((doc) => doc.id == _selectedDocument!.id);
    if (index >= 0) {
      _documents[index] = _selectedDocument!;
    }
    
    notifyListeners();
  }
  
  /// 주석 제거
  void removeAnnotation(Annotation annotation) {
    if (_selectedDocument == null) return;
    
    // 주석 제거
    final updatedAnnotations = List<Annotation>.from(_selectedDocument!.annotations)
      ..removeWhere((a) => a.id == annotation.id);
    
    // 새 문서 객체 생성 및 설정
    _selectedDocument = _selectedDocument!.copyWith(
      annotations: updatedAnnotations,
    );
    
    // 변경된 문서로 목록 업데이트
    final index = _documents.indexWhere((doc) => doc.id == _selectedDocument!.id);
    if (index >= 0) {
      _documents[index] = _selectedDocument!;
    }
    
    notifyListeners();
  }
  
  /// 문서 삭제
  void deleteDocument(String documentId) {
    // 문서 목록에서 제거
    _documents.removeWhere((doc) => doc.id == documentId);
    
    // 현재 선택된 문서가 삭제된 경우 선택 해제
    if (_selectedDocument != null && _selectedDocument!.id == documentId) {
      _selectedDocument = null;
    }
    
    notifyListeners();
  }
  
  /// 메모 텍스트 설정
  void setMemoText(String text) {
    _memoText = text;
    notifyListeners();
  }
  
  /// 로딩 상태 설정 (내부 유틸리티)
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 메시지 설정 (내부 유틸리티)
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
} 