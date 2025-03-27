import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/web_storage_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class StorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

/// 로컬 스토리지 서비스 구현
class SharedPreferencesService implements StorageService {
  final SharedPreferences _prefs;
  
  SharedPreferencesService(this._prefs);
  
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }
  
  @override
  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }
  
  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
  
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

/// 보안 스토리지 서비스 구현
class SecureStorageService implements StorageService {
  final FlutterSecureStorage _storage;
  
  SecureStorageService(this._storage);
  
  static Future<StorageService> create() async {
    final storage = const FlutterSecureStorage();
    return SecureStorageService(storage);
  }
  
  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

/// 웹 스토리지 서비스 구현 (브라우저에서 실행될 때)
class WebStorageService implements StorageService {
  WebStorageService();
  
  static Future<StorageService> create() async {
    return WebStorageService();
  }
  
  @override
  Future<String?> read(String key) async {
    if (kIsWeb) {
      return WebStorageUtils.getItem(key);
    }
    return null;
  }
  
  @override
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      WebStorageUtils.setItem(key, value);
    }
  }
  
  @override
  Future<void> delete(String key) async {
    if (kIsWeb) {
      WebStorageUtils.removeItem(key);
    }
  }
  
  @override
  Future<void> clear() async {
    if (kIsWeb) {
      WebStorageUtils.clear();
    }
  }
}

/// 스토리지 서비스 팩토리
class StorageServiceFactory {
  static Future<StorageService> getService({bool secure = false}) async {
    if (kIsWeb) {
      return await WebStorageService.create();
    } else {
      if (secure) {
        return await SecureStorageService.create();
      } else {
        return await SharedPreferencesService.create();
      }
    }
  }
} 