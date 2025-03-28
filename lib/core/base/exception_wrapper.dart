/// 문자열을 Exception으로 변환하는 래퍼 클래스
class ExceptionWrapper implements Exception {
  /// 예외 메시지
  final String message;
  
  /// 선택적 코드
  final String? code;
  
  /// 원본 예외 (선택 사항)
  final dynamic originalException;
  
  /// 생성자
  const ExceptionWrapper(this.message, {this.code, this.originalException});
  
  /// toString 메서드 오버라이드
  @override
  String toString() {
    if (code != null) {
      return 'ExceptionWrapper: [$code] $message';
    }
    return 'ExceptionWrapper: $message';
  }
  
  /// 문자열에서 예외 생성
  static ExceptionWrapper fromString(String message) {
    return ExceptionWrapper(message);
  }
  
  /// 다른 예외에서 예외 생성
  static ExceptionWrapper fromException(Exception exception, {String? additionalMessage}) {
    final message = additionalMessage != null 
        ? '$additionalMessage: ${exception.toString()}'
        : exception.toString();
    return ExceptionWrapper(message, originalException: exception);
  }
} 