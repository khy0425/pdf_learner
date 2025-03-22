import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _openAiApiKeyKey = 'openai_api_key';
  static const String _googleApiKeyKey = 'google_api_key';
  
  // API 키 캐시
  String? _apiKey;
  String? _openAiApiKey;
  String? _googleApiKey;
  
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
      _openAiApiKey = await _secureStorage.read(key: _openAiApiKeyKey);
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
        _openAiApiKey = prefs.getString(_openAiApiKeyKey);
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
  
  /// OpenAI API 키 저장
  Future<void> saveOpenAiApiKey(String apiKey) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 보안 저장소에 저장 시도
      await _secureStorage.write(key: _openAiApiKeyKey, value: apiKey);
      _openAiApiKey = apiKey;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: OpenAI API 키 저장 완료 (보안 저장소)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: 보안 저장소에 OpenAI API 키 저장 실패, SharedPreferences 시도 - $e');
      }
      
      try {
        // SharedPreferences에 저장 시도
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_openAiApiKeyKey, apiKey);
        _openAiApiKey = apiKey;
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: OpenAI API 키 저장 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: OpenAI API 키 저장 실패 - $e');
        }
      }
    }
  }
  
  /// Google API 키 저장
  Future<void> saveGoogleApiKey(String apiKey) async {
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_googleApiKeyKey, apiKey);
        _googleApiKey = apiKey;
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ApiKeyService: Google API 키 저장 완료 (SharedPreferences)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ApiKeyService: Google API 키 저장 실패 - $e');
        }
      }
    }
  }
  
  /// 일반 API 키 가져오기
  Future<String?> getApiKey() async {
    if (!_isInitialized) await initialize();
    
    if (_apiKey != null) {
      return _apiKey;
    }
    
    await _loadApiKeys();
    return _apiKey;
  }
  
  /// OpenAI API 키 가져오기
  Future<String?> getOpenAiApiKey() async {
    if (!_isInitialized) await initialize();
    
    if (_openAiApiKey != null) {
      return _openAiApiKey;
    }
    
    await _loadApiKeys();
    return _openAiApiKey;
  }
  
  /// Google API 키 가져오기
  Future<String?> getGoogleApiKey() async {
    if (!_isInitialized) await initialize();
    
    if (_googleApiKey != null) {
      return _googleApiKey;
    }
    
    await _loadApiKeys();
    return _googleApiKey;
  }
  
  /// 모든 API 키 삭제
  Future<void> clearAllApiKeys() async {
    try {
      // 보안 저장소에서 삭제 시도
      await _secureStorage.delete(key: _apiKeyKey);
      await _secureStorage.delete(key: _openAiApiKeyKey);
      await _secureStorage.delete(key: _googleApiKeyKey);
      
      // SharedPreferences에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
      await prefs.remove(_openAiApiKeyKey);
      await prefs.remove(_googleApiKeyKey);
      
      // 캐시 초기화
      _apiKey = null;
      _openAiApiKey = null;
      _googleApiKey = null;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: 모든 API 키 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: API 키 삭제 실패 - $e');
      }
    }
  }
  
  /// 일반 API 키 삭제
  Future<void> clearApiKey() async {
    try {
      // 보안 저장소에서 삭제 시도
      await _secureStorage.delete(key: _apiKeyKey);
      
      // SharedPreferences에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
      
      // 캐시 초기화
      _apiKey = null;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: API 키 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: API 키 삭제 실패 - $e');
      }
    }
  }
  
  /// OpenAI API 키 삭제
  Future<void> clearOpenAiApiKey() async {
    try {
      // 보안 저장소에서 삭제 시도
      await _secureStorage.delete(key: _openAiApiKeyKey);
      
      // SharedPreferences에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_openAiApiKeyKey);
      
      // 캐시 초기화
      _openAiApiKey = null;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: OpenAI API 키 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: OpenAI API 키 삭제 실패 - $e');
      }
    }
  }
  
  /// Google API 키 삭제
  Future<void> clearGoogleApiKey() async {
    try {
      // 보안 저장소에서 삭제 시도
      await _secureStorage.delete(key: _googleApiKeyKey);
      
      // SharedPreferences에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_googleApiKeyKey);
      
      // 캐시 초기화
      _googleApiKey = null;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('ApiKeyService: Google API 키 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiKeyService: Google API 키 삭제 실패 - $e');
      }
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String userId) async {
    await clearApiKey();
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
} 