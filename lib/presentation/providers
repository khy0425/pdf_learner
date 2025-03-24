import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIServiceProvider extends ChangeNotifier {
  static const String _apiUrl = 'YOUR_AI_SERVICE_ENDPOINT';
  
  Future<String> summarizeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/summarize'),
        body: {'text': text},
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
        },
      );
      
      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('요약 생성 실패');
    } catch (e) {
      throw Exception('AI 서비스 오류: $e');
    }
  }

  Future<List<Map<String, String>>> generateQuiz(String text) async {
    // 퀴즈 생성 로직
    return [];
  }
} 