import 'dart:async';
import 'package:injectable/injectable.dart';

import 'api_key_service.dart';
import '../domain/models/summarize_option.dart';

/// AI 서비스 상태
enum AIServiceStatus {
  /// 초기 상태
  initial,
  
  /// 로드 중
  loading,
  
  /// 성공
  success,
  
  /// 오류
  error,
  
  /// API 키 없음
  noApiKey,
  
  /// 모델 로드 중
  loadingModel,
  
  /// 요청 제한
  rateLimited,
}

/// AI 서비스 인터페이스
@lazySingleton
class AiService {
  /// API 키 서비스
  final ApiKeyService _apiKeyService;
  
  /// 현재 AI 서비스 상태
  AIServiceStatus _status = AIServiceStatus.initial;
  
  /// 상태 스트림 컨트롤러
  final StreamController<AIServiceStatus> _statusController = StreamController<AIServiceStatus>.broadcast();
  
  /// 응답 스트림 컨트롤러
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  
  /// 오류 메시지
  String _errorMessage = '';
  
  /// 생성자
  AiService({
    required ApiKeyService apiKeyService,
  }) : _apiKeyService = apiKeyService {
    _init();
  }
  
  /// 초기화
  Future<void> _init() async {
    final hasApiKey = await _apiKeyService.hasGeminiApiKey() || await _apiKeyService.hasOpenAIApiKey();
    _setStatus(hasApiKey ? AIServiceStatus.initial : AIServiceStatus.noApiKey);
  }
  
  /// 상태 스트림
  Stream<AIServiceStatus> get statusStream => _statusController.stream;
  
  /// 응답 스트림
  Stream<String> get responseStream => _responseController.stream;
  
  /// 현재 상태
  AIServiceStatus get status => _status;
  
  /// 오류 메시지
  String get errorMessage => _errorMessage;
  
  /// 상태 설정
  void _setStatus(AIServiceStatus status) {
    _status = status;
    _statusController.add(status);
  }
  
  /// 오류 설정
  void _setError(String message) {
    _errorMessage = message;
    _setStatus(AIServiceStatus.error);
  }
  
  /// 텍스트로부터 요약 생성
  Future<String> summarizeText(String text, {SummarizeOption option = SummarizeOption.normal}) async {
    try {
      if (text.isEmpty) {
        return '';
      }
      
      _setStatus(AIServiceStatus.loading);
      
      // API 키 확인
      final geminiApiKey = await _apiKeyService.getGeminiApiKey();
      final openAIApiKey = await _apiKeyService.getOpenAIApiKey();
      
      if ((geminiApiKey == null || geminiApiKey.isEmpty) && 
          (openAIApiKey == null || openAIApiKey.isEmpty)) {
        _setStatus(AIServiceStatus.noApiKey);
        return '🔑 API 키가 설정되지 않았습니다. 설정에서 API 키를 추가해주세요.';
      }
      
      // TODO: 실제 AI API 호출 로직 구현
      // 지금은 임시 구현으로 대체
      await Future.delayed(const Duration(seconds: 2));
      
      String summary = '';
      switch (option) {
        case SummarizeOption.short:
          summary = '짧은 요약: ${text.substring(0, text.length > 100 ? 100 : text.length)}...';
          break;
        case SummarizeOption.normal:
          summary = '일반 요약: ${text.substring(0, text.length > 200 ? 200 : text.length)}...';
          break;
        case SummarizeOption.detailed:
          summary = '상세 요약: ${text.substring(0, text.length > 300 ? 300 : text.length)}...';
          break;
        case SummarizeOption.bullets:
          summary = '• 첫 번째 요점\n• 두 번째 요점\n• 세 번째 요점';
          break;
      }
      
      _setStatus(AIServiceStatus.success);
      return summary;
      
    } catch (e) {
      _setError('요약 생성 중 오류가 발생했습니다: $e');
      return '요약 생성 중 오류가 발생했습니다.';
    }
  }
  
  /// 문서에 대한 질문에 답변
  Future<String> askQuestion(String documentText, String question) async {
    try {
      if (documentText.isEmpty || question.isEmpty) {
        return '';
      }
      
      _setStatus(AIServiceStatus.loading);
      
      // API 키 확인
      final geminiApiKey = await _apiKeyService.getGeminiApiKey();
      final openAIApiKey = await _apiKeyService.getOpenAIApiKey();
      
      if ((geminiApiKey == null || geminiApiKey.isEmpty) && 
          (openAIApiKey == null || openAIApiKey.isEmpty)) {
        _setStatus(AIServiceStatus.noApiKey);
        return '🔑 API 키가 설정되지 않았습니다. 설정에서 API 키를 추가해주세요.';
      }
      
      // TODO: 실제 AI API 호출 로직 구현
      // 지금은 임시 구현으로 대체
      await Future.delayed(const Duration(seconds: 2));
      
      String answer = '질문: $question\n\n';
      answer += '답변: 문서를 분석한 결과, 해당 질문에 대한 답변은...';
      
      _setStatus(AIServiceStatus.success);
      return answer;
      
    } catch (e) {
      _setError('질문 답변 중 오류가 발생했습니다: $e');
      return '질문 답변 중 오류가 발생했습니다.';
    }
  }
  
  /// 마인드맵 생성
  Future<List<Map<String, dynamic>>> generateMindMap(String text) async {
    try {
      if (text.isEmpty) {
        return [];
      }
      
      _setStatus(AIServiceStatus.loading);
      
      // API 키 확인
      final geminiApiKey = await _apiKeyService.getGeminiApiKey();
      final openAIApiKey = await _apiKeyService.getOpenAIApiKey();
      
      if ((geminiApiKey == null || geminiApiKey.isEmpty) && 
          (openAIApiKey == null || openAIApiKey.isEmpty)) {
        _setStatus(AIServiceStatus.noApiKey);
        return [];
      }
      
      // TODO: 실제 AI API 호출 로직 구현
      // 지금은 임시 구현으로 대체
      await Future.delayed(const Duration(seconds: 2));
      
      final List<Map<String, dynamic>> mindMap = [
        {
          'id': '1',
          'label': '중심 주제',
          'children': [
            {
              'id': '2',
              'label': '하위 주제 1',
              'children': [
                {'id': '3', 'label': '상세 내용 1'},
                {'id': '4', 'label': '상세 내용 2'},
              ]
            },
            {
              'id': '5',
              'label': '하위 주제 2',
              'children': [
                {'id': '6', 'label': '상세 내용 3'},
                {'id': '7', 'label': '상세 내용 4'},
              ]
            },
          ]
        }
      ];
      
      _setStatus(AIServiceStatus.success);
      return mindMap;
      
    } catch (e) {
      _setError('마인드맵 생성 중 오류가 발생했습니다: $e');
      return [];
    }
  }
  
  /// 퀴즈 생성
  Future<List<Map<String, dynamic>>> generateQuiz(String text, int numberOfQuestions) async {
    try {
      if (text.isEmpty || numberOfQuestions <= 0) {
        return [];
      }
      
      _setStatus(AIServiceStatus.loading);
      
      // API 키 확인
      final geminiApiKey = await _apiKeyService.getGeminiApiKey();
      final openAIApiKey = await _apiKeyService.getOpenAIApiKey();
      
      if ((geminiApiKey == null || geminiApiKey.isEmpty) && 
          (openAIApiKey == null || openAIApiKey.isEmpty)) {
        _setStatus(AIServiceStatus.noApiKey);
        return [];
      }
      
      // TODO: 실제 AI API 호출 로직 구현
      // 지금은 임시 구현으로 대체
      await Future.delayed(const Duration(seconds: 2));
      
      final List<Map<String, dynamic>> quizQuestions = [];
      
      for (int i = 0; i < numberOfQuestions; i++) {
        quizQuestions.add({
          'question': '문제 ${i + 1}: 이것은 샘플 문제입니다.',
          'options': [
            '보기 1',
            '보기 2',
            '보기 3',
            '보기 4',
          ],
          'correctAnswerIndex': 0,
          'explanation': '해설: 이 문제에 대한 설명입니다.',
        });
      }
      
      _setStatus(AIServiceStatus.success);
      return quizQuestions;
      
    } catch (e) {
      _setError('퀴즈 생성 중 오류가 발생했습니다: $e');
      return [];
    }
  }
  
  /// 자원 정리
  void dispose() {
    _statusController.close();
    _responseController.close();
  }
} 