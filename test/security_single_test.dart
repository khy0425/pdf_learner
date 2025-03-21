import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_learner/utils/input_validator.dart';
import 'test_helper.dart';

void main() async {
  // 테스트 환경 준비
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('입력 검증 테스트', () {
    test('XSS 방어 테스트', () {
      const maliciousInput = '<script>alert("XSS")</script>안녕하세요';
      final sanitizedInput = InputValidator.sanitizeInput(maliciousInput);
      
      // HTML 태그가 제거되거나 이스케이프되어야 함
      expect(sanitizedInput, isNot(contains('<script>')));
      expect(sanitizedInput, isNot(contains('</script>')));
    });

    test('이메일 주소 검증 테스트', () {
      expect(InputValidator.isValidEmail('user@example.com'), true);
      expect(InputValidator.isValidEmail('invalid-email'), false);
      expect(InputValidator.isValidEmail('user@domain'), false);
    });

    test('URL 검증 테스트', () {
      expect(InputValidator.isValidUrl('https://example.com'), true);
      expect(InputValidator.isValidUrl('http://sub.example.co.kr/path'), true);
      expect(InputValidator.isValidUrl('invalid-url'), false);
    });
  });
} 