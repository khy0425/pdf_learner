import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 비회원 사용자를 관리하는 서비스
class AnonymousUserService {
  static const String _anonymousUserKey = 'anonymous_user_id';
  static const String _usageCountKey = 'usage_count';
  static const int _freeUsageLimit = 3; // 무료 사용 한도 (예: PDF 요약 3회)
  
  /// 임시 사용자 ID 생성 또는 가져오기
  Future<String> getAnonymousUserId() async {
    if (kIsWeb) {
      // 웹 환경에서는 localStorage 사용
      final storage = await _getLocalStorage();
      String? userId = storage.getString(_anonymousUserKey);
      
      if (userId == null) {
        userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
        await storage.setString(_anonymousUserKey, userId);
      }
      
      return userId;
    } else {
      // 네이티브 환경에서는 SharedPreferences 사용
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_anonymousUserKey);
      
      if (userId == null) {
        userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_anonymousUserKey, userId);
      }
      
      return userId;
    }
  }
  
  /// 사용 횟수 증가 및 확인
  Future<int> incrementUsage() async {
    final storage = await _getLocalStorage();
    int count = storage.getInt(_usageCountKey) ?? 0;
    count++;
    await storage.setInt(_usageCountKey, count);
    return count;
  }
  
  /// PDF 사용 횟수 증가 (incrementUsage와 동일한 기능)
  Future<int> incrementUsageCount() async {
    return incrementUsage();
  }
  
  /// 현재 사용 횟수 가져오기
  Future<int> getCurrentUsage() async {
    final storage = await _getLocalStorage();
    return storage.getInt(_usageCountKey) ?? 0;
  }
  
  /// 무료 사용 한도 초과 여부 확인
  Future<bool> isFreeLimitExceeded() async {
    final storage = await _getLocalStorage();
    int count = storage.getInt(_usageCountKey) ?? 0;
    return count >= _freeUsageLimit;
  }
  
  /// 남은 무료 사용 횟수 확인
  Future<int> getRemainingFreeUsage() async {
    final storage = await _getLocalStorage();
    int count = storage.getInt(_usageCountKey) ?? 0;
    return _freeUsageLimit - count > 0 ? _freeUsageLimit - count : 0;
  }
  
  /// 사용 횟수 초기화 (회원가입 시)
  Future<void> resetUsage() async {
    final storage = await _getLocalStorage();
    await storage.setInt(_usageCountKey, 0);
  }
  
  /// 로컬 스토리지 가져오기 (웹/네이티브 환경 통합)
  Future<LocalStorage> _getLocalStorage() async {
    return LocalStorage(await SharedPreferences.getInstance());
  }
}

/// 로컬 스토리지 래퍼 클래스 (웹/네이티브 환경 통합)
class LocalStorage {
  final SharedPreferences _prefs;
  
  LocalStorage(this._prefs);
  
  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);
  
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
  bool containsKey(String key) => _prefs.containsKey(key);
} 