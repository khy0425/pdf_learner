import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_learner/utils/input_validator.dart';

void main() {
  group('InputValidator 테스트', () {
    group('이메일 유효성 검사', () {
      test('유효한 이메일', () {
        expect(InputValidator.isValidEmail('test@example.com'), true);
        expect(InputValidator.isValidEmail('user.name@domain.co.kr'), true);
        expect(InputValidator.isValidEmail('name+tag@gmail.com'), true);
      });

      test('유효하지 않은 이메일', () {
        expect(InputValidator.isValidEmail(''), false);
        expect(InputValidator.isValidEmail('plaintext'), false);
        expect(InputValidator.isValidEmail('test@.com'), false);
        expect(InputValidator.isValidEmail('test@domain'), false);
        expect(InputValidator.isValidEmail('@domain.com'), false);
      });
    });

    group('비밀번호 강도 검사', () {
      test('빈 비밀번호', () {
        expect(InputValidator.checkPasswordStrength(''), PasswordStrength.tooWeak);
      });

      test('너무 짧은 비밀번호', () {
        expect(InputValidator.checkPasswordStrength('pass'), PasswordStrength.weak);
      });

      test('약한 비밀번호', () {
        expect(InputValidator.checkPasswordStrength('password'), PasswordStrength.weak);
        expect(InputValidator.checkPasswordStrength('12345678'), PasswordStrength.weak);
      });

      test('중간 강도 비밀번호', () {
        expect(InputValidator.checkPasswordStrength('Password123'), PasswordStrength.medium);
        expect(InputValidator.checkPasswordStrength('pass123!'), PasswordStrength.medium);
      });

      test('강한 비밀번호', () {
        expect(InputValidator.checkPasswordStrength('P@ssw0rd!'), PasswordStrength.strong);
        expect(InputValidator.checkPasswordStrength('Str0ng#P@ss'), PasswordStrength.strong);
      });
      
      test('매우 강한 비밀번호', () {
        expect(InputValidator.checkPasswordStrength('P@ssw0rd!VeryStr0ng123'), PasswordStrength.veryStrong);
        expect(InputValidator.checkPasswordStrength('Str0ng#P@ss!WithSpecial&123'), PasswordStrength.veryStrong);
      });
    });

    group('API 키 유효성 검사', () {
      test('유효한 Gemini API 키', () {
        expect(InputValidator.isValidApiKey('AIzaSyD1AbCdEfGhIjKlMnOpQrStUvWxYz12345', ApiKeyType.gemini), true);
      });

      test('유효하지 않은 Gemini API 키', () {
        expect(InputValidator.isValidApiKey('123456', ApiKeyType.gemini), false);
        expect(InputValidator.isValidApiKey('KEY_12345', ApiKeyType.gemini), false);
      });

      test('유효한 Hugging Face API 키', () {
        expect(InputValidator.isValidApiKey('hf_abcdefghijklmn', ApiKeyType.huggingFace), true);
      });

      test('유효하지 않은 Hugging Face API 키', () {
        expect(InputValidator.isValidApiKey('key_12345', ApiKeyType.huggingFace), false);
      });
    });

    group('PDF 경로 유효성 검사', () {
      test('유효한 PDF 경로', () {
        expect(InputValidator.isValidPdfPath('/path/to/document.pdf'), true);
        expect(InputValidator.isValidPdfPath('document.pdf'), true);
        expect(InputValidator.isValidPdfPath('http://example.com/doc.pdf'), true);
        expect(InputValidator.isValidPdfPath('https://example.com/folder/doc.pdf'), true);
      });

      test('유효하지 않은 PDF 경로', () {
        expect(InputValidator.isValidPdfPath(''), false);
        expect(InputValidator.isValidPdfPath('document.txt'), false);
        expect(InputValidator.isValidPdfPath('/path/../injection.pdf'), false);
        expect(InputValidator.isValidPdfPath('ftp://example.com/doc.pdf'), false);
      });
    });

    group('JSON 유효성 검사', () {
      test('유효한 JSON', () {
        expect(InputValidator.isValidJson('{"name":"John","age":30}'), true);
        expect(InputValidator.isValidJson('[]'), true);
        expect(InputValidator.isValidJson('{"nested":{"key":"value"}}'), true);
      });

      test('유효하지 않은 JSON', () {
        expect(InputValidator.isValidJson(''), false);
        expect(InputValidator.isValidJson('{name:"John"}'), false);
        expect(InputValidator.isValidJson('{"incomplete":'), false);
      });
    });

    group('검색어 유효성 검사', () {
      test('유효한 검색어', () {
        expect(InputValidator.isValidSearchQuery('flutter pdf'), true);
        expect(InputValidator.isValidSearchQuery('안녕하세요'), true);
        expect(InputValidator.isValidSearchQuery('123 test'), true);
      });

      test('SQL 인젝션이 있는 검색어', () {
        expect(InputValidator.isValidSearchQuery("' OR 1=1 --"), false);
        expect(InputValidator.isValidSearchQuery('DROP TABLE users;'), false);
        expect(InputValidator.isValidSearchQuery('SELECT * FROM data'), false);
      });

      test('XSS가 있는 검색어', () {
        expect(InputValidator.isValidSearchQuery('<script>alert(1)</script>'), false);
        expect(InputValidator.isValidSearchQuery('javascript:alert(1)'), false);
        expect(InputValidator.isValidSearchQuery('onload=alert(1)'), false);
      });
    });

    group('파일명 유효성 검사', () {
      test('유효한 파일명', () {
        expect(InputValidator.isValidFilename('document.pdf'), true);
        expect(InputValidator.isValidFilename('my-file.txt'), true);
        expect(InputValidator.isValidFilename('file_name.jpg'), true);
      });

      test('유효하지 않은 파일명', () {
        expect(InputValidator.isValidFilename(''), false);
        expect(InputValidator.isValidFilename('file/name.txt'), false);
        expect(InputValidator.isValidFilename('file?.txt'), false);
        expect(InputValidator.isValidFilename('file".txt'), false);
      });
    });

    group('문자열 정제', () {
      test('HTML 태그 제거', () {
        expect(InputValidator.sanitizeInput('<p>Hello</p>'), 'Hello');
        expect(InputValidator.sanitizeInput('<script>alert(1)</script>'), 'alert(1)');
      });

      test('특수 문자 이스케이프', () {
        expect(InputValidator.sanitizeInput('<>&"\''), '&lt;&gt;&amp;&quot;&#x27;');
      });
    });
  });
} 