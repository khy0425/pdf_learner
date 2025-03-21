import 'package:flutter_test/flutter_test.dart';
import 'utils/input_validation_simple_test.dart' as input_validation_test;

/// 단순화된 보안 테스트 실행기
/// 
/// 테스트 명령어: flutter test test/security_tests_simplified.dart
void main() {
  group('보안 테스트 실행', () {
    test('입력 유효성 검증 테스트', () {
      input_validation_test.main();
    });
  });
} 