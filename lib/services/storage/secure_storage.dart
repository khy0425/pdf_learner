import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'dart:convert';

/// 보안 저장소 서비스
/// 
/// 암호화된 방식으로 데이터를 안전하게 저장하고 관리합니다.
@lazySingleton
class SecureStorage {
  /// Flutter Secure Storage 인스턴스
  final FlutterSecureStorage _storage;
  
  /// 안드로이드 옵션
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  
  /// iOS 옵션
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );
  
  /// 생성자
  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
  
  /// 데이터 저장
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// 데이터 읽기
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  /// 데이터 삭제
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  /// 모든 데이터 삭제
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  /// 모든 키 목록 가져오기
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
  
  /// 데이터 존재 여부 확인
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// API 키를 저장합니다
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: 'gemini_api_key', value: apiKey);
  }

  /// API 키를 불러옵니다
  Future<String?> getApiKey() async {
    return await _storage.read(key: 'gemini_api_key');
  }

  /// API 키를 삭제합니다
  Future<void> deleteApiKey() async {
    await _storage.delete(key: 'gemini_api_key');
  }

  /// 저장된 API 키가 있는지 확인합니다
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// JSON 데이터를 저장합니다
  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    await _storage.write(key: key, value: jsonEncode(data));
  }

  /// JSON 데이터를 불러옵니다
  Future<Map<String, dynamic>?> getJson(String key) async {
    final data = await _storage.read(key: key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// 모든 저장소 데이터 삭제
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
} 