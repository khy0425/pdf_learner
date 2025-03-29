import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/summarize_option.dart';
import '../utils/rate_limiter.dart';

/// AI 요약 상태
enum AISummaryState {
  /// 초기 상태
  initial,
  
  /// API 키 검증 중
  validatingKey,
  
  /// API 키 유효함
  keyValid,
  
  /// API 키 유효하지 않음
  keyInvalid,
  
  /// 로딩 중
  loading,
  
  /// 성공
  success,
  
  /// 오류 발생
  error
}

/// AI 요약 뷰모델
class AISummaryViewModel extends ChangeNotifier {
  /// AI 서비스
  final AiService _aiService;
  
  /// PDF 저장소
  final PDFRepository _pdfRepository;
  
  /// 요청 제한 관리
  final RateLimiter _rateLimiter;
  
  /// 상태
  AISummaryState _state = AISummaryState.initial;
  
  /// PDF 문서
  PDFDocument? _document;
  
  /// 문서 텍스트
  String _documentText = '';
  
  /// 요약 결과
  String _summary = '';
  
  /// 오류 메시지
  String? _errorMessage;
  
  /// 남은 요청 횟수
  int _remainingRequests = 0;
  
  /// 생성자
  AISummaryViewModel({
    required AiService aiService,
    required PDFRepository pdfRepository,
    required RateLimiter rateLimiter,
  }) : 
    _aiService = aiService,
    _pdfRepository = pdfRepository,
    _rateLimiter = rateLimiter;
  
  /// 상태 getter
  AISummaryState get state => _state;
  
  /// 요약 결과 getter
  String get summary => _summary;
  
  /// 오류 메시지 getter
  String? get errorMessage => _errorMessage;
  
  /// 남은 요청 횟수 getter
  int get remainingRequests => _remainingRequests;
  
  /// PDF 문서 getter
  PDFDocument? get document => _document;
  
  /// 초기화
  Future<void> initialize(String documentId) async {
    _setState(AISummaryState.initial);
    _errorMessage = null;
    
    try {
      // PDF 문서 로드
      final result = await _pdfRepository.getDocument(documentId);
      if (result.isFailure || result.data == null) {
        _setError('문서를 찾을 수 없습니다.');
        return;
      }
      
      _document = result.data;
      
      // 남은 요청 횟수 확인
      _remainingRequests = _rateLimiter.getRemainingRequests('pdf_summary');
      
      notifyListeners();
    } catch (e) {
      _setError('초기화 중 오류 발생: $e');
    }
  }
  
  /// 문서 요약
  Future<void> summarizeDocument(SummarizeOption option, {String? language}) async {
    if (_document == null) {
      _setError('요약할 문서가 없습니다.');
      return;
    }
    
    if (!_checkRemainingRequests()) {
      return;
    }
    
    _setState(AISummaryState.loading);
    
    try {
      // 문서 텍스트 추출 (필요한 경우)
      if (_documentText.isEmpty) {
        final bytesResult = await _pdfRepository.getPdfBytes(_document!.filePath);
        if (bytesResult.isFailure || bytesResult.data == null) {
          _setError('문서에서 텍스트를 추출할 수 없습니다.');
          return;
        }
        
        // 텍스트 추출 로직은 실제 프로젝트에 맞게 수정 필요
        _documentText = "문서 텍스트 추출 예시";
      }
      
      // 문서 요약
      final result = await _aiService.summarizeText(_documentText, option: option);
      
      _summary = result;
      
      // 요청 사용 처리
      _rateLimiter.addUsage('pdf_summary', 1);
      _remainingRequests = _rateLimiter.getRemainingRequests('pdf_summary');
      
      _setState(AISummaryState.success);
    } catch (e) {
      _setError('요약 중 오류 발생: $e');
    }
  }
  
  /// API 키 검증
  Future<bool> validateApiKey(String apiKey) async {
    _setState(AISummaryState.validatingKey);
    
    try {
      // AiService에 verifyApiKey 구현이 필요
      final isValid = false; // 임시 구현
      
      if (isValid) {
        _setState(AISummaryState.keyValid);
      } else {
        _setState(AISummaryState.keyInvalid);
        _setError('유효하지 않은 API 키입니다.');
      }
      
      return isValid;
    } catch (e) {
      _setState(AISummaryState.keyInvalid);
      _setError('API 키 검증 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 상태 설정
  void _setState(AISummaryState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String message) {
    _errorMessage = message;
    _setState(AISummaryState.error);
  }
  
  /// 남은 요청 수 확인
  bool _checkRemainingRequests() {
    if (_remainingRequests <= 0) {
      _setError('일일 요약 요청 제한에 도달했습니다. 내일 다시 시도해주세요.');
      return false;
    }
    return true;
  }
  
  /// 광고 시청으로 요청 추가
  Future<void> watchAdForMoreRequests() async {
    try {
      // 광고 시청 로직 (실제로는 광고 SDK와 연동)
      await Future.delayed(const Duration(seconds: 1));
      
      // 요청 횟수 추가
      _rateLimiter.addUsage('pdf_summary', -1); // 1회 추가
      _remainingRequests = _rateLimiter.getRemainingRequests('pdf_summary');
      
      notifyListeners();
    } catch (e) {
      _setError('광고 처리 중 오류 발생: $e');
    }
  }
  
  /// 요약 공유
  Future<void> shareSummary() async {
    if (_summary.isEmpty) {
      _setError('공유할 요약 내용이 없습니다.');
      return;
    }
    
    try {
      // 공유 로직 구현 (Share 패키지 사용 가정)
      // Share.share(_summary);
    } catch (e) {
      _setError('요약 공유 중 오류 발생: $e');
    }
  }
  
  /// 리소스 해제
  @override
  void dispose() {
    super.dispose();
  }
}