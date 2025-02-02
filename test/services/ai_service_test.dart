import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:ai_pdf_study_assistant/services/ai_service.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  group('AIService Tests', () {
    late AIService aiService;
    late http.Client mockClient;

    setUp(() {
      mockClient = MockClient();
      aiService = AIService();
    });

    test('generateSummary returns summary text on success', () async {
      const testText = '테스트 텍스트입니다.';
      const expectedSummary = '요약된 텍스트입니다.';

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"choices": [{"message": {"content": "$expectedSummary"}}]}',
        200,
      ));

      final summary = await aiService.generateSummary(testText);
      expect(summary, expectedSummary);
    });
  });
} 