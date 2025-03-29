/// 인증 관련 예외를 표현하는 클래스
class AuthException implements Exception {
  /// 예외 메시지
  final String message;
  
  /// 예외 코드 (선택 사항)
  final String? code;
  
  /// 원본 예외 (선택 사항)
  final dynamic originalException;
  
  /// 인증 예외 생성자
  AuthException({
    required this.message,
    this.code,
    this.originalException,
  });
  
  @override
  String toString() {
    if (code != null) {
      return 'AuthException: [$code] $message';
    }
    return 'AuthException: $message';
  }
} 