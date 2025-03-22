import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf_learner_v2/services/api_key_service.dart';
import 'package:pdf_learner_v2/services/env_loader.dart';

/// API 관련 서비스 클래스
class ApiService {
  final ApiKeyService _apiKeyService = ApiKeyService();
  final EnvLoader _envLoader = EnvLoader();
  
  /// 기본 요약 API 엔드포인트
  static const String _summarizeEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  /// 기본 퀴즈 생성 API 엔드포인트
  static const String _quizEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  /// PDF 텍스트로부터 요약 생성
  Future<String?> generatePdfSummary(String pdfText) async {
    try {
      // 텍스트가 너무 길면 잘라내기
      final truncatedText = _truncateText(pdfText, 8000);
      
      // API 키 가져오기 (우선 OpenAI API 키 사용)
      final apiKey = await _apiKeyService.getOpenAiApiKey() ?? 
                    await _envLoader.defaultApiKey;
      
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print('API 키가 설정되지 않았습니다.');
        }
        
        // 백업: 로컬 요약 생성
        return _generateLocalSummary(truncatedText);
      }
      
      // API 요청 본문 생성
      final Map<String, dynamic> requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '당신은 전문적인 문서 요약가입니다. 주어진 텍스트를 명확하고 간결하게 요약해 주세요.'
          },
          {
            'role': 'user',
            'content': '다음 PDF 문서를 500단어 이내로 요약해 주세요. 핵심 내용만 포함하고 중요한 정보를 놓치지 마세요:\n\n$truncatedText'
          }
        ],
        'max_tokens': 1000,
        'temperature': 0.3,
      };
      
      // API 요청
      final response = await http.post(
        Uri.parse(_summarizeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        return content;
      } else {
        if (kDebugMode) {
          print('API 요청 실패: ${response.statusCode}, ${response.body}');
        }
        
        // 백업: 로컬 요약 생성
        return _generateLocalSummary(truncatedText);
      }
    } catch (e) {
      if (kDebugMode) {
        print('요약 생성 중 오류: $e');
      }
      
      // 백업: 로컬 요약 생성
      return _generateLocalSummary(pdfText);
    }
  }
  
  /// PDF 텍스트로부터 퀴즈 생성
  Future<List<Map<String, dynamic>>?> generatePdfQuiz(String pdfText) async {
    try {
      // 텍스트가 너무 길면 잘라내기
      final truncatedText = _truncateText(pdfText, 8000);
      
      // API 키 가져오기 (우선 OpenAI API 키 사용)
      final apiKey = await _apiKeyService.getOpenAiApiKey() ?? 
                    await _envLoader.defaultApiKey;
      
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print('API 키가 설정되지 않았습니다.');
        }
        
        // 백업: 로컬 퀴즈 생성
        return _generateLocalQuiz(truncatedText);
      }
      
      // API 요청 본문 생성
      final Map<String, dynamic> requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '당신은 교육 전문가입니다. 주어진 텍스트 내용을 바탕으로 학습자가 내용을 이해했는지 확인할 수 있는 퀴즈 문제를 생성해 주세요.'
          },
          {
            'role': 'user',
            'content': '다음 PDF 문서 내용을 바탕으로 5개의 객관식 퀴즈 문제를 생성해 주세요. 각 문제는 질문과 4개의 보기, 그리고 정답 번호를 포함해야 합니다. JSON 형식으로 반환해 주세요:\n\n$truncatedText\n\n다음 형식으로 반환해 주세요: [{\"question\": \"질문\", \"options\": [\"보기1\", \"보기2\", \"보기3\", \"보기4\"], \"answer\": 정답번호}]'
          }
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
      };
      
      // API 요청
      final response = await http.post(
        Uri.parse(_quizEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        try {
          // JSON 형식 추출 (API가 주변 텍스트를 포함할 수 있음)
          final regex = RegExp(r'\[{.*}\]', dotAll: true);
          final match = regex.firstMatch(content);
          
          if (match != null) {
            final jsonContent = match.group(0);
            final quizzes = jsonDecode(jsonContent!) as List;
            
            return quizzes.map((quiz) => quiz as Map<String, dynamic>).toList();
          } else {
            // 일반 JSON 파싱 시도
            final quizzes = jsonDecode(content) as List;
            return quizzes.map((quiz) => quiz as Map<String, dynamic>).toList();
          }
        } catch (e) {
          if (kDebugMode) {
            print('퀴즈 JSON 파싱 중 오류: $e');
            print('받은 콘텐츠: $content');
          }
          
          // 백업: 로컬 퀴즈 생성
          return _generateLocalQuiz(truncatedText);
        }
      } else {
        if (kDebugMode) {
          print('API 요청 실패: ${response.statusCode}, ${response.body}');
        }
        
        // 백업: 로컬 퀴즈 생성
        return _generateLocalQuiz(truncatedText);
      }
    } catch (e) {
      if (kDebugMode) {
        print('퀴즈 생성 중 오류: $e');
      }
      
      // 백업: 로컬 퀴즈 생성
      return _generateLocalQuiz(pdfText);
    }
  }
  
  /// 텍스트 길이 제한
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    // 최대 길이의 중간 부분만 추출
    final start = 0;
    final middle = text.length ~/ 2 - maxLength ~/ 4;
    final end = text.length - maxLength ~/ 4;
    
    return '${text.substring(start, start + maxLength ~/ 2)}\n\n[...중간 내용 생략...]\n\n${text.substring(end)}';
  }
  
  /// 로컬에서 간단한 요약 생성 (API 실패 시 대체)
  String _generateLocalSummary(String text) {
    try {
      // 매우 간단한 요약 - 각 단락의 첫 문장들을 수집
      final paragraphs = text.split('\n\n');
      final summary = <String>[];
      
      for (var i = 0; i < paragraphs.length; i++) {
        if (paragraphs[i].isEmpty) continue;
        
        final sentences = paragraphs[i].split(RegExp(r'(?<=[.!?])\s+'));
        if (sentences.isNotEmpty && sentences[0].length > 10) {
          summary.add(sentences[0]);
        }
        
        // 요약이 충분히 길면 중단
        if (summary.join(' ').length > 500 || summary.length > 10) {
          break;
        }
      }
      
      return '⚠️ API 연결에 실패하여 자동 생성된 단순 요약입니다:\n\n${summary.join('\n\n')}';
    } catch (e) {
      if (kDebugMode) {
        print('로컬 요약 생성 중 오류: $e');
      }
      return '⚠️ 요약을 생성할 수 없습니다. API 키를 확인하거나 나중에 다시 시도해 주세요.';
    }
  }
  
  /// 로컬에서 간단한 퀴즈 생성 (API 실패 시 대체)
  List<Map<String, dynamic>> _generateLocalQuiz(String text) {
    try {
      // 매우 간단한 퀴즈 - 각 문단에서 키워드 찾아 빈칸 채우기 생성
      final paragraphs = text.split('\n\n');
      final quizzes = <Map<String, dynamic>>[];
      
      for (var i = 0; i < paragraphs.length && quizzes.length < 5; i++) {
        if (paragraphs[i].length < 50) continue;
        
        final sentences = paragraphs[i].split(RegExp(r'(?<=[.!?])\s+'));
        for (var j = 0; j < sentences.length && quizzes.length < 5; j++) {
          final sentence = sentences[j];
          if (sentence.length < 40) continue;
          
          // 키워드 후보 (4글자 이상 단어)
          final words = sentence.split(RegExp(r'\s+'))
              .where((word) => word.length > 4)
              .toList();
          
          if (words.length < 4) continue;
          
          // 랜덤 단어 선택
          words.shuffle();
          final targetWord = words.first.replaceAll(RegExp(r'[,.!?:;]'), '');
          
          if (targetWord.length < 4) continue;
          
          // 문제 생성
          final question = sentence.replaceFirst(
              RegExp(targetWord, caseSensitive: false), 
              '_________'
          );
          
          // 보기 생성 (3개는 다른 단어, 1개는 정답)
          final options = <String>[targetWord];
          words.skip(1).take(3).forEach((word) {
            options.add(word.replaceAll(RegExp(r'[,.!?:;]'), ''));
          });
          
          // 보기 순서 섞기
          options.shuffle();
          
          // 정답 찾기
          final answerIndex = options.indexOf(targetWord);
          
          quizzes.add({
            'question': '다음 문장의 빈칸에 들어갈 단어로 가장 적절한 것은?\n$question',
            'options': options,
            'answer': answerIndex
          });
        }
      }
      
      // 충분한 퀴즈가 없으면 더미 퀴즈 추가
      while (quizzes.length < 3) {
        quizzes.add({
          'question': '⚠️ API 연결에 실패하여 자동 생성된 예시 문제입니다. 문서 내용과 관련이 없을 수 있습니다.',
          'options': ['예시 답변 1', '예시 답변 2', '예시 답변 3', '예시 답변 4'],
          'answer': 0
        });
      }
      
      return quizzes;
    } catch (e) {
      if (kDebugMode) {
        print('로컬 퀴즈 생성 중 오류: $e');
      }
      
      // 더미 퀴즈 반환
      return [
        {
          'question': '⚠️ 퀴즈를 생성할 수 없습니다. API 키를 확인하거나 나중에 다시 시도해 주세요.',
          'options': ['답변 1', '답변 2', '답변 3', '답변 4'],
          'answer': 0
        },
        {
          'question': '⚠️ 퀴즈를 생성할 수 없습니다. API 키를 확인하거나 나중에 다시 시도해 주세요.',
          'options': ['답변 1', '답변 2', '답변 3', '답변 4'],
          'answer': 0
        },
        {
          'question': '⚠️ 퀴즈를 생성할 수 없습니다. API 키를 확인하거나 나중에 다시 시도해 주세요.',
          'options': ['답변 1', '답변 2', '답변 3', '답변 4'],
          'answer': 0
        }
      ];
    }
  }
} 