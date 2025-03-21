import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_learner/config/security_config.dart';
import 'package:pdf_learner/utils/security_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late SecurityConfig securityConfig;
  
  setUp(() async {
    // 테스트를 위한 SharedPreferences 설정
    SharedPreferences.setMockInitialValues({});
    securityConfig = SecurityConfig();
  });
  
  group('SecurityConfig 테스트', () {
    test('기본 초기화가 올바르게 수행되는지 확인', () async {
      // 실행
      await securityConfig.initialize();
      
      // 확인
      expect(securityConfig.logLevel, SecurityLogLevel.info);
      expect(securityConfig.useFirestoreLogging, false);
      expect(securityConfig.xssProtection, true);
      expect(securityConfig.csrfProtection, true);
      expect(securityConfig.hideSensitiveErrors, true);
      expect(securityConfig.allowMultipleSessions, false);
    });
    
    test('개발 환경 설정이 올바르게 적용되는지 확인', () async {
      // 실행
      await securityConfig.loadDevelopmentConfig();
      
      // 확인
      expect(securityConfig.logLevel, SecurityLogLevel.debug);
      expect(securityConfig.useFirestoreLogging, false);
      expect(securityConfig.hideSensitiveErrors, false);
    });
    
    test('프로덕션 환경 설정이 올바르게 적용되는지 확인', () async {
      // 실행
      await securityConfig.loadProductionConfig();
      
      // 확인
      expect(securityConfig.logLevel, SecurityLogLevel.warn);
      expect(securityConfig.useFirestoreLogging, true);
      expect(securityConfig.hideSensitiveErrors, true);
    });
    
    test('테스트 환경 설정이 올바르게 적용되는지 확인', () async {
      // 실행
      await securityConfig.loadTestConfig();
      
      // 확인
      expect(securityConfig.logLevel, SecurityLogLevel.debug);
      expect(securityConfig.useFirestoreLogging, false);
      expect(securityConfig.useLocalFileLogging, true);
      expect(securityConfig.hideSensitiveErrors, false);
    });
    
    test('사용자 정의 설정이 올바르게 적용되는지 확인', () async {
      // 실행
      await securityConfig.initialize(
        logLevel: SecurityLogLevel.error,
        autoLogout: false,
        csrfProtection: false,
        allowMultipleSessions: true,
        contentSecurityPolicy: "default-src 'self'; script-src 'self'",
      );
      
      // 확인
      expect(securityConfig.logLevel, SecurityLogLevel.error);
      expect(securityConfig.autoLogout, false);
      expect(securityConfig.csrfProtection, false);
      expect(securityConfig.allowMultipleSessions, true);
      expect(securityConfig.contentSecurityPolicy, "default-src 'self'; script-src 'self'");
    });
    
    test('API 키 관련 상수가 올바른지 확인', () {
      expect(SecurityConfig.minApiKeyLength, 20);
      expect(SecurityConfig.maxApiKeyAttempts, 5);
      expect(SecurityConfig.apiKeyLockoutMinutes, 30);
    });
    
    test('비밀번호 관련 상수가 올바른지 확인', () {
      expect(SecurityConfig.minPasswordLength, 8);
      expect(SecurityConfig.maxPasswordLength, 100);
      expect(SecurityConfig.requiredPasswordStrength, 2);
      expect(SecurityConfig.passwordChangeDays, 90);
    });
    
    test('세션 관련 상수가 올바른지 확인', () {
      expect(SecurityConfig.sessionTimeoutMinutes, 30);
    });
    
    test('암호화 관련 상수가 올바른지 확인', () {
      expect(SecurityConfig.aesKeyLength, 256);
    });
    
    test('로그 보존 기간이 올바른지 확인', () {
      expect(SecurityConfig.logRetentionDays, 30);
    });
    
    test('싱글톤 패턴이 올바르게 작동하는지 확인', () {
      final instance1 = SecurityConfig();
      final instance2 = SecurityConfig();
      
      expect(identical(instance1, instance2), true);
    });
  });
} 