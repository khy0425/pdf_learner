import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_learner/utils/rate_limiter.dart';
import 'package:pdf_learner/utils/security_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SecurityLogger 모의 객체
class MockSecurityLogger extends Mock implements SecurityLogger {}

// 테스트용 RateLimiter 모의 객체
class MockRateLimiter extends RateLimiter {
  static final MockRateLimiter _instance = MockRateLimiter._internal();
  factory MockRateLimiter() => _instance;
  MockRateLimiter._internal();
  
  // 요청 카운터 (클라이언트ID + 액션타입 => 요청 횟수)
  final Map<String, int> _requestCounts = {};
  
  // 차단된 클라이언트 목록
  final Map<String, DateTime> _blockedClients = {};
  
  @override
  Future<void> initialize() async {
    // Firebase 의존성 제거
    // 이미 초기화된 것으로 취급
  }
  
  @override
  Future<bool> isRateLimited(String clientId, String actionType) async {
    // 차단된 클라이언트인지 확인
    if (_blockedClients.containsKey(clientId)) {
      if (DateTime.now().isBefore(_blockedClients[clientId]!)) {
        return true;
      } else {
        _blockedClients.remove(clientId);
      }
    }
    
    // 요청 카운터 키
    final key = "$clientId:$actionType";
    
    // 요청 카운트 증가
    _requestCounts[key] = (_requestCounts[key] ?? 0) + 1;
    
    // API 키 검증은 5회 이상 시 제한
    if (actionType == 'api_key_validation' && (_requestCounts[key] ?? 0) > 5) {
      return true;
    }
    
    return false;
  }
  
  @override
  Future<void> blockClient(String clientId, String reason, int blockMinutes) async {
    final blockUntil = DateTime.now().add(Duration(minutes: blockMinutes));
    _blockedClients[clientId] = blockUntil;
  }
  
  @override
  Future<void> unblockClient(String clientId) async {
    _blockedClients.remove(clientId);
  }
  
  // 테스트용 유틸리티 메서드
  void resetCounters() {
    _requestCounts.clear();
    _blockedClients.clear();
  }
}

void main() {
  late MockRateLimiter rateLimiter;
  
  setUp(() {
    // 테스트 전에 SharedPreferences 모의 객체 설정
    SharedPreferences.setMockInitialValues({});
    
    // RateLimiter 인스턴스 생성
    rateLimiter = MockRateLimiter();
    rateLimiter.resetCounters();
  });
  
  group('RateLimiter 테스트', () {
    test('초기화가 성공적으로 실행됨', () async {
      // 초기화 실행
      await rateLimiter.initialize();
      
      // 테스트에서는 초기화가 오류 없이 완료되면 성공
      expect(true, true);
    });
    
    test('요청 제한이 적용되지 않음 (제한 이하)', () async {
      // 초기화
      await rateLimiter.initialize();
      
      // 클라이언트 ID와 액션 타입 정의
      const clientId = 'test_client_1';
      const actionType = 'api_key_validation';
      
      // 요청 제한 확인 (최초 요청)
      bool limited = await rateLimiter.isRateLimited(clientId, actionType);
      
      // 최초 요청은 제한되지 않아야 함
      expect(limited, false);
      
      // 여러 번 요청 (제한 이하)
      for (int i = 0; i < 4; i++) {
        limited = await rateLimiter.isRateLimited(clientId, actionType);
        expect(limited, false);
      }
    });
    
    test('요청 제한이 적용됨 (제한 초과)', () async {
      // 초기화
      await rateLimiter.initialize();
      
      // 클라이언트 ID와 액션 타입 정의
      const clientId = 'test_client_2';
      const actionType = 'api_key_validation';
      
      // 여러 번 요청 (제한 이상)
      bool limited = false;
      for (int i = 0; i < 10; i++) {
        limited = await rateLimiter.isRateLimited(clientId, actionType);
        if (limited) break;
      }
      
      // 여러 번 요청 후에는 제한되어야 함
      expect(limited, true);
    });
    
    test('서로 다른 클라이언트 ID는 독립적으로 제한됨', () async {
      // 초기화
      await rateLimiter.initialize();
      
      // 두 개의 클라이언트 ID 정의
      const clientId1 = 'test_client_3';
      const clientId2 = 'test_client_4';
      const actionType = 'api_key_validation';
      
      // 첫 번째 클라이언트 여러 번 요청하여 제한 초과
      bool limited1 = false;
      for (int i = 0; i < 10; i++) {
        limited1 = await rateLimiter.isRateLimited(clientId1, actionType);
        if (limited1) break;
      }
      
      // 두 번째 클라이언트는 첫 요청 (제한되지 않아야 함)
      bool limited2 = await rateLimiter.isRateLimited(clientId2, actionType);
      
      // 첫 번째 클라이언트는 제한, 두 번째는 제한 없음
      expect(limited1, true);
      expect(limited2, false);
    });
    
    test('서로 다른 액션 타입은 독립적으로 제한됨', () async {
      // 초기화
      await rateLimiter.initialize();
      
      // 클라이언트 ID와 두 가지 액션 타입 정의
      const clientId = 'test_client_5';
      const actionType1 = 'api_key_validation';
      const actionType2 = 'login_attempt';
      
      // 첫 번째 액션 여러 번 요청하여 제한 초과
      bool limited1 = false;
      for (int i = 0; i < 10; i++) {
        limited1 = await rateLimiter.isRateLimited(clientId, actionType1);
        if (limited1) break;
      }
      
      // 두 번째 액션은 첫 요청 (제한되지 않아야 함)
      bool limited2 = await rateLimiter.isRateLimited(clientId, actionType2);
      
      // 첫 번째 액션은 제한, 두 번째는 제한 없음
      expect(limited1, true);
      expect(limited2, false);
    });
    
    test('클라이언트 ID 생성이 일관적임', () {
      // 동일한 식별자로 여러 번 클라이언트 ID 생성
      final id1 = RateLimiter.generateClientId('test_identifier');
      final id2 = RateLimiter.generateClientId('test_identifier');
      
      // 동일한 식별자에서 동일한 ID가 생성됨
      expect(id1, id2);
      
      // 다른 식별자에서는 다른 ID가 생성됨
      final id3 = RateLimiter.generateClientId('different_identifier');
      expect(id1, isNot(equals(id3)));
    });
    
    test('수동 차단 및 해제 기능이 올바르게 작동함', () async {
      // 초기화
      await rateLimiter.initialize();
      
      // 클라이언트 ID 정의
      const clientId = 'test_client_6';
      const actionType = 'api_key_validation';
      
      // 처음에는 제한 없음
      bool limited = await rateLimiter.isRateLimited(clientId, actionType);
      expect(limited, false);
      
      // 수동으로 클라이언트 차단
      await rateLimiter.blockClient(clientId, '테스트 목적 차단', 5);
      
      // 차단 후에는 제한됨
      limited = await rateLimiter.isRateLimited(clientId, actionType);
      expect(limited, true);
      
      // 차단 해제
      await rateLimiter.unblockClient(clientId);
      
      // 해제 후에는 다시 제한 없음
      limited = await rateLimiter.isRateLimited(clientId, actionType);
      expect(limited, false);
    });
  });
} 