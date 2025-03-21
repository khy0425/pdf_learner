import 'package:flutter/foundation.dart';
import '../utils/security_logger.dart';

/// 애플리케이션의 보안 설정을 관리하는 클래스
class SecurityConfig {
  static final SecurityConfig _instance = SecurityConfig._internal();
  factory SecurityConfig() => _instance;
  SecurityConfig._internal();

  /// 로그 수준
  SecurityLogLevel _logLevel = SecurityLogLevel.info;
  SecurityLogLevel get logLevel => _logLevel;

  /// 암호화 관련 설정
  /// AES 암호화 키 길이 (비트)
  static const int aesKeyLength = 256;
  
  /// API 키 관련 설정
  /// API 키 최소 길이
  static const int minApiKeyLength = 20;
  
  /// API 키 최대 시도 횟수
  static const int maxApiKeyAttempts = 5;
  
  /// API 키 잠금 시간(분)
  static const int apiKeyLockoutMinutes = 30;
  
  /// 비밀번호 관련 설정
  /// 비밀번호 최소 길이
  static const int minPasswordLength = 8;
  
  /// 비밀번호 최대 길이
  static const int maxPasswordLength = 100;
  
  /// 비밀번호 강도 요구사항 (0-4, 숫자가 클수록 강력한 비밀번호 요구)
  static const int requiredPasswordStrength = 2;
  
  /// 비밀번호 변경 요구 주기(일)
  static const int passwordChangeDays = 90;
  
  /// 세션 관련 설정
  /// 세션 타임아웃(분)
  static const int sessionTimeoutMinutes = 30;
  
  /// 자동 로그아웃 활성화
  bool _autoLogout = true;
  bool get autoLogout => _autoLogout;
  
  /// XSS 보호 활성화
  bool _xssProtection = true;
  bool get xssProtection => _xssProtection;
  
  /// CSRF 보호 활성화
  bool _csrfProtection = true;
  bool get csrfProtection => _csrfProtection;
  
  /// 민감한 오류 메시지 숨기기
  bool _hideSensitiveErrors = true;
  bool get hideSensitiveErrors => _hideSensitiveErrors;
  
  /// 동시 로그인 세션 허용
  bool _allowMultipleSessions = false;
  bool get allowMultipleSessions => _allowMultipleSessions;
  
  /// 로그 저장 설정
  bool _useFirestoreLogging = false;
  bool get useFirestoreLogging => _useFirestoreLogging;
  
  bool _useLocalFileLogging = !kIsWeb;
  bool get useLocalFileLogging => _useLocalFileLogging;
  
  /// 로그 보존 기간(일)
  static const int logRetentionDays = 30;
  
  /// Content Security Policy 헤더
  String _contentSecurityPolicy = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self' https://firebaseapp.com https://googleapis.com; object-src 'none'";
  String get contentSecurityPolicy => _contentSecurityPolicy;
  
  /// 환경에 따른 설정 초기화
  Future<void> initialize({
    SecurityLogLevel logLevel = SecurityLogLevel.info,
    bool useFirestoreLogging = false,
    bool useLocalFileLogging = !kIsWeb,
    bool autoLogout = true,
    bool xssProtection = true,
    bool csrfProtection = true,
    bool hideSensitiveErrors = true,
    bool allowMultipleSessions = false,
    String? contentSecurityPolicy,
  }) async {
    _logLevel = logLevel;
    _useFirestoreLogging = useFirestoreLogging;
    _useLocalFileLogging = useLocalFileLogging && !kIsWeb;
    _autoLogout = autoLogout;
    _xssProtection = xssProtection;
    _csrfProtection = csrfProtection;
    _hideSensitiveErrors = hideSensitiveErrors;
    _allowMultipleSessions = allowMultipleSessions;
    
    if (contentSecurityPolicy != null) {
      _contentSecurityPolicy = contentSecurityPolicy;
    }
    
    // 보안 로거 초기화
    await SecurityLogger().initialize(
      logLevel: _logLevel,
      useFirestore: _useFirestoreLogging,
      useLocalFile: _useLocalFileLogging,
    );
    
    debugPrint('보안 설정 초기화 완료');
  }
  
  /// 개발 환경 설정 로드
  Future<void> loadDevelopmentConfig() async {
    await initialize(
      logLevel: SecurityLogLevel.debug,
      useFirestoreLogging: false,
      hideSensitiveErrors: false,
    );
  }
  
  /// 프로덕션 환경 설정 로드
  Future<void> loadProductionConfig() async {
    await initialize(
      logLevel: SecurityLogLevel.warn,
      useFirestoreLogging: true,
      hideSensitiveErrors: true,
    );
  }
  
  /// 테스트 환경 설정 로드
  Future<void> loadTestConfig() async {
    await initialize(
      logLevel: SecurityLogLevel.debug,
      useFirestoreLogging: false,
      useLocalFileLogging: true,
      hideSensitiveErrors: false,
    );
  }
} 