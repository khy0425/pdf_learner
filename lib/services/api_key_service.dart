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
    // 테스트 오버라이드 확인
    if (testOverrides.containsKey('isValidApiKey')) {
      final testImpl = testOverrides['isValidApiKey'] as Future<bool> Function(String);
      return await testImpl(apiKey);
    }
    
    // 빈 API 키는 유효하지 않음
    if (apiKey.isEmpty) {
      _apiKeyErrorMessages[apiKey] = '빈 API 키는 유효하지 않습니다.';
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키가 비어있음',
        level: SecurityLogLevel.warn,
      );
      return false;
    }
    
    // 형식 검사
    if (!InputValidator.isValidApiKey(apiKey, ApiKeyType.gemini)) {
      _apiKeyErrorMessages[apiKey] = 'API 키 형식이 올바르지 않습니다. Gemini API 키는 "AI"로 시작해야 합니다.';
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        '잘못된 API 키 형식',
        level: SecurityLogLevel.warn,
      );
      return false;
    }
    
    // 검증 중인지 확인
    if (_validationStatus.containsKey(apiKey) && 
        _validationStatus[apiKey]!.isValidating &&
        DateTime.now().difference(_validationStatus[apiKey]!.startTime).inSeconds < 30) {
      // 30초 이내에 이미 검증 중이면 이전 결과 반환 또는 대기
      if (_validationStatus[apiKey]!.lastResult != null) {
        return _validationStatus[apiKey]!.lastResult!;
      }
      
      // 최대 3초 대기
      int attempts = 0;
      while (_validationStatus.containsKey(apiKey) && 
             _validationStatus[apiKey]!.isValidating && 
             attempts < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      if (_validationStatus.containsKey(apiKey) && _validationStatus[apiKey]!.lastResult != null) {
        return _validationStatus[apiKey]!.lastResult!;
      }
    }
    
    // 요청 제한 확인
    final clientId = RateLimiter.generateClientId(apiKey.substring(0, min(apiKey.length, 10)));
    if (await _rateLimiter.isRateLimited(clientId, 'api_key_validation')) {
      _apiKeyErrorMessages[apiKey] = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      
      _securityLogger.log(
        SecurityEvent.rateLimit,
        'API 키 검증 속도 제한 초과',
        level: SecurityLogLevel.warn,
        data: {'clientId': clientId},
      );
      
      return false;
    }
    
    // 검증 상태 설정
    _validationStatus[apiKey] = _ValidationStatus(
      isValidating: true,
      startTime: DateTime.now(),
      lastResult: null,
    );
    
    return await _isValidApiKeyImpl(apiKey);
  }
  
  /// API 키 유효성 실제 검사 구현부 (테스트용으로 분리)
  Future<bool> _isValidApiKeyImpl(String apiKey) async {
    // 테스트 오버라이드 확인
    if (testOverrides.containsKey('isValidApiKeyImpl')) {
      final testImpl = testOverrides['isValidApiKeyImpl'] as Future<bool> Function(String);
      final isValid = await testImpl(apiKey);
      
      // 검증 상태 업데이트
      _validationStatus[apiKey] = _ValidationStatus(
        isValidating: false,
        startTime: _validationStatus[apiKey]!.startTime,
        lastResult: isValid,
        lastCheck: DateTime.now(),
      );
      
      return isValid;
    }
    
    // API 호출을 통한 실제 검증 시도
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'}
              ]
            }
          ],
        }),
      );
      
      final isValid = response.statusCode == 200;
      
      // 오류 메시지 설정
      if (!isValid) {
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? '알 수 없는 오류가 발생했습니다.';
          _apiKeyErrorMessages[apiKey] = 'API 키 검증 실패: $errorMessage';
        } catch (_) {
          _apiKeyErrorMessages[apiKey] = 'API 키 검증 실패: 상태 코드 ${response.statusCode}';
        }
      } else {
        _apiKeyErrorMessages.remove(apiKey);
      }
      
      if (isValid) {
        _securityLogger.log(
          SecurityEvent.apiKeyVerified,
          'API 키 유효성 검증 성공',
          level: SecurityLogLevel.info,
        );
      } else {
        _securityLogger.log(
          SecurityEvent.apiKeyFailed,
          'API 키 유효성 검증 실패',
          level: SecurityLogLevel.warn,
          data: {'statusCode': response.statusCode, 'response': response.body.substring(0, min(response.body.length, 100))},
        );
      }
      
      // 검증 상태 업데이트
      _validationStatus[apiKey] = _ValidationStatus(
        isValidating: false,
        startTime: _validationStatus[apiKey]!.startTime,
        lastResult: isValid,
        lastCheck: DateTime.now(),
      );
      
      return isValid;
    } catch (e) {
      debugPrint('API 키 검증 오류: $e');
      
      String errorMessage = '네트워크 오류가 발생했습니다.';
      
      if (e is SocketException) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (e is TimeoutException) {
        errorMessage = '서버 응답 시간이 초과되었습니다.';
      } else if (e is FormatException) {
        errorMessage = '응답 데이터 형식이 올바르지 않습니다.';
      }
      
      _apiKeyErrorMessages[apiKey] = 'API 키 검증 중 오류 발생: $errorMessage';
      
      _securityLogger.log(
        SecurityEvent.apiKeyFailed,
        'API 키 검증 중 오류 발생',
        level: SecurityLogLevel.error,
        data: {'error': e.toString()},
      );
      
      // 검증 상태 업데이트
      _validationStatus[apiKey] = _ValidationStatus(
        isValidating: false,
        startTime: _validationStatus[apiKey]!.startTime,
        lastResult: false,
        lastCheck: DateTime.now(),
      );
      
      return false;
    }
  }
  
  /// API 키 마스킹 (보안을 위해 일부만 표시)
  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '********';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
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
      !status.isValidating && now.difference(status.lastCheck ?? status.startTime).inMinutes > 30  // 30분 이상 된 검증 상태 제거
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
        _validationStatus[apiKey]!.lastResult != null &&
        !_validationStatus[apiKey]!.isValidating &&
        DateTime.now().difference(_validationStatus[apiKey]!.lastCheck ?? DateTime.now()).inMinutes < 60) {
      return _validationStatus[apiKey]!.lastResult!;
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
}

// 캐시된 API 키 클래스
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

// API 키 검증 상태
class _ValidationStatus {
  final bool isValidating;
  final DateTime startTime;
  final bool? lastResult;
  final DateTime? lastCheck;
  
  _ValidationStatus({
    required this.isValidating,
    required this.startTime,
    this.lastResult,
    this.lastCheck,
  });
} 