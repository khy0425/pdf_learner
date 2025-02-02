import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AIService {
  // Gemini API 설정
  static const String _apiKey = 'AIzaSyAjxIypX5iritXTZO3M_4mhJ8uwjWyyHJ8';  // API 키 직접 설정
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

  Future<String> generateSummary(
    String text, {
    Function(String)? onProgress,
  }) async {
    try {
      if (onProgress != null) {
        onProgress('AI가 텍스트를 분석중입니다...');
      }
      final processedText = _preprocessText(text);
      print('요약 생성 시작...');

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 텍스트를 한국어로 간단명료하게 요약해주세요. 
              핵심 내용을 3-4개의 문장으로 요약하고, 각 문장은 번호를 붙여서 표시해주세요:
              
              $processedText'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          },
        }),
      );

      print('응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        print('응답 성공!');
        
        if (result['candidates']?[0]?['content'] != null) {
          final summary = result['candidates'][0]['content']['parts'][0]['text'].trim();
          return summary;
        }
      }
      
      print('API 오류 응답: ${response.body}');
      throw Exception('요약 생성 실패');
    } catch (e) {
      print('요약 생성 중 오류 발생: $e');
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

  Future<List<Map<String, dynamic>>> generateQuiz(
    String text, {
    int? count,
  }) async {
    try {
      final processedText = _preprocessText(text);
      final quizCount = count ?? 5;

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 텍스트를 바탕으로 $quizCount개의 4지선다형 퀴즈를 만들어주세요.
              
              다음 형식을 반드시 지켜주세요:
              문제: [문제 내용]
              ① [보기1]
              ② [보기2]
              ③ [보기3]
              ④ [보기4]
              정답: [1-4 중 선택]
              해설: [해설 내용]

              텍스트: $processedText'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          },
        }),
      );

      print('API 요청 완료: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final content = result['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        
        print('AI 응답 내용:');
        print(content);

        if (content != null) {
          final quizzes = <Map<String, dynamic>>[];
          
          // 문제 단위로 분리하는 부분 수정
          final problems = content
              .split(RegExp(r'\*\*문제\s*\d+:\*\*'))  // "문제 N:" 형식으로 분리
              .where((s) => s.trim().isNotEmpty)
              .toList();
          
          for (final problem in problems) {
            try {
              // 문제 내용 추출 수정
              final questionLines = problem.split('\n');
              final question = questionLines.first.trim();

              // 보기 추출 부분 수정
              final options = <String>[];
              final optionsRegex = RegExp(r'[①②③④]\s*([^\n]+)');
              final optionsText = problem.split('정답:')[0];  // 정답 이전 텍스트만 사용
              final optionsMatches = optionsRegex.allMatches(optionsText);
              
              for (final match in optionsMatches) {
                final option = match.group(1)?.trim();
                if (option != null && option.isNotEmpty) {
                  options.add(option);
                }
              }

              // 정답 추출 부분 수정
              var answer = -1;
              if (problem.contains('정답:')) {
                final answerPart = problem.split('정답:')[1].split('\n')[0].trim();
                if (answerPart.contains('①') || answerPart == '1') answer = 0;
                else if (answerPart.contains('②') || answerPart == '2') answer = 1;
                else if (answerPart.contains('③') || answerPart == '3') answer = 2;
                else if (answerPart.contains('④') || answerPart == '4') answer = 3;
              }

              // 해설 추출 부분 수정
              var explanation = '';
              if (problem.contains('해설:')) {
                explanation = problem
                    .split('해설:')[1]
                    .split('**')[0]  // 다음 문제 시작 전까지
                    .trim();
              }

              // 디버그 출력
              print('처리 중인 문제:');
              print('문제: $question');
              print('보기: $options');
              print('정답: $answer');
              print('해설: $explanation');

              if (question.isNotEmpty && options.length == 4 && answer >= 0 && explanation.isNotEmpty) {
                quizzes.add({
                  'question': question,
                  'options': options,
                  'answer': answer,
                  'explanation': explanation,
                });
              }
            } catch (e) {
              print('개별 퀴즈 파싱 오류: $e');
              print('문제 내용: $problem');
            }
          }

          print('생성된 퀴즈 수: ${quizzes.length}');
          if (quizzes.isEmpty) {
            print('파싱된 퀴즈가 없습니다. 원본 응답:');
            print(content);
          }
          return quizzes;
        }
      }
      
      throw Exception('퀴즈 생성 실패: 응답 형식 오류');
    } catch (e) {
      print('퀴즈 생성 중 오류 발생: $e');
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

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 텍스트에서 가장 중요한 핵심 문장들을 추출해주세요.
              각 문장은 원문 그대로 추출하고, 줄바꿈으로 구분해주세요.
              가능한 한 전체 내용을 포괄하는 5-7개의 핵심 문장을 선택해주세요:
              
              $processedText'''
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
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 학습 노트 내용을 분석하고, 추가 학습이 필요한 부분과 
              심화 학습을 위한 제안사항을 제시해주세요:
              
              $content'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
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

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음 퀴즈의 오답에 대한 상세 분석과 학습 제안을 해주세요.
              
              문제: $question
              보기:
              ${options.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}
              
              학생의 답: ${userAnswer + 1}번
              정답: ${correctAnswer + 1}번
              기존 해설: $explanation
              
              다음 JSON 형식으로 응답해주세요:
              {
                "mistakeAnalysis": "오답 선택 이유 분석",
                "conceptExplanation": "관련 개념 상세 설명",
                "studyTips": ["학습 제안 1", "학습 제안 2", "학습 제안 3"],
                "relatedTopics": ["연관 주제 1", "연관 주제 2"]
              }'''
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
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

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음은 학생이 틀린 문제들입니다. 
              이 문제들의 개념을 보강하기 위한 새로운 복습 문제 3개를 만들어주세요.
              
              틀린 문제들:
              $quizzesStr
              
              위 문제들과 연관된 새로운 퀴즈를 다음 JSON 형식으로 만들어주세요:
              {
                "quizzes": [
                  {
                    "question": "문제",
                    "options": ["보기1", "보기2", "보기3", "보기4"],
                    "answer": 정답번호(0-3),
                    "explanation": "해설",
                    "relatedConcepts": ["관련 개념1", "관련 개념2"]
                  }
                ]
              }'''
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

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''다음은 학생이 틀린 문제들입니다. 
              이를 바탕으로 학습 가이드를 작성해주세요.
              
              틀린 문제들:
              $quizzesStr
              
              다음 JSON 형식으로 응답해주세요:
              {
                "weakPoints": ["취약한 개념 1", "취약한 개념 2"],
                "studyPlan": "단계별 학습 계획",
                "recommendedResources": ["추천 자료 1", "추천 자료 2"]
              }'''
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
        
        return jsonDecode(jsonStr);
      }

      throw Exception('학습 가이드 생성 실패');
    } catch (e) {
      print('학습 가이드 생성 중 오류 발생: $e');
      rethrow;
    }
  }
} 