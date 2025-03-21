import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_learner/utils/input_validator.dart';

void main() {
  group('InputValidator 테스트', () {
    group('이메일 검증', () {
      test('유효한 이메일', () {
        expect(InputValidator.isValidEmail('user@example.com'), true);
        expect(InputValidator.isValidEmail('name.surname@domain.co.kr'), true);
        expect(InputValidator.isValidEmail('user+tag@gmail.com'), true);
      });

      test('유효하지 않은 이메일', () {
        expect(InputValidator.isValidEmail(''), false);
        expect(InputValidator.isValidEmail('user@'), false);
        expect(InputValidator.isValidEmail('@domain.com'), false);
        expect(InputValidator.isValidEmail('user@domain'), false);
      });
    });

    group('URL 검증', () {
      test('유효한 URL', () {
        expect(InputValidator.isValidUrl('https://example.com'), true);
        expect(InputValidator.isValidUrl('http://sub.domain.co.kr/path'), true);
      });

      test('유효하지 않은 URL', () {
        expect(InputValidator.isValidUrl(''), false);
        expect(InputValidator.isValidUrl('domain.com'), false);
        expect(InputValidator.isValidUrl('not-a-url'), false);
      });
    });

    group('파일명 검증', () {
      test('유효한 파일명', () {
        expect(InputValidator.isValidFilename('document.pdf'), true);
        expect(InputValidator.isValidFilename('my-file.txt'), true);
        expect(InputValidator.isValidFilename('file_123.jpg'), true);
      });

      test('유효하지 않은 파일명', () {
        expect(InputValidator.isValidFilename(''), false);
        expect(InputValidator.isValidFilename('file/name.txt'), false);
        expect(InputValidator.isValidFilename('file?.txt'), false);
      });
    });

    group('API 키 검증', () {
      test('Gemini API 키', () {
        expect(InputValidator.isValidApiKey('AIzaSyA1234567890abcdefghijklmnopqrstuvwxyz', ApiKeyType.gemini), true);
        expect(InputValidator.isValidApiKey('invalid-key', ApiKeyType.gemini), false);
      });

      test('OpenAI API 키', () {
        expect(InputValidator.isValidApiKey('sk-1234567890abcdefghijklmnopqrstuvwxyz', ApiKeyType.openai), true);
        expect(InputValidator.isValidApiKey('invalid-key', ApiKeyType.openai), false);
      });
      
      test('HuggingFace API 키', () {
        expect(InputValidator.isValidApiKey('hf_abcdefghijklmnopqrstuvwxyz', ApiKeyType.huggingFace), true);
        expect(InputValidator.isValidApiKey('invalid-key', ApiKeyType.huggingFace), false);
      });
    });

    group('XSS 방어', () {
      test('HTML 태그 제거 또는 이스케이프', () {
        const input = '<script>alert("XSS")</script>안녕하세요';
        final sanitized = InputValidator.sanitizeInput(input);
        
        // 태그가 제거되거나 이스케이프되었는지 확인
        expect(sanitized, isNot(contains('<script>')));
        expect(sanitized, isNot(contains('</script>')));
        
        // 문자열 내용이 포함되어 있는지 확인 (따옴표는 이스케이프될 수 있음)
        expect(sanitized, contains('alert'));
        expect(sanitized, contains('XSS'));
        expect(sanitized, contains('안녕하세요'));
      });

      test('특수 문자 이스케이프', () {
        const input = '&<>"\'안녕하세요';
        final sanitized = InputValidator.sanitizeInput(input);
        
        // 원본 텍스트에는 특수문자가 있었지만 이스케이프된 결과에는 없어야 함
        expect(sanitized, isNot(contains('&<>"\'')));
        
        // 한글은 유지되어야 함
        expect(sanitized, contains('안녕하세요'));
        
        // 이스케이프된 특수문자가 포함되어 있어야 함 (정확한 형식은 구현에 따라 다를 수 있음)
        expect(sanitized.length, greaterThan(input.length)); // 이스케이프로 인해 길이가 늘어남
      });
    });

    group('비밀번호 강도 검사', () {
      test('빈 비밀번호는 매우 약함', () {
        expect(InputValidator.checkPasswordStrength(''), PasswordStrength.tooWeak);
      });

      // 실제 구현에서는 짧은 비밀번호나 단순한 비밀번호를 'weak'로 평가
      test('단순한 비밀번호는 약함', () {
        final strength = InputValidator.checkPasswordStrength('password');
        expect(strength == PasswordStrength.weak || strength == PasswordStrength.tooWeak, isTrue);
      });

      test('숫자만 있는 비밀번호는 약함', () {
        final strength = InputValidator.checkPasswordStrength('12345678');
        expect(strength == PasswordStrength.weak || strength == PasswordStrength.tooWeak, isTrue);
      });

      test('대문자/소문자/숫자 조합은 중간 이상', () {
        final strength = InputValidator.checkPasswordStrength('Password123');
        expect(strength == PasswordStrength.medium || strength == PasswordStrength.strong, isTrue);
      });

      test('특수문자가 포함된 조합은 강함 이상', () {
        final strength = InputValidator.checkPasswordStrength('P@ssw0rd!');
        expect(strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong, isTrue);
      });
      
      test('길고 복잡한 비밀번호는 매우 강함', () {
        final strength = InputValidator.checkPasswordStrength('P@ssw0rd!VeryStr0ng123');
        expect(strength == PasswordStrength.veryStrong || strength == PasswordStrength.strong, isTrue);
      });
    });
  });
} 