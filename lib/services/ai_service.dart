import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _hfApiKey => dotenv.env['HUGGING_FACE_API_KEY'] ?? '';

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
      // 1. 먼저 .env 파일의 API 키 확인
      final envApiKey = dotenv.env['GEMINI_API_KEY'];
      if (envApiKey?.isNotEmpty ?? false) {
        return envApiKey!;
      }

      // 2. 사용자가 입력한 API 키 확인
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString('user_api_key');
      if (userApiKey?.isNotEmpty ?? false) {
        return userApiKey!;
      }

      throw Exception('API 키가 설정되지 않았습니다. API 키를 입력해주세요.');
    } catch (e) {
      throw Exception('API 키 설정 오류: $e');
    }
  }

  Future<String> generateSummary(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 텍스트를 한국어로 간단명료하게 요약해주세요:
              
              $text'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        return result['candidates'][0]['content']['parts'][0]['text'];
      }
      
      throw Exception('요약 생성 실패');
    } catch (e) {
      print('요약 생성 중 오류: $e');
      rethrow;
    }
  }

  Future<List<String>> extractKeyPoints(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/facebook/bart-large-mnli'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': text,
          'parameters': {
            'candidate_labels': ['key point', 'important concept', 'main idea'],
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // 결과 처리 및 핵심 포인트 추출
        return ['핵심 포인트 1', '핵심 포인트 2']; // 임시 반환값
      }
      
      throw Exception('핵심 포인트 추출 실패');
    } catch (e) {
      throw Exception('핵심 포인트 추출 중 오류 발생: $e');
    }
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String text, {int count = 5}) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 텍스트를 바탕으로 $count개의 퀴즈를 만들어주세요.

              퀴즈 작성 규칙:
              1. 육하원칙(누가, 언제, 어디서, 무엇을, 어떻게, 왜)을 최대한 활용해 구체적인 문제를 작성
              2. 문제 내용이 모호하지 않도록 명확하게 작성
              3. 정답과 오답의 구분이 명확해야 함
              4. 해설에는 왜 그 답이 정답인지 구체적으로 설명
              
              다음 JSON 형식으로 작성해주세요:
              {
                "quizzes": [
                  {
                    "question": "구체적인 문제 내용 (육하원칙 활용)",
                    "options": [
                      "명확한 보기1",
                      "명확한 보기2",
                      "명확한 보기3",
                      "명확한 보기4"
                    ],
                    "answer": 정답번호(0-3),
                    "explanation": "왜 이 답이 정답인지 구체적인 설명",
                    "category": "문제 유형(개념/사실/분석/추론 등)"
                  }
                ]
              }
              
              텍스트: $text'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final content = result['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final parsed = jsonDecode(jsonStr);
        
        return List<Map<String, dynamic>>.from(parsed['quizzes']);
      }
      
      throw Exception('퀴즈 생성 실패');
    } catch (e) {
      print('퀴즈 생성 중 오류: $e');
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
      final processedText = _preprocessText(text);
      print('핵심 문장 추출 시작...');

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
          
          return sentences;
        }
      }
      
      print('API 오류 응답: ${response.body}');
      throw Exception('핵심 문장 추출 실패');
    } catch (e) {
      print('핵심 문장 추출 중 오류 발생: $e');
      rethrow;
    }
  }

  Future<String> generateStudySuggestion(String content) async {
    try {
      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse('$_apiUrl/study-suggestion'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',  // 사용자 인증 토큰
        },
        body: jsonEncode({
          'text': content,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        if (result['candidates']?[0]?['content'] != null) {
          return result['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      throw Exception('학습 제안 생성 실패');
    } catch (e) {
      debugPrint('학습 제안 생성 중 오류: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateMistakeAnalysis(
    Map<String, dynamic> quiz,
    int userAnswer,
  ) async {
    try {
      final question = quiz['question'];
      final options = quiz['options'];
      final correctAnswer = quiz['answer'];
      final explanation = quiz['explanation'];

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
        
        return jsonDecode(jsonStr);
      }

      throw Exception('오답 분석 생성 실패');
    } catch (e) {
      print('오답 분석 생성 중 오류 발생: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateReviewQuizzes(
    List<Map<String, dynamic>> mistakeQuizzes,
  ) async {
    try {
      final quizzesStr = mistakeQuizzes.map((q) => 
        '문제: ${q['question']}\n정답: ${q['options'][q['answer']]}'
      ).join('\n\n');

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
        return List<Map<String, dynamic>>.from(parsed['quizzes']);
      }

      throw Exception('복습 문제 생성 실패');
    } catch (e) {
      print('복습 문제 생성 중 오류 발생: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateStudyGuide(
    List<Map<String, dynamic>> incorrectQuizzes,
  ) async {
    try {
      final quizzesStr = incorrectQuizzes.map((q) => 
        '문제: ${q['question']}\n정답: ${q['options'][q['answer']]}'
      ).join('\n\n');

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
        
        return jsonDecode(jsonStr);
      }

      throw Exception('학습 가이드 생성 실패');
    } catch (e) {
      print('학습 가이드 생성 중 오류 발생: $e');
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
    return usage < _freeUsageLimit;
  }

  Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageKey = 'api_usage_$today';
    
    final usage = prefs.getInt(usageKey) ?? 0;
    await prefs.setInt(usageKey, usage + 1);
  }
} 