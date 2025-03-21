import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
import 'dart:async';
import '../services/web_firebase_initializer.dart';
import '../repositories/user_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/secure_storage.dart';
import '../utils/security_logger.dart';
import '../utils/input_validator.dart';
import '../utils/rate_limiter.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// API 키 캐시 클래스
class _CachedApiKey {
  final String apiKey;
  final DateTime timestamp;
  final bool isValid;
  
  _CachedApiKey({
    required this.apiKey,
    required this.timestamp,
    required this.isValid,
  });
}

/// 프리미엄 사용자 상태 캐시 클래스
class _CachedPremiumStatus {
  final bool isPremium;
  final DateTime timestamp;
  
  _CachedPremiumStatus({
    required this.isPremium,
    required this.timestamp,
  });
}

/// 검증 상태 클래스
class _ValidationStatus {
  final bool isValid;
  final DateTime timestamp;
  final bool isValidating;
  
  _ValidationStatus({
    required this.isValid,
    required this.timestamp,
    this.isValidating = false,
  });
}

/// API 키 관리를 담당하는 Service 클래스
class ApiKeyService {
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore;
  final SecureStorage _secureStorage;
  final SecurityLogger _securityLogger;
  final RateLimiter _rateLimiter;
  final FirebaseAuth _auth;
  final bool _isWeb;
  
  // API 키 캐싱
  final Map<String, _CachedApiKey> _apiKeyCache = {};
  
  // 유효하지 않은 API 키에 대한 오류 메시지
  final Map<String, String> _apiKeyErrorMessages = {};
  
  // API 키 검증 상태
  final Map<String, _ValidationStatus> _validationStatus = {};
  
  // 테스트 전용: 오버라이드 값
  Map<String, dynamic> testOverrides = {};
  
  // 사용자가 프리미엄 사용자인지 확인합니다
  final Map<String, _CachedPremiumStatus> _premiumStatusCache = {};
  
  ApiKeyService({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository(),
        _isWeb = kIsWeb,
        _firestore = FirebaseFirestore.instance,
        _secureStorage = SecureStorage(),
        _securityLogger = SecurityLogger(),
        _rateLimiter = RateLimiter(),
        _auth = FirebaseAuth.instance {
    _initServices();
  }
  
  /// 테스트용 생성자
  /// 모든 의존성을 직접 주입할 수 있습니다.
  ApiKeyService.forTesting({
    UserRepository? userRepository,
    required SecureStorage secureStorage,
    required SecurityLogger securityLogger,
    required RateLimiter rateLimiter,
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _userRepository = userRepository ?? UserRepository(),
       _isWeb = kIsWeb,
       _firestore = firestore,
       _secureStorage = secureStorage,
       _securityLogger = securityLogger,
       _rateLimiter = rateLimiter,
       _auth = firebaseAuth {
    _initServices();
  }
  
  // 서비스 초기화
  Future<void> _initServices() async {
    await _secureStorage.initialize();
    await _securityLogger.initialize(
      logLevel: SecurityLogLevel.info,
      useFirestore: false,
    );
    await _rateLimiter.initialize();
    debugPrint('ApiKeyService: 보안 서비스 초기화 완료');
    
    // 정기적인 캐시 정리 스케줄러
    Timer.periodic(const Duration(minutes: 30), (_) {
      _cleanupCache();
    });
  }
  
  /// API 키 저장
  Future<void> saveApiKey(String userId, String apiKey) async {
    try {
      debugPrint('API 키 저장 시작: $userId');
      
      // 요청 제한 확인
      final clientId = _getClientId(userId);
      if (await _rateLimiter.isRateLimited(clientId, 'api_key_validation')) {
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          'API 키 저장 속도 제한 초과',
          level: SecurityLogLevel.warn,
          data: {'userId': userId},
        );
        throw Exception('너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.');
      }
      
      // 입력 유효성 검사
      if (!InputValidator.isValidApiKey(apiKey, ApiKeyType.gemini)) {
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          'API 키 형식이 유효하지 않음',
          level: SecurityLogLevel.warn,
          data: {'userId': userId},
        );
        throw Exception('API 키 형식이 올바르지 않습니다. Gemini API 키는 "AI"로 시작해야 합니다.');
      }
      
      // API 키 유효성 검증
      final isValid = await isValidApiKey(apiKey);
      if (!isValid) {
        final errorMessage = _apiKeyErrorMessages[apiKey] ?? 'API 키가 유효하지 않습니다.';
        throw Exception(errorMessage);
      }
      
      // 보안 스토리지에 저장
      final storageKey = 'api_key_$userId';
      await _secureStorage.saveSecureData(storageKey, apiKey);
      debugPrint('보안 스토리지에 API 키 저장 완료');
      
      // 캐싱
      _apiKeyCache[userId] = _CachedApiKey(
        apiKey: apiKey,
        timestamp: DateTime.now(),
        isValid: true,
      );
      
      // Firestore에 저장 (암호화된 상태로)
      try {
        // 실제 구현에서는 백엔드에서 암호화 처리하는 것이 더 안전
        await _firestore.collection('users').doc(userId).update({
          'hasApiKey': true,  // 실제 키는 저장하지 않고 존재 여부만 표시
          'apiKeyUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        _securityLogger.log(
          SecurityEvent.apiKeyAdded,
          'API 키 추가됨',
          level: SecurityLogLevel.info,
          data: {'userId': userId},
        );
        
        debugPrint('Firestore에 API 키 상태 저장 완료');
      } catch (e) {
        debugPrint('Firestore API 키 저장 오류: $e');
        
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          'API 키 Firestore 저장 실패',
          level: SecurityLogLevel.error,
          data: {'userId': userId, 'error': e.toString()},
        );
        
        throw Exception('API 키를 Firestore에 저장하는 중 오류가 발생했습니다: ${_getHumanReadableError(e)}');
      }
    } catch (e) {
      debugPrint('saveApiKey 메서드 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키 저장 실패',
        level: SecurityLogLevel.error,
        data: {'userId': userId, 'error': e.toString()},
      );
      
      throw Exception('API 키 저장 중 오류가 발생했습니다: ${_getHumanReadableError(e)}');
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String userId) async {
    try {
      debugPrint('API 키 조회 시작: $userId');
      
      // 캐시에서 API 키 확인
      if (_apiKeyCache.containsKey(userId)) {
        final cachedKey = _apiKeyCache[userId]!;
        // 1시간 이내의 캐시만 사용
        if (DateTime.now().difference(cachedKey.timestamp).inMinutes < 60) {
          debugPrint('캐시에서 API 키 조회 성공');
          return cachedKey.apiKey;
        }
      }
      
      // 유료 회원인지 확인
      final isPremiumUser = await _checkPremiumStatus(userId);
      if (isPremiumUser) {
        debugPrint('유료 회원이므로 내부 API 키 사용');
        // 환경 변수에서 내부 API 키 가져오기 시도
        final dotEnvMap = testOverrides['dotenv'] as Map<String, String>? ?? dotenv.env;
        final internalApiKey = dotEnvMap['GEMINI_API_KEY'];
        if (internalApiKey != null && internalApiKey.isNotEmpty) {
          debugPrint('내부 API 키 사용');
          
          _securityLogger.log(
            SecurityEvent.apiKeyVerified,
            '내부 API 키 사용됨',
            level: SecurityLogLevel.debug,
            data: {'userId': userId, 'isPremium': true},
          );
          
          // 캐싱
          _apiKeyCache[userId] = _CachedApiKey(
            apiKey: internalApiKey,
            timestamp: DateTime.now(),
            isValid: true,
          );
          
          return internalApiKey;
        }
      }
      
      // 보안 스토리지에서 API 키 조회
      final storageKey = 'api_key_$userId';
      final apiKey = await _secureStorage.getSecureData(storageKey);
      
      if (apiKey != null && apiKey.isNotEmpty) {
        debugPrint('보안 스토리지에서 API 키 조회 성공');
        
        _securityLogger.log(
          SecurityEvent.apiKeyVerified,
          '사용자 API 키 검색됨',
          level: SecurityLogLevel.debug,
          data: {'userId': userId},
        );
        
        // 캐싱
        _apiKeyCache[userId] = _CachedApiKey(
          apiKey: apiKey,
          timestamp: DateTime.now(),
          isValid: true,
        );
        
        return apiKey;
      }
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키를 찾을 수 없음',
        level: SecurityLogLevel.warn,
        data: {'userId': userId},
      );
      
      debugPrint('API 키를 찾을 수 없음: $userId');
      return null;
    } catch (e) {
      debugPrint('getApiKey 메서드 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키 조회 오류',
        level: SecurityLogLevel.error,
        data: {'userId': userId, 'error': e.toString()},
      );
      
      return null;
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String userId) async {
    try {
      debugPrint('API 키 삭제 시작: $userId');
      
      // 캐시에서 삭제
      _apiKeyCache.remove(userId);
      
      // 보안 스토리지에서 삭제
      final storageKey = 'api_key_$userId';
      await _secureStorage.deleteSecureData(storageKey);
      debugPrint('보안 스토리지에서 API 키 삭제 완료');
      
      // Firestore에서 상태 업데이트
      try {
        await _firestore.collection('users').doc(userId).update({
          'hasApiKey': false,
          'apiKeyUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        _securityLogger.log(
          SecurityEvent.apiKeyRemoved,
          'API 키 삭제됨',
          level: SecurityLogLevel.info,
          data: {'userId': userId},
        );
        
        debugPrint('Firestore에서 API 키 상태 업데이트 완료');
      } catch (e) {
        debugPrint('Firestore API 키 상태 업데이트 오류: $e');
        
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          'API 키 Firestore 상태 업데이트 실패',
          level: SecurityLogLevel.error,
          data: {'userId': userId, 'error': e.toString()},
        );
        
        throw Exception('API 키 상태를 Firestore에서 업데이트하는 중 오류가 발생했습니다: ${_getHumanReadableError(e)}');
      }
    } catch (e) {
      debugPrint('deleteApiKey 메서드 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키 삭제 실패',
        level: SecurityLogLevel.error,
        data: {'userId': userId, 'error': e.toString()},
      );
      
      throw Exception('API 키 삭제 중 오류가 발생했습니다: ${_getHumanReadableError(e)}');
    }
  }
  
  /// API 키 유효성 검사 (결과 캐싱 적용)
  Future<bool> isValidApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        _apiKeyErrorMessages[apiKey] = 'API 키가 비어있습니다.';
        return false;
      }
      
      // 이미 검증된 키는 즉시 결과 반환
      if (_validationStatus.containsKey(apiKey)) {
        final status = _validationStatus[apiKey]!;
        if (DateTime.now().difference(status.timestamp).inMinutes < 30) {
          return status.isValid;
        }
      }
      
      // 실제 API 호출을 통한 검증
      final isValid = await _validateApiKey(apiKey);
      
      // 검증 결과 저장
      _validationStatus[apiKey] = _ValidationStatus(
        isValid: isValid,
        timestamp: DateTime.now(),
      );
      
      return isValid;
    } catch (e) {
      debugPrint('isValidApiKey 오류: $e');
      _apiKeyErrorMessages[apiKey] = '유효성 검사 중 오류: ${e.toString()}';
      return false;
    }
  }
  
  // API 키의 실제 검증 로직
  Future<bool> _validateApiKey(String apiKey) async {
    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro?key=$apiKey');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        _apiKeyErrorMessages[apiKey] = errorBody['error']['message'] ?? '유효하지 않은 API 키';
        return false;
      }
    } catch (e) {
      debugPrint('API 키 검증 오류: $e');
      _apiKeyErrorMessages[apiKey] = '네트워크 오류: ${e.toString()}';
      return false;
    }
  }
  
  /// API 키를 마스킹 처리하여 반환합니다
  String maskApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      return '';
    }
    
    if (apiKey.length <= 8) {
      return '********';
    }
    
    // 처음 4자와 마지막 4자만 표시하고 나머지는 *로 마스킹
    final prefix = apiKey.substring(0, 4);
    final suffix = apiKey.substring(apiKey.length - 4);
    final maskedLength = apiKey.length - 8;
    final maskedPart = '*' * maskedLength;
    
    return '$prefix$maskedPart$suffix';
  }
  
  // 유료 구독 확인
  Future<bool> _checkPremiumStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['subscriptionTier'] == 'premium' || data['subscriptionTier'] == 'basic';
      }
      return false;
    } catch (e) {
      debugPrint('구독 상태 확인 오류: $e');
      
      _securityLogger.log(
        SecurityEvent.dataAccessDenied,
        '구독 상태 확인 실패',
        level: SecurityLogLevel.warn,
        data: {'userId': userId, 'error': e.toString()},
      );
      
      return false;
    }
  }
  
  /// API 키 보안 감사 이벤트 기록 (의심스러운 활동)
  Future<void> logSuspiciousApiKeyActivity(String userId, String reason) async {
    await _securityLogger.log(
      SecurityEvent.suspiciousActivity,
      '의심스러운 API 키 활동 감지',
      level: SecurityLogLevel.critical,
      data: {
        'userId': userId,
        'reason': reason,
      },
      reportToAnalytics: true,
      reportToCrashlytics: true,
    );
  }
  
  /// API 키 사용량 기록
  Future<void> logApiKeyUsage(String userId, String service) async {
    await _securityLogger.log(
      SecurityEvent.aiRequestSent,
      'API 키 사용됨',
      level: SecurityLogLevel.info,
      data: {
        'userId': userId,
        'service': service,
      },
    );
  }
  
  /// 오류 메시지 가독성 향상
  String _getHumanReadableError(dynamic error) {
    final message = error.toString();
    
    if (message.contains('network') || message.contains('SocketException')) {
      return '네트워크 연결을 확인해주세요.';
    } else if (message.contains('permission') || message.contains('denied')) {
      return '권한이 없거나 접근이 거부되었습니다.';
    } else if (message.contains('not found') || message.contains('존재하지 않')) {
      return '요청한 정보를 찾을 수 없습니다.';
    } else if (message.contains('timeout')) {
      return '서버 응답 시간이 초과되었습니다.';
    } else if (message.contains('format') || message.contains('parse')) {
      return '데이터 형식이 올바르지 않습니다.';
    }
    
    // Exception에서 메시지 부분만 추출
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    
    return message;
  }
  
  /// 클라이언트 ID 생성
  String _getClientId(String userId) {
    return RateLimiter.generateClientId(userId);
  }
  
  /// 캐시 정리
  void _cleanupCache() {
    final now = DateTime.now();
    _apiKeyCache.removeWhere((_, cachedKey) => 
      now.difference(cachedKey.timestamp).inHours > 2  // 2시간 이상 된 캐시 제거
    );
    
    _validationStatus.removeWhere((_, status) => 
      !status.isValidating && now.difference(status.timestamp).inMinutes > 30  // 30분 이상 된 검증 상태 제거
    );
    
    // 100개 이상의 오류 메시지가 있으면 가장 오래된 것부터 제거
    if (_apiKeyErrorMessages.length > 100) {
      final keys = _apiKeyErrorMessages.keys.toList();
      for (int i = 0; i < keys.length - 100; i++) {
        _apiKeyErrorMessages.remove(keys[i]);
      }
    }
  }
  
  /// API 키가 유효한지 확인 (캐시된 결과 반환)
  bool isApiKeyValidCached(String apiKey) {
    // 검증 상태 확인
    if (_validationStatus.containsKey(apiKey) && 
        _validationStatus[apiKey]!.isValid &&
        DateTime.now().difference(_validationStatus[apiKey]!.timestamp).inMinutes < 60) {
      return true;
    }
    
    // 캐시된 값이 없으면 형식만 검사
    return InputValidator.isValidApiKey(apiKey, ApiKeyType.gemini);
  }
  
  /// API 키 오류 메시지 가져오기
  String? getApiKeyErrorMessage(String apiKey) {
    return _apiKeyErrorMessages[apiKey];
  }
  
  /// 현재 로그인된 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  /// 사용자가 프리미엄 사용자인지 확인합니다
  Future<bool> isPremiumUser(String userId) async {
    try {
      // 캐시된 값이 있을 경우 사용
      final now = DateTime.now();
      if (_premiumStatusCache.containsKey(userId)) {
        final cacheEntry = _premiumStatusCache[userId]!;
        if (now.difference(cacheEntry.timestamp).inHours < 1) {
          return cacheEntry.isPremium;
        }
      }
      
      // 실제 구현은 SubscriptionService를 통해 확인
      final isPremium = await _checkPremiumStatus(userId);
      
      // 캐시 업데이트
      _premiumStatusCache[userId] = _CachedPremiumStatus(
        isPremium: isPremium,
        timestamp: now,
      );
      
      return isPremium;
    } catch (e) {
      debugPrint('isPremiumUser 오류: $e');
      return false;
    }
  }
} 