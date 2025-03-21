import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_learner/services/api_key_service.dart';
import 'package:pdf_learner/utils/input_validator.dart';
import 'package:pdf_learner/utils/secure_storage.dart';
import 'package:pdf_learner/utils/security_logger.dart';
import 'package:pdf_learner/utils/rate_limiter.dart';
import 'package:pdf_learner/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../test_helper.dart';

// Mocks
class MockSecureStorage extends Mock implements SecureStorage {
  Map<String, String> _data = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
    return Future.value();
  }

  @override
  Future<void> saveSecureData(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> getSecureData(String key) async {
    return _data[key];
  }

  @override
  Future<void> deleteSecureData(String key) async {
    _data.remove(key);
  }
}

class MockSecurityLogger extends Mock implements SecurityLogger {
  @override
  Future<void> initialize({SecurityLogLevel? logLevel, bool? useFirestore}) async {
    return Future.value();
  }

  @override
  Future<void> log(
    SecurityEvent event,
    String message, {
    SecurityLogLevel? level,
    Map<String, dynamic>? data,
  }) async {
    return Future.value();
  }
}

class MockRateLimiter extends Mock implements RateLimiter {
  @override
  Future<void> initialize() async {
    return Future.value();
  }

  @override
  Future<bool> isRateLimited(String clientId, String actionType) async {
    return false;
  }
}

class MockUserRepository extends Mock implements UserRepository {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() async {
  // 테스트 환경 준비
  await setupTestEnvironment();
  
  late ApiKeyService apiKeyService;
  late MockSecureStorage mockSecureStorage;
  late MockSecurityLogger mockSecurityLogger;
  late MockRateLimiter mockRateLimiter;
  late MockUserRepository mockUserRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    
    mockSecureStorage = MockSecureStorage();
    mockSecurityLogger = MockSecurityLogger();
    mockRateLimiter = MockRateLimiter();
    mockUserRepository = MockUserRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();
    
    apiKeyService = ApiKeyService.forTesting(
      userRepository: mockUserRepository,
      secureStorage: mockSecureStorage,
      securityLogger: mockSecurityLogger,
      rateLimiter: mockRateLimiter,
      firestore: mockFirebaseFirestore,
      firebaseAuth: mockFirebaseAuth,
    );
    
    apiKeyService.testOverrides = {
      'dotenv': {'GEMINI_API_KEY': 'AI-test-key-from-env'},
    };
  });

  group('API 키 서비스 테스트', () {
    test('API 키 저장 및 조회 테스트', () async {
      const userId = 'test-user-id';
      const apiKey = 'AI-test-gemini-key12345678901234567890';
      
      // API 키 저장
      await apiKeyService.saveApiKey(userId, apiKey);
      
      // API 키 조회
      final retrievedKey = await apiKeyService.getApiKey(userId);
      
      // 저장된 키와 조회된 키가 일치해야 함
      expect(retrievedKey, apiKey);
    });

    test('API 키 유효성 검증 테스트', () {
      // 유효한 Gemini API 키
      expect(InputValidator.isValidApiKey('AIzaSyA1234567890abcdefghijk', ApiKeyType.gemini), true);
      
      // 유효하지 않은 Gemini API 키
      expect(InputValidator.isValidApiKey('invalid-key', ApiKeyType.gemini), false);
      
      // 유효한 OpenAI API 키
      expect(InputValidator.isValidApiKey('sk-valid12345678901234567890', ApiKeyType.openai), true);
      
      // 유효하지 않은 OpenAI API 키
      expect(InputValidator.isValidApiKey('invalid-key', ApiKeyType.openai), false);
    });

    test('API 키 삭제 테스트', () async {
      const userId = 'test-user-id';
      const apiKey = 'AI-test-gemini-key12345678901234567890';
      
      // 키 저장
      await apiKeyService.saveApiKey(userId, apiKey);
      
      // 키 존재 확인
      var retrievedKey = await apiKeyService.getApiKey(userId);
      expect(retrievedKey, apiKey);
      
      // 키 삭제
      await apiKeyService.deleteApiKey(userId);
      
      // 키 삭제 확인
      retrievedKey = await apiKeyService.getApiKey(userId);
      expect(retrievedKey, isNull);
    });
  });
}