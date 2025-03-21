import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_learner/utils/security_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';

@GenerateMocks([SharedPreferences])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late SecurityLogger logger;
  Map<String, dynamic> storedLogs = {};
  
  setUp(() async {
    // 테스트용 SharedPreferences 모의 설정
    SharedPreferences.setMockInitialValues({});
    
    logger = SecurityLogger();
    
    // 저장된 로그를 모의하는 함수
    storedLogs = {};
  });
  
  group('SecurityLogger 테스트', () {
    test('초기화가 성공적으로 수행되는지 확인', () async {
      // 실행
      await logger.initialize(
        logLevel: SecurityLogLevel.debug,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 확인
      expect(logger.isInitialized, isTrue);
    });
    
    test('로그 기록 및 조회 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.debug,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 실행
      await logger.log(
        SecurityEvent.loginAttempt,
        '사용자 로그인 시도',
        data: {'userId': 'test123'}
      );
      
      await logger.log(
        SecurityEvent.loginSuccess, 
        '로그인 성공',
        data: {'userId': 'test123'}
      );
      
      await logger.log(
        SecurityEvent.apiKeyVerified, 
        'API 키 검증됨',
        data: {'keyType': 'gemini'}
      );
      
      // 모든 로그 가져오기
      final allLogs = await logger.getAllLogs();
      
      // 특정 이벤트에 대한 로그 가져오기
      final loginLogs = await logger.getLogsByEvent(SecurityEvent.loginSuccess);
      
      // 확인
      expect(allLogs.length, 4); // appStarted도 포함됨
      expect(loginLogs.length, 1);
      expect(loginLogs[0]['message'], '로그인 성공');
      expect(loginLogs[0]['data']['userId'], 'test123');
    });
    
    test('로그 레벨 필터링 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.warn, // warn 이상만 기록
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 실행 - debug는 무시됨
      await logger.log(
        SecurityEvent.loginAttempt,
        '디버그 로그',
        level: SecurityLogLevel.debug
      );
      
      // 실행 - info는 무시됨
      await logger.log(
        SecurityEvent.loginAttempt,
        '정보 로그',
        level: SecurityLogLevel.info
      );
      
      // 실행 - warn은 기록됨
      await logger.log(
        SecurityEvent.suspiciousActivity,
        '경고 로그',
        level: SecurityLogLevel.warn
      );
      
      // 실행 - error는 기록됨
      await logger.log(
        SecurityEvent.loginFailed,
        '오류 로그',
        level: SecurityLogLevel.error
      );
      
      // 확인
      final allLogs = await logger.getAllLogs();
      expect(allLogs.length, 3); // appStarted도 포함됨
      
      final warningLog = allLogs.firstWhere((log) => log['level'] == 'warn');
      expect(warningLog['message'], '경고 로그');
      
      final errorLog = allLogs.firstWhere((log) => log['level'] == 'error');
      expect(errorLog['message'], '오류 로그');
    });
    
    test('로그 내보내기 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.info,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 몇 가지 로그 추가
      await logger.log(SecurityEvent.loginSuccess, '로그인 성공');
      await logger.log(SecurityEvent.apiKeyUsed, 'API 키 사용됨');
      
      // CSV로 내보내기
      final csv = await logger.exportLogsAsCsv();
      
      // 확인
      expect(csv.contains('timestamp,event,level,message,userId,platform,sessionId'), isTrue);
      expect(csv.contains('loginSuccess'), isTrue);
      expect(csv.contains('apiKeyUsed'), isTrue);
      expect(csv.contains('로그인 성공'), isTrue);
      expect(csv.contains('API 키 사용됨'), isTrue);
    });
    
    test('로그 삭제 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.info,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 로그 추가
      await logger.log(SecurityEvent.loginSuccess, '로그인 성공');
      
      // 로그 존재 확인
      var logs = await logger.getAllLogs();
      expect(logs.length, 2); // appStarted도 포함됨
      
      // 로그 삭제
      await logger.clearLogs();
      
      // 로그가 삭제되었는지 확인
      logs = await logger.getAllLogs();
      expect(logs.length, 0);
    });
    
    test('CSV 필드 이스케이핑 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.info,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 콤마와 따옴표가 포함된 메시지
      const testMessage = 'This message contains, commas and "quotes"';
      await logger.log(SecurityEvent.configChanged, testMessage);
      
      // CSV로 내보내기
      final csv = await logger.exportLogsAsCsv();
      
      // 확인 - 따옴표가 이스케이프되었는지 확인
      expect(csv.contains('This message contains, commas and ""quotes""'), isTrue);
    });
    
    test('날짜 범위 필터링 테스트', () async {
      // 설정
      await logger.initialize(
        logLevel: SecurityLogLevel.info,
        useFirestore: false,
        useLocalFile: false,
      );
      
      // 과거 날짜 생성
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));
      
      // 로그 추가 및 타임스탬프 조작
      final yesterdayLog = {
        'timestamp': yesterday.toIso8601String(),
        'event': 'loginSuccess',
        'level': 'info',
        'message': '어제 로그인',
        'userId': 'test123',
        'data': {},
        'platform': 'test',
        'sessionId': '123456',
      };
      
      final lastWeekLog = {
        'timestamp': lastWeek.toIso8601String(),
        'event': 'loginSuccess',
        'level': 'info',
        'message': '지난주 로그인',
        'userId': 'test123',
        'data': {},
        'platform': 'test',
        'sessionId': '123456',
      };
      
      // 로그 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('security_log_${yesterday.millisecondsSinceEpoch}', jsonEncode(yesterdayLog));
      await prefs.setString('security_log_${lastWeek.millisecondsSinceEpoch}', jsonEncode(lastWeekLog));
      
      // 3일 전부터 현재까지의 로그만 필터링
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final filteredLogs = await logger.getLogsByDateRange(threeDaysAgo, now);
      
      // 어제의 로그만 포함되어야 함
      expect(filteredLogs.length, 1);
      expect(filteredLogs[0]['message'], '어제 로그인');
    });
  });
} 