import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 민감한 정보를 안전하게 저장하기 위한 보안 저장소 서비스
class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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