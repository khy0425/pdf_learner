import 'package:googleapis/language/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const _credentials = {
    "type": "service_account",
    // ... Google Cloud 서비스 계정 키 정보
  };

  late Interpreter _interpreter;
  
  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset('assets/models/summarizer.tflite');
  }

  // Hugging Face API 설정
  static String get _apiKey => dotenv.env['HUGGING_FACE_API_KEY'] ?? '';
  
  // 요약 모델 엔드포인트
  static const String _summaryApiUrl = 
    'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
  
  // 텍스트 생성 모델 엔드포인트 (퀴즈 생성용)
  static const String _textGenApiUrl = 
    'https://api-inference.huggingface.co/models/google/flan-t5-large';

  Future<String> generateSummary(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_summaryApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': text,
          'parameters': {
            'max_length': 150,
            'min_length': 40,
            'do_sample': false,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['summary_text'];
      } else {
        throw Exception('요약 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI 서비스 오류: $e');
    }
  }

  Future<List<Map<String, String>>> generateQuiz(String text) async {
    try {
      final prompt = '''
텍스트를 기반으로 3개의 퀴즈를 생성해주세요. 각 퀴즈는 다음 형식을 따릅니다:
질문:
1) 보기1
2) 보기2
3) 보기3
4) 보기4
정답: [번호]
해설: [설명]

텍스트: $text
''';

      final response = await http.post(
        Uri.parse(_textGenApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_length': 800,
            'temperature': 0.7,
            'do_sample': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quizText = data[0]['generated_text'];
        return _parseQuizText(quizText);
      } else {
        throw Exception('퀴즈 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('퀴즈 생성 오류: $e');
    }
  }

  List<Map<String, String>> _parseQuizText(String quizText) {
    final List<Map<String, String>> quizzes = [];
    final quizRegExp = RegExp(
      r'질문:\s*(.*?)\n1\)\s*(.*?)\n2\)\s*(.*?)\n3\)\s*(.*?)\n4\)\s*(.*?)\n정답:\s*(\d+)\n해설:\s*(.*?)(?=\n질문:|$)',
      dotAll: true,
    );

    final matches = quizRegExp.allMatches(quizText);
    
    for (var match in matches) {
      quizzes.add({
        'question': match.group(1)?.trim() ?? '',
        'options': [
          match.group(2)?.trim() ?? '',
          match.group(3)?.trim() ?? '',
          match.group(4)?.trim() ?? '',
          match.group(5)?.trim() ?? '',
        ].join('|'),
        'correct_answer': match.group(6) ?? '',
        'explanation': match.group(7)?.trim() ?? '',
      });
    }

    return quizzes;
  }
} 