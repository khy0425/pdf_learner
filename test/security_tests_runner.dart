import 'package:flutter_test/flutter_test.dart';
import 'utils/security_logger_test.dart' as security_logger_test;
import 'utils/rate_limiter_test.dart' as rate_limiter_test;
import 'utils/input_validator_test.dart' as input_validator_test;
import 'security/security_tests.dart' as security_tests;
import 'test_helper.dart';

/// 모든 보안 관련 테스트를 실행하는 스크립트
/// 
/// 테스트 명령어: flutter test test/security_tests_runner.dart
void main() async {
  group('모든 보안 테스트 실행', () {
    // 테스트 환경 설정
    setUpAll(() async {
      await setupTestEnvironment();
    });

    // 로깅, 입력 검증, 속도 제한 테스트 실행
    test('보안 로거 테스트', () => security_logger_test.main());
    test('속도 제한 테스트', () => rate_limiter_test.main());
    test('입력 검증 테스트', () => input_validator_test.main());
    test('보안 취약점 테스트', () => security_tests.main());
  });
} 