import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_learner_v2/models/ai_summary.dart';
import 'package:pdf_learner_v2/services/api_keys.dart';
import 'package:pdf_learner_v2/services/api_key_service.dart';
import 'package:pdf_learner_v2/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_learner_v2/services/secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pdf_document.dart';
import '../repositories/pdf_repository.dart';
import '../services/ai_service.dart';
import '../utils/rate_limiter.dart';

/// Gemini API 요청 결과 상태
enum ApiRequestStatus {
  idle,
  loading,
  success,
  error,
}

/// AI 요약 ViewModel
class AiSummaryViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  final AiService _aiService;
  final RateLimiter _rateLimiter;
  
  // 상태 변수
  bool _isLoading = false;
  String _startPage = '1';
  String _endPage = '1';
  AiSummary? _currentSummary;
  String? _errorMessage;
  PDFDocument? _document;
  
  // 게터
  bool get isLoading => _isLoading;
  String get startPage => _startPage;
  String get endPage => _endPage;
  AiSummary? get currentSummary => _currentSummary;
  String? get errorMessage => _errorMessage;
  bool get hasSummary => _currentSummary != null;
  
  /// 생성자
  AiSummaryViewModel({
    required PDFRepository repository,
    required AiService aiService,
    required RateLimiter rateLimiter,
  }) : _repository = repository,
       _aiService = aiService,
       _rateLimiter = rateLimiter;
  
  /// 초기화
  Future<void> initialize(String documentId, PDFDocument? document) async {
    try {
      if (document == null) {
        _document = await _repository.getDocumentById(documentId);
      } else {
        _document = document;
      }
      
      if (_document != null && _document!.pageCount > 0) {
        _endPage = _document!.pageCount.toString();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '문서 로드 중 오류 발생: $e';
      notifyListeners();
    }
  }
  
  /// 시작 페이지 설정
  void setStartPage(String page) {
    _startPage = page;
    notifyListeners();
  }
  
  /// 종료 페이지 설정
  void setEndPage(String page) {
    _endPage = page;
    notifyListeners();
  }
  
  /// 요약 생성
  Future<void> generateSummary() async {
    if (_document == null) {
      _errorMessage = '문서 정보를 로드할 수 없습니다';
      notifyListeners();
      return;
    }
    
    // 페이지 범위 유효성 검사
    final startPage = int.tryParse(_startPage);
    final endPage = int.tryParse(_endPage);
    final pageCount = _document!.pageCount;
    
    if (startPage == null || endPage == null) {
      _errorMessage = '유효한 페이지 번호를 입력하세요';
      notifyListeners();
      return;
    }
    
    if (startPage < 1 || startPage > pageCount) {
      _errorMessage = '시작 페이지는 1부터 $pageCount까지 입력해주세요';
      notifyListeners();
      return;
    }
    
    if (endPage < startPage || endPage > pageCount) {
      _errorMessage = '종료 페이지는 시작 페이지부터 $pageCount까지 입력해주세요';
      notifyListeners();
      return;
    }
    
    // 요청 제한 확인
    final isAllowed = await _rateLimiter.checkRequest('ai_summary');
    if (!isAllowed) {
      _errorMessage = '요청이 너무 많습니다. 잠시 후 다시 시도해주세요';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // PDF 텍스트 추출
      final extractedText = await _repository.extractText(
        _document!.id,
        startPage,
        endPage,
      );
      
      // AI 요약 생성
      final summary = await _aiService.generateSummary(
        text: extractedText,
        documentId: _document!.id,
      );
      
      if (summary != null) {
        _currentSummary = summary;
      } else {
        _errorMessage = '요약 생성에 실패했습니다';
      }
    } catch (e) {
      _errorMessage = '요약 생성 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 요약 초기화
  void resetSummary() {
    _currentSummary = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 요약 공유
  void shareSummary() {
    if (_currentSummary == null) return;
    
    final summaryText = '''
주요 내용:
${_currentSummary!.summary}

핵심 키워드:
${_currentSummary!.keywords}

중요 개념:
${_currentSummary!.keyPoints}

- PDF Learner V2로 생성된 요약
''';

    Share.share(summaryText, subject: 'PDF 요약');
  }
} 