import 'dart:async';
// 플랫폼에 따라 다른 임포트
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 웹이 아닌 경우에만 path_provider 임포트
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_document.dart';
import '../repositories/pdf_repository.dart';

/// PDF 뷰어 뷰모델
class PdfViewerViewModel extends ChangeNotifier {
  final PdfRepository _repository;
  
  // 로딩 상태
  bool _isLoading = false;
  String? _errorMessage;
  PDFDocument? _document;
  
  /// 생성자
  PdfViewerViewModel({
    required PdfRepository repository,
  }) : _repository = repository;
  
  /// 로딩 상태 여부
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get errorMessage => _errorMessage;
  
  /// 현재 문서
  PDFDocument? get document => _document;
  
  /// 문서 로드
  Future<void> loadDocument(PDFDocument document) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // 최종 방문 시간 업데이트
      await _repository.updateLastOpenedAt(document.id);
      
      _document = document;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '문서 로드 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }
  
  /// 북마크 추가
  Future<bool> addBookmark(String title, int pageNumber, double scrollPosition) async {
    if (_document == null) return false;
    
    try {
      // 북마크 추가 로직 구현
      return true;
    } catch (e) {
      _errorMessage = '북마크 추가 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// 북마크 제거
  Future<bool> removeBookmark(String bookmarkId) async {
    if (_document == null) return false;
    
    try {
      // 북마크 제거 로직 구현
      return true;
    } catch (e) {
      _errorMessage = '북마크 제거 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }
} 