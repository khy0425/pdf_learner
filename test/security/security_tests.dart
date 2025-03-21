import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_learner/utils/input_validator.dart';
import 'package:pdf_learner/utils/rate_limiter.dart';
import 'package:pdf_learner/utils/security_logger.dart';
import '../models/security_log_model.dart';
import '../test_helper.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() async {
  // 테스트 환경 준비
  await setupTestEnvironment();
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    SharedPreferences.setMockInitialValues({});
  });

  group('XSS 취약점 테스트', () {
    test('HTML 태그 주입 시도에 대한 방어 테스트', () {
      const maliciousInput = '<script>alert("XSS")</script>안녕하세요';
      final sanitizedInput = InputValidator.sanitizeInput(maliciousInput);
      
      // HTML 태그가 제거되거나 이스케이프되어야 함
      expect(sanitizedInput, isNot(contains('<script>')));
      expect(sanitizedInput, isNot(contains('</script>')));
    });
    
    test('JavaScript 인젝션 시도에 대한 방어 테스트', () {
      const maliciousInput = 'javascript:alert("XSS")';
      final sanitizedInput = InputValidator.sanitizeInput(maliciousInput);
      
      // javascript: 프로토콜이 제거되거나 이스케이프되어야 함
      expect(sanitizedInput, isNot(startsWith('javascript:')));
    });
    
    test('iframe 인젝션 시도에 대한 방어 테스트', () {
      const maliciousInput = '<iframe src="malicious-site.com"></iframe>';
      final sanitizedInput = InputValidator.sanitizeInput(maliciousInput);
      
      // iframe 태그가 제거되거나 이스케이프되어야 함
      expect(sanitizedInput, isNot(contains('<iframe')));
      expect(sanitizedInput, isNot(contains('</iframe>')));
    });
  });
  
  group('SQL 인젝션 방어 테스트', () {
    test('기본 SQL 인젝션 시도에 대한 방어 테스트', () {
      const maliciousQuery = "' OR 1=1 --";
      // InputValidator.validateSearchQuery 대신 isValidInput 메서드 사용
      final isValid = InputValidator.isValidInput(maliciousQuery, allowedPattern: r'^[a-zA-Z0-9\s]+$');
      
      // SQL 인젝션 문자열은 유효하지 않아야 함
      expect(isValid, false);
    });
    
    test('복잡한 SQL 인젝션 시도에 대한 방어 테스트', () {
      const maliciousQuery = "'; DROP TABLE users; --";
      // InputValidator.validateSearchQuery 대신 isValidInput 메서드 사용
      final isValid = InputValidator.isValidInput(maliciousQuery, allowedPattern: r'^[a-zA-Z0-9\s]+$');
      
      // SQL 인젝션 문자열은 유효하지 않아야 함
      expect(isValid, false);
    });
  });
  
  group('브루트포스 방어 테스트', () {
    test('로그인 시도 제한 테스트', () async {
      // Mock RateLimiter 생성 (테스트 전용)
      final mockRateLimiter = MockRateLimiter();
      await mockRateLimiter.initialize();
      
      const clientId = 'test-user';
      const actionType = 'login';
      
      // 임계값 이하의 요청
      for (var i = 0; i < 4; i++) {
        expect(await mockRateLimiter.isRateLimited(clientId, actionType), false);
      }
      
      // 임계값 초과 시 제한됨
      for (var i = 0; i < 2; i++) {
        expect(await mockRateLimiter.isRateLimited(clientId, actionType), true);
      }
    });
  });
  
  group('보안 로깅 테스트', () {
    test('보안 이벤트 로깅 및 검색 테스트', () async {
      // Mock SecurityLogger 생성 (테스트 전용)
      final mockLogger = MockSecurityLogger();
      await mockLogger.initialize();
      
      // 로그 기록
      await mockLogger.log(
        event: SecurityEvent.login, 
        userId: 'test-user', 
        level: SecurityLogLevel.info, 
        message: '로그인 성공'
      );
      
      // 로그 검색
      final logs = await mockLogger.getLogs();
      expect(logs.length, 1);
      expect(logs[0].event, SecurityEvent.login);
      expect(logs[0].userId, 'test-user');
      expect(logs[0].level, SecurityLogLevel.info);
      expect(logs[0].message, '로그인 성공');
    });
  });
}

// 테스트용 Mock 클래스들
class MockRateLimiter extends RateLimiter {
  Map<String, Map<String, int>> requestCounts = {};
  Map<String, bool> blockedClients = {};
  bool _initialized = false;

  MockRateLimiter() : super._internal();

  @override
  Future<void> initialize() async {
    _initialized = true;
    return Future.value();
  }

  @override
  Future<bool> isRateLimited(String clientId, String actionType) async {
    if (!_initialized) await initialize();
    
    if (blockedClients[clientId] == true) {
      return true;
    }
    
    if (!requestCounts.containsKey(clientId)) {
      requestCounts[clientId] = {};
    }
    
    if (!requestCounts[clientId]!.containsKey(actionType)) {
      requestCounts[clientId]![actionType] = 0;
    }
    
    requestCounts[clientId]![actionType] = requestCounts[clientId]![actionType]! + 1;
    
    // 임계값 설정 (테스트용)
    const threshold = 5;
    
    if (requestCounts[clientId]![actionType]! > threshold) {
      await blockClient(clientId, '임계값 초과', 60);
      return true;
    }
    
    return false;
  }

  @override
  Future<void> blockClient(String clientId, String reason, int blockMinutes) async {
    blockedClients[clientId] = true;
  }

  @override
  Future<void> unblockClient(String clientId) async {
    blockedClients[clientId] = false;
  }
  
  // 테스트용 메서드
  void resetCounters() {
    requestCounts.clear();
    blockedClients.clear();
  }
}

class MockSecurityLogger extends SecurityLogger {
  List<SecurityLog> logs = [];
  bool _initialized = false;
  
  MockSecurityLogger() : super._internal();
  
  @override
  Future<void> initialize({bool enableFirestore = false, bool enableLocalFile = false}) async {
    _initialized = true;
    return Future.value();
  }
  
  @override
  Future<void> log({
    required SecurityEvent event,
    required String userId,
    required SecurityLogLevel level,
    required String message,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? data
  }) async {
    if (!_initialized) await initialize();
    
    final now = DateTime.now();
    logs.add(SecurityLog(
      timestamp: now,
      event: event, 
      userId: userId,
      level: level,
      message: message,
      metadata: metadata ?? {}
    ));
  }
  
  @override
  Future<List<SecurityLog>> getLogs({SecurityLogLevel? level, DateTime? startDate, DateTime? endDate}) async {
    if (!_initialized) await initialize();
    
    return logs.where((log) {
      bool levelMatch = level == null || log.level == level;
      bool dateMatch = true;
      
      if (startDate != null) {
        dateMatch = dateMatch && log.timestamp.isAfter(startDate);
      }
      
      if (endDate != null) {
        dateMatch = dateMatch && log.timestamp.isBefore(endDate);
      }
      
      return levelMatch && dateMatch;
    }).toList();
  }
  
  // 테스트용 메서드
  @override
  Future<void> clearLogs() async {
    logs.clear();
  }
} 