import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf_learner_v2/services/secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_keys.dart';

/// API 키 관리 서비스 클래스
class ApiKeyService extends ChangeNotifier {
  // 싱글톤 패턴 구현
  static final ApiKeyService _instance = ApiKeyService._internal();
  factory ApiKeyService() => _instance;
  
  ApiKeyService._internal();
  
  // 보안 저장소
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // API 키 저장소 키
  static const String _apiKeyKey = 'general_api_key';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _googleApiKeyKey = 'google_api_key';
  
  // API 키 캐시
  String? _apiKey;
  String? _geminiApiKey;
  String? _googleApiKey;
  
  // API 키 존재 여부 확인
  bool get hasApiKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
  
  // API 키 가져오기
  String? getApiKey([String? keyType]) {
    if (keyType == null) {
      return _geminiApiKey ?? _apiKey;
    }
    
    switch (keyType) {
      case 'gemini':
      case 'google_ai':
        return _geminiApiKey;
      case 'google':
        return _googleApiKey;
      default:
        return _apiKey;
    }
  }
  
  /// API 키 비동기 조회
  Future<String?> getApiKeyAsync([String? keyType]) async {
    if (!_isInitialized) await initialize();
    return getApiKey(keyType);
  }
  
  // API 키 설정
  Future<void> _setApiKeySharedPreferences(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
  
  /// 제미니 API 키 설정
  Future<void> setGeminiApiKey(String apiKey) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 보안 저장소에 저장 시도
      await _secureStorage.write(key: _geminiApiKeyKey, value: apiKey);
      _geminiApiKey = apiKey;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: 제미니 API 키 저장 완료 (보안 저장소)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에 제미니 API 키 저장 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에 저장 시도
        await _setApiKeySharedPreferences(_geminiApiKeyKey, apiKey);
        _geminiApiKey = apiKey;
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: 제미니 API 키 저장 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: SharedPreferences에 제미니 API 키 저장 실패 - $e');
        }
        throw Exception('API 키 저장 실패');
      }
    }
  }
  
  /// Google API 키 설정
  Future<void> setGoogleApiKey(String apiKey) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 보안 저장소에 저장 시도
      await _secureStorage.write(key: _googleApiKeyKey, value: apiKey);
      _googleApiKey = apiKey;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: Google API 키 저장 완료 (보안 저장소)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에 Google API 키 저장 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에 저장 시도
        await _setApiKeySharedPreferences(_googleApiKeyKey, apiKey);
        _googleApiKey = apiKey;
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: Google API 키 저장 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: SharedPreferences에 Google API 키 저장 실패 - $e');
        }
        throw Exception('API 키 저장 실패');
      }
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String keyType) async {
    if (!_isInitialized) await initialize();
    
    String key;
    switch (keyType) {
      case 'gemini':
      case 'google_ai':
        key = _geminiApiKeyKey;
        _geminiApiKey = null;
        break;
      case 'google':
        key = _googleApiKeyKey;
        _googleApiKey = null;
        break;
      default:
        key = _apiKeyKey;
        _apiKey = null;
        break;
    }
    
    try {
      // 보안 저장소에서 삭제 시도
      await _secureStorage.delete(key: key);
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: API 키 삭제 완료 (보안 저장소)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에서 API 키 삭제 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에서 삭제 시도
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: API 키 삭제 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: SharedPreferences에서 API 키 삭제 실패 - $e');
        }
        throw Exception('API 키 삭제 실패');
      }
    }
  }
  
  /// 사용자 입력 키 저장
  Future<void> saveUserProvidedKey(String uid, String keyType, String apiKey) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('user_api_keys').doc(uid).set({
        keyType: apiKey,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('ApiKeyService: 사용자 API 키 Firestore에 저장 완료');
      }
      
      // 로컬에도 저장
      switch (keyType) {
        case 'gemini':
        case 'google_ai':
          await setGeminiApiKey(apiKey);
          break;
        case 'google':
          await setGoogleApiKey(apiKey);
          break;
        default:
          await saveApiKey(apiKey);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 사용자 API 키 저장 실패 - $e');
      }
      throw Exception('API 키 저장 실패');
    }
  }
  
  // 초기화 상태
  bool _isInitialized = false;
  
  /// 초기화 여부
  bool get isInitialized => _isInitialized;
  
  /// 초기화 메서드
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadApiKeys();
      _isInitialized = true;
      if (kDebugMode) {
        print('ApiKeyService: 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 초기화 실패 - $e');
      }
    }
  }
  
  /// API 키 로드
  Future<void> _loadApiKeys() async {
    try {
      // 보안 저장소에서 시도
      _apiKey = await _secureStorage.read(key: _apiKeyKey);
      _geminiApiKey = await _secureStorage.read(key: _geminiApiKeyKey);
      _googleApiKey = await _secureStorage.read(key: _googleApiKeyKey);
      
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에서 API 키 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소 로드 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에서 시도
        final prefs = await SharedPreferences.getInstance();
        _apiKey = prefs.getString(_apiKeyKey);
        _geminiApiKey = prefs.getString(_geminiApiKeyKey);
        _googleApiKey = prefs.getString(_googleApiKeyKey);
        
        if (kDebugMode) {
          print('ApiKeyService: SharedPreferences에서 API 키 로드 완료');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: SharedPreferences 로드 실패 - $e');
        }
      }
    }
  }
  
  /// 일반 API 키 저장
  Future<void> saveApiKey(String apiKey) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 보안 저장소에 저장 시도
      await _secureStorage.write(key: _apiKeyKey, value: apiKey);
      _apiKey = apiKey;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: API 키 저장 완료 (보안 저장소)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에 API 키 저장 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에 저장 시도
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_apiKeyKey, apiKey);
        _apiKey = apiKey;
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: API 키 저장 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: API 키 저장 실패 - $e');
        }
      }
    }
  }
  
  /// API 키 유효성 검사 (캐시된 결과)
  bool isApiKeyValidCached(String apiKey) {
    // 기본 검사: 최소 길이 확인
    return apiKey.length >= 32;
  }
  
  /// API 키 유효성 검사
  Future<bool> isValidApiKey(String apiKey) async {
    // 기본 검사: 최소 길이 확인
    if (apiKey.length < 32) {
      return false;
    }
    
    // 여기에 실제 API 유효성 검증 로직 추가
    return true;
  }
  
  /// API 키 오류 메시지 가져오기
  String getApiKeyErrorMessage(String apiKey) {
    if (apiKey.isEmpty) {
      return 'API 키가 필요합니다';
    }
    
    if (apiKey.length < 32) {
      return 'API 키가 너무 짧습니다';
    }
    
    return '유효하지 않은 API 키입니다';
  }
  
  /// API 키 마스킹 처리
  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '****';
    }
    
    return apiKey.substring(0, 4) + '****' + apiKey.substring(apiKey.length - 4);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 사용자 API 키 정보를 Firestore에 저장
  Future<void> updateUserApiKeyStatus(String userId, bool hasCustomKey) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'hasCustomApiKey': hasCustomKey,
      });
    } catch (e) {
      print('사용자 API 키 상태 업데이트 중 오류 발생: $e');
    }
  }
  
  /// API 사용량 업데이트
  Future<void> updateApiUsage(String userId) async {
    try {
      // 오늘 날짜 가져오기
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final apiUsageKey = 'api_usage_$userId';
      
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> usageData = {};
      
      if (prefs.containsKey(apiUsageKey)) {
        final saved = prefs.getString(apiUsageKey);
        if (saved != null) {
          usageData = Map<String, dynamic>.from(jsonDecode(saved));
        }
      }
      
      // 오늘 날짜의 사용량 업데이트
      final todayKey = today.toString();
      final todayCount = (usageData[todayKey] as int?) ?? 0;
      usageData[todayKey] = todayCount + 1;
      
      // 저장
      await prefs.setString(apiUsageKey, jsonEncode(usageData));
      
      // Firestore에도 총 사용량 업데이트
      await _firestore.collection('users').doc(userId).update({
        'apiCallsToday': FieldValue.increment(1),
        'totalApiCalls': FieldValue.increment(1),
      });
    } catch (e) {
      print('API 할당량 사용량 업데이트 중 오류 발생: $e');
    }
  }
  
  // 오늘 API 호출 횟수 가져오기
  Future<int> getTodayApiUsage(String userId) async {
    try {
      // 오늘 날짜 가져오기
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayKey = today.toString();
      
      // 기존 사용량 데이터 가져오기
      final apiUsageKey = 'api_usage_$userId';
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(apiUsageKey);
      
      if (saved == null) return 0;
      
      final usageData = jsonDecode(saved) as Map<String, dynamic>;
      
      // 오늘 날짜의 사용량 반환
      return (usageData[todayKey] as int?) ?? 0;
    } catch (e) {
      print('오늘 API 사용량 가져오기 중 오류 발생: $e');
      return 0;
    }
  }
  
  // 할당량 초과 여부 확인
  Future<bool> isQuotaExceeded(String userId, int maxQuota) async {
    final usage = await getTodayApiUsage(userId);
    return usage >= maxQuota;
  }

  /// API 키 설정
  Future<void> setApiKey(String keyType, String apiKey) async {
    if (!_isInitialized) await initialize();
    
    switch (keyType) {
      case 'gemini':
      case 'google_ai':
        await setGeminiApiKey(apiKey);
        break;
      case 'google':
        await setGoogleApiKey(apiKey);
        break;
      default:
        await saveApiKey(apiKey);
        break;
    }
  }
} 