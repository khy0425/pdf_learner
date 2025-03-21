/// 보안 로그 레벨 정의
enum SecurityLogLevel {
  debug,
  info,
  warning,
  error,
  critical
}

/// 보안 이벤트 유형 정의
enum SecurityEvent {
  login,
  logout,
  signup,
  passwordReset,
  passwordChange,
  apiKeyGenerated,
  apiKeyUsed,
  apiKeyRevoked,
  fileAccess,
  fileUpload,
  fileDownload,
  configChanged,
  rateLimit,
  suspiciousActivity
}

/// 보안 로그 데이터 모델
class SecurityLog {
  final DateTime timestamp;
  final SecurityEvent event;
  final String userId;
  final SecurityLogLevel level;
  final String message;
  final Map<String, dynamic> metadata;

  SecurityLog({
    required this.timestamp,
    required this.event,
    required this.userId,
    required this.level,
    required this.message,
    this.metadata = const {},
  });

  /// JSON 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'event': event.toString().split('.').last,
      'userId': userId,
      'level': level.toString().split('.').last,
      'message': message,
      'metadata': metadata,
    };
  }

  /// JSON에서 SecurityLog 객체 생성
  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      event: SecurityEvent.values.firstWhere(
          (e) => e.toString().split('.').last == json['event'],
          orElse: () => SecurityEvent.suspiciousActivity),
      userId: json['userId'],
      level: SecurityLogLevel.values.firstWhere(
          (l) => l.toString().split('.').last == json['level'],
          orElse: () => SecurityLogLevel.info),
      message: json['message'],
      metadata: json['metadata'] ?? {},
    );
  }

  @override
  String toString() {
    return '[$timestamp] ${level.toString().split('.').last.toUpperCase()} - ${event.toString().split('.').last}: $message (User: $userId)';
  }
}