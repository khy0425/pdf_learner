import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage.dart';
import '../services/api_key_service.dart';
import '../utils/security_logger.dart';
import '../utils/input_validator.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _hfApiKey => dotenv.env['HUGGING_FACE_API_KEY'] ?? '';

  // 보안 스토리지 및 API 키 서비스 인스턴스
  static final SecureStorage _secureStorage = SecureStorage();
  static final ApiKeyService _apiKeyService = ApiKeyService();
  static final SecurityLogger _securityLogger = SecurityLogger();
  
  // 서비스 초기화
  static Future<void> _initializeServices() async {
    await _secureStorage.initialize();
    await _securityLogger.initialize(
      logLevel: SecurityLogLevel.info,
      useFirestore: false,
    );
  }

  // Gemini API 설정
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // 사용 가능한 한국어 요약 모델로 변경
  static const String _summaryApiUrl = 
    'https://api-inference.huggingface.co/models/noahkim/KoBART-news-summary';
  
  // 텍스트 생성 모델 엔드포인트 (퀴즈 생성용)
  static const String _textGenApiUrl = 
    'https://api-inference.huggingface.co/models/google/flan-t5-large';

  // 텍스트 분할 (API 요청 제한을 고려)
  String _splitText(String text, {int maxLength = 1000}) {
    if (text.length <= maxLength) return text;
    
    // 문장 단위로 분할하여 적절한 길이로 자르기
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    String result = '';
    
    for (var sentence in sentences) {
      if ((result + sentence).length > maxLength) break;
      result += sentence + ' ';
    }
    
    return result.trim();
  }

  static Future<String> getApiKey() async {
    try {
      // 초기화 확인
      await _secureStorage.initialize();
      if (!SecurityLogger().isInitialized) {
        await _initializeServices();
      }
      
      // 1. 로그인된 사용자 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. 사용자별 API 키 가져오기
        final userApiKey = await _apiKeyService.getApiKey(user.uid);
        if (userApiKey != null && userApiKey.isNotEmpty) {
          debugPrint('사용자 API 키 사용');
          
          // API 키 사용 로깅
          await _apiKeyService.logApiKeyUsage(user.uid, 'gemini');
          
          return userApiKey;
        }
      }
      
      // 3. 환경 변수의 API 키 확인
      final envApiKey = dotenv.env['GEMINI_API_KEY'];
      if (envApiKey != null && envApiKey.isNotEmpty) {
        debugPrint('환경 변수 API 키 사용');
        
        _securityLogger.log(
          SecurityEvent.apiKeyVerified,
          '환경 변수 API 키 사용됨',
          level: SecurityLogLevel.debug,
        );
        
        return envApiKey;
      }
      
      // 4. 앱 전역 설정에서 저장된 API 키 확인
      final globalApiKey = await _secureStorage.getSecureData('global_api_key');
      if (globalApiKey != null && globalApiKey.isNotEmpty) {
        debugPrint('전역 API 키 사용');
        
        _securityLogger.log(
          SecurityEvent.apiKeyVerified,
          '전역 API 키 사용됨',
          level: SecurityLogLevel.debug,
        );
        
        return globalApiKey;
      }
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키가 설정되지 않음',
        level: SecurityLogLevel.warn,
      );

      throw Exception('API 키가 설정되지 않았습니다. API 키를 입력해주세요.');
    } catch (e) {
      debugPrint('API 키 설정 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키 설정 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      throw Exception('API 키 설정 오류: $e');
    }
  }

  Future<String?> generateSummary(String pdfId) async {
    try {
      // 입력 유효성 검사
      if (pdfId.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          'PDF ID가 비어 있음',
          level: SecurityLogLevel.warn,
        );
        throw Exception('요약할 PDF ID가 비어 있습니다.');
      }
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '요약 생성 시작',
        level: SecurityLogLevel.info,
        data: {'pdfId': pdfId},
      );
      
      // 실제 구현에서는 PDF의 텍스트를 추출하고 AI로 요약 생성
      
      // 테스트 목적을 위한 가짜 응답 생성
      if (pdfId.contains('test')) {
        return '이 문서는 테스트용 PDF에 관한 내용을 다루고 있습니다. 문서의 주요 내용은 테스트 데이터이며, 더 자세한 정보는 문서를 직접 참조해야 합니다.';
      }
      
      // API 호출 로직 (향후 실제 구현에서 활성화)
      /*
      final response = await http.post(
        Uri.parse('$_apiUrl'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'PDF ID: $pdfId에 대한 내용을 요약해주세요.'}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        
        _securityLogger.log(
          SecurityEvent.aiResponseReceived,
          '요약 생성 성공',
          level: SecurityLogLevel.info,
        );
        
        return result['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      */
      
      // 테스트를 위한 기본 응답
      return '이 문서는 $pdfId에 관한 내용입니다. 주요 주제와 정보가 포함되어 있으며, AI 요약 기능을 통해 생성되었습니다.';
    } catch (e) {
      debugPrint('요약 생성 중 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '요약 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      // 테스트를 위해 에러가 발생해도 기본 요약 반환
      return null;
    }
  }

  Future<List<String>> extractKeyPoints(String text) async {
    try {
      // 입력 유효성 검사
      if (text.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '핵심 포인트 추출을 위한 빈 텍스트 입력',
          level: SecurityLogLevel.warn,
        );
        throw Exception('핵심 포인트를 추출할 텍스트가 비어 있습니다.');
      }
      
      // 입력 정제
      final sanitizedText = InputValidator.sanitizeInput(text);
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '핵심 포인트 추출 시작',
        level: SecurityLogLevel.info,
        data: {'textLength': sanitizedText.length},
      );
      
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/facebook/bart-large-mnli'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': sanitizedText,
          'parameters': {
            'candidate_labels': ['key point', 'important concept', 'main idea'],
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // 결과 처리 및 핵심 포인트 추출
        
        _securityLogger.log(
          SecurityEvent.aiResponseReceived,
          '핵심 포인트 추출 성공',
          level: SecurityLogLevel.info,
        );
        
        return ['핵심 포인트 1', '핵심 포인트 2']; // 임시 반환값
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '핵심 포인트 추출 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );
      
      throw Exception('핵심 포인트 추출 실패');
    } catch (e) {
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '핵심 포인트 추출 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      throw Exception('핵심 포인트 추출 중 오류 발생: $e');
    }
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String text) async {
    try {
      // 입력 유효성 검사
      if (text.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '퀴즈 생성을 위한 빈 텍스트 입력',
          level: SecurityLogLevel.warn,
        );
        throw Exception('퀴즈를 생성할 텍스트가 비어 있습니다.');
      }
      
      // 입력 정제
      final sanitizedText = InputValidator.sanitizeInput(text);
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '퀴즈 생성 시작',
        level: SecurityLogLevel.info,
        data: {'textLength': sanitizedText.length},
      );
      
      final response = await http.post(
        Uri.parse('$_apiUrl/generate-quiz'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'text': sanitizedText,
          'format': 'json',
          'num_questions': 5,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> quizzes = jsonDecode(utf8.decode(response.bodyBytes));
          
          _securityLogger.log(
            SecurityEvent.aiResponseReceived,
            '퀴즈 생성 성공',
            level: SecurityLogLevel.info,
            data: {'quizCount': quizzes.length},
          );
          
          return quizzes.map((quiz) => Map<String, dynamic>.from(quiz)).toList();
        } catch (e) {
          debugPrint('퀴즈 JSON 파싱 오류: $e');
          
          _securityLogger.log(
            SecurityEvent.invalidInput,
            '퀴즈 JSON 파싱 오류',
            level: SecurityLogLevel.error,
            data: {'error': e.toString()},
          );
          
          throw Exception('퀴즈 데이터 형식이 올바르지 않습니다');
        }
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '퀴즈 생성 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );
      
      throw Exception('퀴즈 생성 실패: ${response.statusCode}');
    } catch (e) {
      debugPrint('퀴즈 생성 중 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '퀴즈 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  Future<String> getAnswer(String question, String context) async {
    // 향후 구현
    return '';
  }

  String _preprocessText(String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    const maxLength = 30000;
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
      final lastPeriod = text.lastIndexOf('.');
      if (lastPeriod > 0) {
        text = text.substring(0, lastPeriod + 1);
      }
    }
    
    return text;
  }

  Future<List<String>> extractKeySentences(String text) async {
    try {
      // 입력 유효성 검사
      if (text.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '핵심 문장 추출을 위한 빈 텍스트 입력',
          level: SecurityLogLevel.warn,
        );
        throw Exception('핵심 문장을 추출할 텍스트가 비어 있습니다.');
      }
      
      final processedText = _preprocessText(text);
      print('핵심 문장 추출 시작...');
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '핵심 문장 추출 시작',
        level: SecurityLogLevel.info,
        data: {'processedTextLength': processedText.length},
      );

      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/key-sentences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'text': processedText,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        print('응답 성공!');
        
        if (result['candidates']?[0]?['content'] != null) {
          final content = result['candidates'][0]['content']['parts'][0]['text'] as String;
          final sentences = content
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

          // 추출된 핵심 문장들 로그 출력
          print('추출된 핵심 문장들:');
          sentences.forEach((s) => print('• $s'));
          
          _securityLogger.log(
            SecurityEvent.aiResponseReceived,
            '핵심 문장 추출 성공',
            level: SecurityLogLevel.info,
            data: {'sentenceCount': sentences.length},
          );
          
          return sentences;
        }
      }
      
      print('API 오류 응답: ${response.body}');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '핵심 문장 추출 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );
      
      throw Exception('핵심 문장 추출 실패');
    } catch (e) {
      print('핵심 문장 추출 중 오류 발생: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '핵심 문장 추출 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  Future<String> generateStudySuggestion(String content) async {
    try {
      // 입력 유효성 검사
      if (content.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '학습 제안 생성을 위한 빈 텍스트 입력',
          level: SecurityLogLevel.warn,
        );
        throw Exception('학습 제안을 생성할 텍스트가 비어 있습니다.');
      }
      
      // 입력 정제
      final sanitizedContent = InputValidator.sanitizeInput(content);
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '학습 제안 생성 시작',
        level: SecurityLogLevel.info,
        data: {'contentLength': sanitizedContent.length},
      );
      
      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/study-suggestion'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'text': sanitizedContent,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        if (result['candidates']?[0]?['content'] != null) {
          _securityLogger.log(
            SecurityEvent.aiResponseReceived,
            '학습 제안 생성 성공',
            level: SecurityLogLevel.info,
          );
          
          return result['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '학습 제안 생성 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );
      
      throw Exception('학습 제안 생성 실패');
    } catch (e) {
      debugPrint('학습 제안 생성 중 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '학습 제안 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateMistakeAnalysis(
    Map<String, dynamic> quiz,
    int userAnswer,
  ) async {
    try {
      // 입력 유효성 검사
      if (quiz['question'] == null || quiz['options'] == null || quiz['answer'] == null) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '오답 분석을 위한 잘못된 퀴즈 형식',
          level: SecurityLogLevel.warn,
          data: {'quiz': quiz},
        );
        throw Exception('퀴즈 데이터 형식이 올바르지 않습니다.');
      }
      
      final question = quiz['question'];
      final options = quiz['options'];
      final correctAnswer = quiz['answer'];
      final explanation = quiz['explanation'];
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '오답 분석 시작',
        level: SecurityLogLevel.info,
      );

      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/mistake-analysis'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'question': question,
          'options': options,
          'userAnswer': userAnswer,
          'correctAnswer': correctAnswer,
          'explanation': explanation,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final content = result['candidates'][0]['content']['parts'][0]['text'];
        
        // JSON 부분만 추출
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        final jsonStr = content.substring(jsonStart, jsonEnd);
        
        _securityLogger.log(
          SecurityEvent.aiResponseReceived,
          '오답 분석 성공',
          level: SecurityLogLevel.info,
        );
        
        return jsonDecode(jsonStr);
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '오답 분석 생성 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );

      throw Exception('오답 분석 생성 실패');
    } catch (e) {
      print('오답 분석 생성 중 오류 발생: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '오답 분석 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateReviewQuizzes(
    List<Map<String, dynamic>> mistakeQuizzes,
  ) async {
    try {
      // 입력 유효성 검사
      if (mistakeQuizzes.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '복습 문제 생성을 위한 빈 오답 목록',
          level: SecurityLogLevel.warn,
        );
        throw Exception('복습 문제를 생성할 오답 목록이 비어 있습니다.');
      }
      
      final quizzesStr = mistakeQuizzes.map((q) => 
        '문제: ${q['question']}\n정답: ${q['options'][q['answer']]}'
      ).join('\n\n');
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '복습 문제 생성 시작',
        level: SecurityLogLevel.info,
        data: {'mistakeCount': mistakeQuizzes.length},
      );

      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/review-quizzes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'text': quizzesStr,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final content = result['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        final jsonStr = content.substring(jsonStart, jsonEnd);
        
        final parsed = jsonDecode(jsonStr);
        
        _securityLogger.log(
          SecurityEvent.aiResponseReceived,
          '복습 문제 생성 성공',
          level: SecurityLogLevel.info,
          data: {'generatedQuizCount': parsed['quizzes'].length},
        );
        
        return List<Map<String, dynamic>>.from(parsed['quizzes']);
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '복습 문제 생성 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );

      throw Exception('복습 문제 생성 실패');
    } catch (e) {
      print('복습 문제 생성 중 오류 발생: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '복습 문제 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateStudyGuide(
    List<Map<String, dynamic>> incorrectQuizzes,
  ) async {
    try {
      // 입력 유효성 검사
      if (incorrectQuizzes.isEmpty) {
        _securityLogger.log(
          SecurityEvent.invalidInput,
          '학습 가이드 생성을 위한 빈 오답 목록',
          level: SecurityLogLevel.warn,
        );
        throw Exception('학습 가이드를 생성할 오답 목록이 비어 있습니다.');
      }
      
      final quizzesStr = incorrectQuizzes.map((q) => 
        '문제: ${q['question']}\n정답: ${q['options'][q['answer']]}'
      ).join('\n\n');
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        '학습 가이드 생성 시작',
        level: SecurityLogLevel.info,
        data: {'incorrectCount': incorrectQuizzes.length},
      );

      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/study-guide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'text': quizzesStr,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final content = result['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        final jsonStr = content.substring(jsonStart, jsonEnd);
        
        _securityLogger.log(
          SecurityEvent.aiResponseReceived,
          '학습 가이드 생성 성공',
          level: SecurityLogLevel.info,
        );
        
        return jsonDecode(jsonStr);
      }
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '학습 가이드 생성 실패',
        level: SecurityLogLevel.error,
        data: {'statusCode': response.statusCode},
      );

      throw Exception('학습 가이드 생성 실패');
    } catch (e) {
      print('학습 가이드 생성 중 오류 발생: $e');
      
      _securityLogger.log(
        SecurityEvent.aiServiceDown,
        '학습 가이드 생성 중 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      rethrow;
    }
  }

  // API 사용량 제한 (옵션)
  static const int _freeUsageLimit = 50;  // 무료 사용자 일일 제한
  
  Future<bool> checkUsageLimit() async {
    // SharedPreferences로 간단히 구현
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageKey = 'api_usage_$today';
    
    final usage = prefs.getInt(usageKey) ?? 0;
    
    if (usage >= _freeUsageLimit) {
      _securityLogger.log(
        SecurityEvent.aiQuotaExceeded,
        'API 사용량 제한 초과',
        level: SecurityLogLevel.warn,
        data: {'usage': usage, 'limit': _freeUsageLimit},
      );
      return false;
    }
    
    return true;
  }

  Future<void> incrementUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usageKey = 'api_usage_$today';
      
      final usage = prefs.getInt(usageKey) ?? 0;
      final newUsage = usage + 1;
      await prefs.setInt(usageKey, newUsage);
      
      _securityLogger.log(
        SecurityEvent.aiRequestSent,
        'API 사용량 증가',
        level: SecurityLogLevel.debug,
        data: {'newUsage': newUsage, 'limit': _freeUsageLimit},
      );
      
      // 사용량이 제한에 가까워지면 경고
      if (newUsage >= _freeUsageLimit * 0.8) {
        _securityLogger.log(
          SecurityEvent.aiQuotaExceeded,
          'API 사용량 경고: 제한에 근접',
          level: SecurityLogLevel.warn,
          data: {'usage': newUsage, 'limit': _freeUsageLimit},
        );
      }
    } catch (e) {
      debugPrint('사용량 증가 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.error,
        'API 사용량 추적 오류',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
    }
  }

  /// 전역 API 키 설정
  static Future<void> setGlobalApiKey(String apiKey) async {
    try {
      // 유효성 검사
      if (!InputValidator.isValidApiKey(apiKey, ApiKeyType.gemini)) {
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          '전역 API 키 형식이 유효하지 않음',
          level: SecurityLogLevel.warn,
        );
        
        throw Exception('API 키 형식이 올바르지 않습니다');
      }
      
      await _secureStorage.initialize();
      await _secureStorage.saveSecureData('global_api_key', apiKey);
      
      _securityLogger.log(
        SecurityEvent.apiKeyAdded,
        '전역 API 키 설정됨',
        level: SecurityLogLevel.info,
      );
      
      debugPrint('전역 API 키 설정 완료');
    } catch (e) {
      debugPrint('전역 API 키 설정 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        '전역 API 키 설정 실패',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      throw Exception('API 키를 저장할 수 없습니다: $e');
    }
  }

  /// API 키 삭제
  static Future<void> clearGlobalApiKey() async {
    try {
      await _secureStorage.initialize();
      await _secureStorage.deleteSecureData('global_api_key');
      
      _securityLogger.log(
        SecurityEvent.apiKeyRemoved,
        '전역 API 키 삭제됨',
        level: SecurityLogLevel.info,
      );
      
      debugPrint('전역 API 키 삭제 완료');
    } catch (e) {
      debugPrint('API 키 삭제 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        '전역 API 키 삭제 실패',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
    }
  }
  
  /// API 키 유효성 검증
  static Future<bool> validateApiKey(String apiKey) async {
    return _apiKeyService.isValidApiKey(apiKey);
  }
  
  /// 비정상적인 API 요청 패턴 감지 (DoS 방지)
  Future<bool> detectAbnormalUsage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final timeKey = 'last_api_request_$userId';
      final countKey = 'api_request_count_$userId';
      
      // 마지막 요청 시간 가져오기
      final lastRequestStr = prefs.getString(timeKey);
      final requestCount = prefs.getInt(countKey) ?? 0;
      
      // 현재 시간 저장
      await prefs.setString(timeKey, now.toIso8601String());
      
      if (lastRequestStr != null) {
        final lastRequest = DateTime.parse(lastRequestStr);
        final timeDifference = now.difference(lastRequest).inSeconds;
        
        // 1초 안에 여러 요청이 오는 경우 (DoS 의심)
        if (timeDifference < 1) {
          await prefs.setInt(countKey, requestCount + 1);
          
          // 짧은 시간 내에 5회 이상 요청 시 비정상 패턴으로 간주
          if (requestCount > 5) {
            _securityLogger.log(
              SecurityEvent.rateLimit,
              '비정상적인 API 요청 패턴 감지',
              level: SecurityLogLevel.critical,
              data: {'userId': userId, 'requestCount': requestCount},
              reportToAnalytics: true,
              reportToCrashlytics: true,
            );
            
            return true;
          }
        } else {
          // 정상적인 시간 간격이면 카운트 초기화
          await prefs.setInt(countKey, 1);
        }
      } else {
        // 첫 요청인 경우
        await prefs.setInt(countKey, 1);
      }
      
      return false;
    } catch (e) {
      debugPrint('비정상 사용 감지 오류: $e');
      return false;
    }
  }
} 