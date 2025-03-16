import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_model.dart';
import '../view_models/pdf_view_model.dart';
import '../view_models/auth_view_model.dart';

/// 홈 화면의 ViewModel
/// PDF 파일 관련 상태와 로직을 관리합니다.
class HomeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  /// PDF 파일 목록 로드
  Future<void> loadPDFs(String userId) async {
    debugPrint('PDF 파일 로드 시작 (HomeViewModel)');
    
    _setLoading(true);
    _clearError();
    
    try {
      // 10초 타임아웃 설정
      await Future.any([
        _loadPDFsInternal(userId),
        Future.delayed(const Duration(seconds: 10), () => 
          throw TimeoutException('PDF 파일 로드 작업 시간 초과 (10초)')
        ),
      ]);
      
      _isInitialized = true;
      debugPrint('PDF 파일 로드 완료 (HomeViewModel)');
    } on TimeoutException catch (e) {
      debugPrint('PDF 파일 로드 타임아웃 (HomeViewModel): $e');
      _setError('PDF 파일 로드 시간이 초과되었습니다. 다시 시도해주세요.');
    } catch (e) {
      debugPrint('PDF 파일 로드 오류 (HomeViewModel): $e');
      _setError('PDF 파일 로드 중 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 내부 PDF 로드 로직
  Future<void> _loadPDFsInternal(String userId) async {
    // 이 메서드는 실제 구현에서 PdfViewModel을 통해 PDF 목록을 로드합니다.
    // 이 메서드는 HomeViewModel 내부에서만 사용됩니다.
  }
  
  /// 파일에서 PDF 업로드
  Future<void> pickPdfFromFile(BuildContext context, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 파일 선택 다이얼로그 표시
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result == null || result.files.isEmpty) {
        debugPrint('파일 선택 취소됨');
        _setLoading(false);
        return;
      }
      
      final file = File(result.files.first.path!);
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // PDF 업로드
      await pdfViewModel.uploadPdfFromFile(file, userId);
      
      // 성공 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 파일이 업로드되었습니다')),
        );
      }
      
      // PDF 목록 새로고침
      await loadPDFs(userId);
    } catch (e) {
      debugPrint('PDF 파일 업로드 오류: $e');
      _setError('PDF 파일을 업로드할 수 없습니다: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 업로드 실패: $e')),
        );
      }
    } finally {
      _setLoading(false);
    }
  }
  
  /// URL에서 PDF 업로드
  Future<void> pickPdfFromUrl(BuildContext context, String url, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (url.isEmpty) {
        throw Exception('URL이 비어있습니다');
      }
      
      if (!url.toLowerCase().endsWith('.pdf') && !url.toLowerCase().contains('pdf')) {
        throw Exception('유효한 PDF URL이 아닙니다');
      }
      
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // PDF 업로드
      await pdfViewModel.uploadPdfFromUrl(url, userId);
      
      // 성공 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 파일이 업로드되었습니다')),
        );
      }
      
      // PDF 목록 새로고침
      await loadPDFs(userId);
    } catch (e) {
      debugPrint('URL에서 PDF 업로드 오류: $e');
      _setError('URL에서 PDF를 업로드할 수 없습니다: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL에서 PDF 업로드 실패: $e')),
        );
      }
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(BuildContext context, String pdfId, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // PDF 삭제
      await pdfViewModel.deletePdf(pdfId, userId);
      
      // 성공 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 파일이 삭제되었습니다')),
        );
      }
      
      // PDF 목록 새로고침
      await loadPDFs(userId);
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      _setError('PDF를 삭제할 수 없습니다: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 삭제 실패: $e')),
        );
      }
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 오류 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
} 