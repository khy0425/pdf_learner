import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// API 키를 관리하는 서비스 클래스
@singleton
class ApiKeyService {
  final FlutterSecureStorage _storage;
  
  ApiKeyService(this._storage);
  
  /// API 키 저장
  Future<void> saveApiKey(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw Exception('API 키 저장에 실패했습니다: $e');
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw Exception('API 키 조회에 실패했습니다: $e');
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw Exception('API 키 삭제에 실패했습니다: $e');
    }
  }
  
  /// 모든 API 키 삭제
  Future<void> deleteAllApiKeys() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('모든 API 키 삭제에 실패했습니다: $e');
    }
  }
  
  /// API 키 존재 여부 확인
  Future<bool> containsApiKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw Exception('API 키 존재 여부 확인 실패: $e');
    }
  }
  
  /// 모든 API 키 가져오기
  Future<Map<String, String>> getAllApiKeys() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw Exception('모든 API 키 조회 실패: $e');
    }
  }
} 