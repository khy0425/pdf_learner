import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class ApiKeyService {
  final FlutterSecureStorage _storage;
  static const String _keyPrefix = 'api_key_';

  ApiKeyService(this._storage);

  /// API 키 저장
  Future<void> setApiKey(String service, String key) async {
    try {
      await _storage.write(key: _keyPrefix + service, value: key);
    } catch (e) {
      throw Exception('API 키 저장 실패: $e');
    }
  }

  /// API 키 가져오기
  Future<String?> getApiKey(String service) async {
    try {
      return await _storage.read(key: _keyPrefix + service);
    } catch (e) {
      throw Exception('API 키 가져오기 실패: $e');
    }
  }

  /// API 키 삭제
  Future<void> deleteApiKey(String service) async {
    try {
      await _storage.delete(key: _keyPrefix + service);
    } catch (e) {
      throw Exception('API 키 삭제 실패: $e');
    }
  }

  /// 모든 API 키 삭제
  Future<void> deleteAllApiKeys() async {
    try {
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      throw Exception('모든 API 키 삭제 실패: $e');
    }
  }

  /// API 키 존재 여부 확인
  Future<bool> hasApiKey(String service) async {
    try {
      final key = await getApiKey(service);
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
} 