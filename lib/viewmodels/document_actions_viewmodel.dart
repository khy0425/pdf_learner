import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/pdf_document.dart';
import '../models/sort_option.dart';
import '../repositories/pdf_repository.dart';
import '../services/file_picker_service.dart';
import '../viewmodels/document_list_viewmodel.dart';

/// 문서 관련 액션(추가, 삭제, 공유 등)을 처리하는 ViewModel
class DocumentActionsViewModel extends ChangeNotifier {
  final PdfRepository _repository;
  final DocumentListViewModel _listViewModel;
  final FilePickerService _filePickerService;
  bool _isLoading = false;
  String? _errorMessage;
  
  /// 생성자
  DocumentActionsViewModel({
    required PdfRepository repository,
    required DocumentListViewModel listViewModel,
    required FilePickerService filePickerService,
  }) : _repository = repository,
       _listViewModel = listViewModel,
       _filePickerService = filePickerService;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 에러 메시지
  String? get errorMessage => _errorMessage;
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 에러 메시지 설정
  void _setErrorMessage(String? message) {
    _errorMessage = message;
    if (message != null) {
      debugPrint('오류: $message');
    }
    notifyListeners();
  }
  
  /// 문서 삭제
  Future<bool> deleteDocument(PDFDocument document) async {
    try {
      _setLoading(true);
      final success = await _repository.deleteDocument(document.id);
      
      if (success) {
        await _listViewModel.loadDocuments();
        return true;
      }
      
      _setErrorMessage('문서 삭제에 실패했습니다.');
      return false;
    } catch (e) {
      _setErrorMessage('문서 삭제 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 문서 이름 변경
  Future<bool> renameDocument(String documentId, String newTitle) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final result = await _repository.renameDocument(documentId, newTitle);
      _setLoading(false);
      if (result) {
        // 이름 변경 성공 시 문서 목록 갱신
        await _listViewModel.loadDocuments();
      }
      return result;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage('문서 이름 변경 실패: $e');
      return false;
    }
  }
  
  /// 파일에서 PDF 추가 (모바일 환경)
  Future<bool> addPdfFromFile(dynamic file, String title) async {
    try {
      _setLoading(true);
      
      // 파일 객체에 따라 처리 (dart:io File 또는 web_stub File)
      final document = await _repository.addDocumentFromFile(file, title);
      
      if (document != null) {
        await _listViewModel.loadDocuments();
        return true;
      }
      
      _setErrorMessage('PDF 파일 추가에 실패했습니다.');
      return false;
    } catch (e) {
      _setErrorMessage('PDF 파일 추가 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// URL에서 PDF 추가
  Future<bool> addDocumentFromUrl(String url) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);
      
      if (!url.toLowerCase().endsWith('.pdf') && !url.contains('.pdf?')) {
        _setErrorMessage('PDF URL만 지원합니다.');
        return false;
      }
      
      // URL에서 이름 추출
      final name = url.split('/').last.replaceAll('.pdf', '');
      final document = await _repository.addDocumentFromUrl(url, name);
      
      if (document != null) {
        // 문서 목록 새로고침
        await _listViewModel.loadDocuments();
        return true;
      } else {
        _setErrorMessage('PDF 추가 실패');
        return false;
      }
    } catch (e) {
      _setErrorMessage('PDF 추가 중 오류 발생: $e');
      debugPrint('PDF 추가 중 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// URL에서 PDF 추가 (이름 지정)
  Future<bool> addPdfFromUrl(String url, String name) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);
      
      if (!url.toLowerCase().endsWith('.pdf') && !url.contains('.pdf?')) {
        _setErrorMessage('PDF URL만 지원합니다.');
        return false;
      }
      
      final document = await _repository.addDocumentFromUrl(url, name);
      
      if (document != null) {
        // 문서 목록 새로고침
        await _listViewModel.loadDocuments();
        return true;
      } else {
        _setErrorMessage('PDF 추가 실패');
        return false;
      }
    } catch (e) {
      _setErrorMessage('PDF 추가 중 오류 발생: $e');
      debugPrint('PDF 추가 중 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 바이트 데이터에서 PDF 추가 (웹 환경)
  Future<bool> addPdfFromBytes(Uint8List bytes, String title) async {
    try {
      _setLoading(true);
      final document = await _repository.addDocumentFromBytes(bytes, title);
      
      if (document != null) {
        await _listViewModel.loadDocuments();
        return true;
      }
      
      _setErrorMessage('PDF 추가에 실패했습니다.');
      return false;
    } catch (e) {
      _setErrorMessage('PDF 추가 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 샘플 PDF 추가
  Future<bool> addSamplePdf() async {
    try {
      _setLoading(true);
      _setErrorMessage(null);
      
      const url = 'https://www.africau.edu/images/default/sample.pdf';
      final name = url.split('/').last.replaceAll('.pdf', '');
      final document = await _repository.addDocumentFromUrl(url, name);
      
      if (document != null) {
        // 문서 목록 새로고침
        await _listViewModel.loadDocuments();
        return true;
      } else {
        _setErrorMessage('샘플 PDF 추가 실패');
        return false;
      }
    } catch (e) {
      _setErrorMessage('샘플 PDF 추가 중 오류 발생: $e');
      debugPrint('샘플 PDF 추가 중 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 기기에서 PDF 추가
  Future<bool> addDocumentFromDevice() async {
    try {
      _setLoading(true);
      _setErrorMessage(null);
      
      // 파일 선택 다이얼로그 표시
      final result = await _filePickerService.pickPdf();
      
      if (result == null) {
        // 사용자가 파일 선택을 취소함
        return false;
      }
      
      if (kIsWeb) {
        // 웹 환경에서는 바이트로 처리
        final bytes = result.bytes;
        final name = result.name.replaceAll('.pdf', '');
        
        if (bytes != null) {
          // Uint8List로 변환하여 전달
          final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
          final document = await _repository.addDocumentFromBytes(uint8Bytes, name);
          
          if (document != null) {
            // 문서 목록 새로고침
            await _listViewModel.loadDocuments();
            return true;
          }
        }
      } else {
        // 모바일 환경에서는 파일로 처리
        final path = result.path;
        final name = result.name.replaceAll('.pdf', '');
        
        if (path != null) {
          final file = io.File(path);
          final document = await _repository.addDocumentFromFile(file, name);
          
          if (document != null) {
            // 문서 목록 새로고침
            await _listViewModel.loadDocuments();
            return true;
          }
        }
      }
      
      _setErrorMessage('PDF 추가 실패');
      return false;
    } catch (e) {
      _setErrorMessage('PDF 추가 중 오류 발생: $e');
      debugPrint('PDF 추가 중 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 정렬 옵션 설정
  void setSortOption(SortOption sortOption) {
    _listViewModel.setSortOption(sortOption);
  }
  
  /// 문서 검색
  void searchDocuments(String query) {
    _listViewModel.setSearchQuery(query);
  }
  
  /// 오류 메시지 지우기
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}