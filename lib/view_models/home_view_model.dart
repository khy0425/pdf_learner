import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // 타임아웃 예외 사용
import '../providers/pdf_provider.dart';
import '../main.dart';  // AppLogger 사용을 위한 import

/// 홈 화면의 ViewModel
/// PDF 파일 관련 상태와 로직을 관리합니다.
class HomeViewModel extends ChangeNotifier {
  bool _isLoading = false; // 초기 상태를 false로 변경
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;  // 초기화 상태 추가

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  
  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  set hasError(bool value) {
    _hasError = value;
    notifyListeners();
  }
  
  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }
  
  set isInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }
  
  /// PDF 파일 목록 로드
  Future<void> loadPDFs(BuildContext context) async {
    AppLogger.log('PDF 파일 로드 시작 (ViewModel)');
    
    _setLoadingState(true);
    _clearError();
    
    try {
      // PDFProvider 로드 작업에 10초 타임아웃 설정 (20초에서 10초로 줄임)
      await Future.any([
        _loadPDFsInternal(context),
        Future.delayed(const Duration(seconds: 10), () => 
          throw TimeoutException('PDF 파일 로드 작업 시간 초과 (10초)')
        ),
      ]);
      
      AppLogger.log('PDF 파일 로드 완료 (ViewModel)');
    } on TimeoutException catch (e) {
      AppLogger.error('PDF 파일 로드 타임아웃 (ViewModel)', e);
      _setError('PDF 파일 로드 시간이 초과되었습니다. 다시 시도해주세요.');
    } catch (e) {
      AppLogger.error('PDF 파일 로드 오류 (ViewModel)', e);
      _setError('PDF 파일 로드 중 오류: $e');
    } finally {
      _setLoadingState(false);
    }
  }
  
  /// 내부 PDF 로드 로직
  Future<void> _loadPDFsInternal(BuildContext context) async {
    // PDFProvider를 통해 저장된 PDF 파일 목록 불러오기
    await Provider.of<PDFProvider>(context, listen: false).loadSavedPDFs(context);
  }
  
  /// PDF 파일 선택
  Future<void> pickPDF(BuildContext context) async {
    try {
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      await pdfProvider.pickPDF(context);
    } catch (e) {
      AppLogger.error('PDF 선택 오류 (ViewModel)', e);
      
      // 에러 스낵바 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 파일 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// PDF 파일 삭제
  Future<void> deletePDF(BuildContext context, PDFProvider pdfProvider, PdfFileInfo pdfFile) async {
    try {
      // 삭제 확인 다이얼로그 표시
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF 파일 삭제'),
          content: Text('${pdfFile.fileName}을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirmed && context.mounted) {
        await pdfProvider.deletePDF(pdfFile, context);
      }
    } catch (e) {
      AppLogger.error('PDF 삭제 오류 (ViewModel)', e);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  /// 로딩 상태 설정
  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 에러 상태 설정
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// 에러 상태 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
} 