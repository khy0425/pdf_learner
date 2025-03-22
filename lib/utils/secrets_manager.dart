import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 앱 비밀 정보 관리 클래스
class SecretsManager {
  static const String _firebaseKeysKey = 'firebase_keys';
  static const String _apiKeysKey = 'api_keys';
  static const String _userSecretsKey = 'user_secrets';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// 초기화 완료 여부
  bool _isInitialized = false;
  
  /// 초기화 여부 확인
  bool get isInitialized => _isInitialized;
  
  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 테스트 키-값을 저장해서 사용 가능한지 확인
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      await _secureStorage.delete(key: 'test_key');
      
      _isInitialized = true;
      if (kDebugMode) {
        print('SecretsManager: 초기화 완료');
      }
    } catch (e) {
      // 보안 저장소 초기화 실패 - SharedPreferences로 대체
      if (kDebugMode) {
        print('SecretsManager: 보안 저장소 초기화 실패, SharedPreferences 사용 - $e');
      }
      _isInitialized = true;
    }
  }
  
  /// Firebase API 키 저장
  Future<void> saveFirebaseApiKey(String apiKey) async {
    await _saveSecret(_firebaseKeysKey, 'api_key', apiKey);
  }
  
  /// Firebase 프로젝트 ID 저장
  Future<void> saveFirebaseProjectId(String projectId) async {
    await _saveSecret(_firebaseKeysKey, 'project_id', projectId);
  }
  
  /// Firebase 앱 ID 저장
  Future<void> saveFirebaseAppId(String appId) async {
    await _saveSecret(_firebaseKeysKey, 'app_id', appId);
  }
  
  /// Firebase 메시징 발신자 ID 저장
  Future<void> saveFirebaseMessagingSenderId(String messagingSenderId) async {
    await _saveSecret(_firebaseKeysKey, 'messaging_sender_id', messagingSenderId);
  }
  
  /// Firebase 스토리지 버킷 저장
  Future<void> saveFirebaseStorageBucket(String storageBucket) async {
    await _saveSecret(_firebaseKeysKey, 'storage_bucket', storageBucket);
  }
  
  /// Firebase API 키 가져오기
  Future<String?> getFirebaseApiKey() async {
    return await _getSecret(_firebaseKeysKey, 'api_key');
  }
  
  /// Firebase 프로젝트 ID 가져오기
  Future<String?> getFirebaseProjectId() async {
    return await _getSecret(_firebaseKeysKey, 'project_id');
  }
  
  /// Firebase 앱 ID 가져오기
  Future<String?> getFirebaseAppId() async {
    return await _getSecret(_firebaseKeysKey, 'app_id');
  }
  
  /// Firebase 메시징 발신자 ID 가져오기
  Future<String?> getFirebaseMessagingSenderId() async {
    return await _getSecret(_firebaseKeysKey, 'messaging_sender_id');
  }
  
  /// Firebase 스토리지 버킷 가져오기
  Future<String?> getFirebaseStorageBucket() async {
    return await _getSecret(_firebaseKeysKey, 'storage_bucket');
  }
  
  /// API 키 저장
  Future<void> saveApiKey(String service, String apiKey) async {
    await _saveSecret(_apiKeysKey, service, apiKey);
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String service) async {
    return await _getSecret(_apiKeysKey, service);
  }
  
  /// 사용자 비밀 정보 저장
  Future<void> saveUserSecret(String key, String value) async {
    await _saveSecret(_userSecretsKey, key, value);
  }
  
  /// 사용자 비밀 정보 가져오기
  Future<String?> getUserSecret(String key) async {
    return await _getSecret(_userSecretsKey, key);
  }
  
  /// 비밀 정보 삭제
  Future<void> deleteSecret(String category, String key) async {
    try {
      final data = await _getSecretCategory(category);
      if (data != null) {
        data.remove(key);
        await _saveSecretCategory(category, data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 비밀 정보 삭제 실패 - $e');
      }
    }
  }
  
  /// 모든 비밀 정보 삭제
  Future<void> clearAllSecrets() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firebaseKeysKey);
      await prefs.remove(_apiKeysKey);
      await prefs.remove(_userSecretsKey);
      
      if (kDebugMode) {
        print('SecretsManager: 모든 비밀 정보 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 모든 비밀 정보 삭제 실패 - $e');
      }
    }
  }
  
  /// 내부: 비밀 정보 저장 구현
  Future<void> _saveSecret(String category, String key, String value) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 현재 카테고리 데이터 가져오기
      Map<String, dynamic> data = await _getSecretCategory(category) ?? {};
      
      // 데이터 업데이트
      data[key] = value;
      
      // 저장
      await _saveSecretCategory(category, data);
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 비밀 정보 저장 실패 - $e');
      }
    }
  }
  
  /// 내부: 비밀 정보 가져오기 구현
  Future<String?> _getSecret(String category, String key) async {
    if (!_isInitialized) await initialize();
    
    try {
      final data = await _getSecretCategory(category);
      return data?[key] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 비밀 정보 가져오기 실패 - $e');
      }
      return null;
    }
  }
  
  /// 내부: 카테고리 데이터 가져오기
  Future<Map<String, dynamic>?> _getSecretCategory(String category) async {
    try {
      // 보안 저장소에서 시도
      final jsonStr = await _secureStorage.read(key: category);
      if (jsonStr != null) {
        return json.decode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 보안 저장소에서 가져오기 실패, SharedPreferences 시도 - $e');
      }
    }
    
    try {
      // SharedPreferences에서 시도
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(category);
      if (jsonStr != null) {
        return json.decode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: SharedPreferences에서 가져오기 실패 - $e');
      }
    }
    
    return null;
  }
  
  /// 내부: 카테고리 데이터 저장
  Future<void> _saveSecretCategory(String category, Map<String, dynamic> data) async {
    final jsonStr = json.encode(data);
    
    try {
      // 보안 저장소에 저장 시도
      await _secureStorage.write(key: category, value: jsonStr);
      return;
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: 보안 저장소에 저장 실패, SharedPreferences 시도 - $e');
      }
    }
    
    try {
      // SharedPreferences에 저장 시도
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(category, jsonStr);
    } catch (e) {
      if (kDebugMode) {
        print('SecretsManager: SharedPreferences에 저장 실패 - $e');
      }
    }
  }
} 