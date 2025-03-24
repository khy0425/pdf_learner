import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_learner_v2/services/api_key_service.dart';
import 'package:pdf_learner_v2/services/subscription_service.dart';
import 'package:pdf_learner_v2/services/secure_storage.dart';
import 'dart:convert';

enum ApiKeySource {
  user,  // 사용자가 직접 입력한 API 키
  free,  // 무료 사용자를 위한 API 키
  paid,  // 유료 사용자를 위한 API 키
  none   // API 키 없음
}

/// API 키 관리 서비스
class ApiKeyManager {
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;
  ApiKeyManager._internal();
  
  final SecureStorage _secureStorage = SecureStorage();
  static const String _userProvidedKeyKey = 'user_provided_api_key';
  
  // 키 종류별 기본값 (실제로는 .env 파일이나 Firebase Remote Config 등에서 로드)
  static const String _freeUserApiKey = 'AIzaFreeUserApiKeyPlaceholder123456789'; 
  static const String _paidUserApiKey = 'AIzaPaidUserApiKeyPlaceholder123456789';
  
  // 키 캐시
  String? _cachedApiKey;
  ApiKeySource? _cachedKeySource;
  
  /// 사용자가 제공한 API 키 가져오기
  Future<String?> getUserProvidedKey() async {
    try {
      return await _secureStorage.getApiKey();
    } catch (e) {
      debugPrint('사용자 제공 API 키 로드 중 오류: $e');
      return null;
    }
  }
  
  /// 사용자가 제공한 API 키 저장
  Future<void> saveUserProvidedKey(String apiKey) async {
    await _secureStorage.saveApiKey(apiKey);
    // 캐시 무효화
    _cachedApiKey = null;
    _cachedKeySource = null;
  }
  
  /// 사용자가 제공한 API 키 삭제
  Future<void> clearUserProvidedKey() async {
    await _secureStorage.deleteApiKey();
    // 캐시 무효화
    _cachedApiKey = null;
    _cachedKeySource = null;
  }
  
  // API 키 반환
  Future<String?> getApiKey({
    required ApiKeyService apiKeyService,
    required SubscriptionService subscriptionService,
    User? user,
  }) async {
    // 캐시된 키가 있으면 반환
    if (_cachedApiKey != null && _cachedKeySource != null) {
      return _cachedApiKey;
    }
    
    try {
      // 1. 사용자가 입력한 키가 있는지 확인
      final userApiKey = await apiKeyService.getApiKey();
      if (userApiKey != null && userApiKey.isNotEmpty) {
        _cachedApiKey = userApiKey;
        _cachedKeySource = ApiKeySource.user;
        return userApiKey;
      }
      
      // 2. 로그인한 사용자면서 유료 구독자인 경우 유료 키 제공
      if (user != null) {
        final isPaidUser = await subscriptionService.isUserPremium(user.uid);
        if (isPaidUser) {
          _cachedApiKey = _paidUserApiKey;
          _cachedKeySource = ApiKeySource.paid;
          return _paidUserApiKey;
        }
      }
      
      // 3. 그 외 경우는 무료 키 제공
      _cachedApiKey = _freeUserApiKey;
      _cachedKeySource = ApiKeySource.free;
      return _freeUserApiKey;
    } catch (e) {
      print('API 키 가져오기 중 오류 발생: $e');
      return null;
    }
  }
  
  // 현재 API 키 소스 확인
  ApiKeySource? getCurrentKeySource() {
    return _cachedKeySource;
  }
  
  // API 키 캐시 초기화
  void clearCache() {
    _cachedApiKey = null;
    _cachedKeySource = null;
  }
  
  // 할당량 초과 여부 확인
  Future<bool> isQuotaExceeded(String userId, SubscriptionService subscriptionService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorage();
      
      // 오늘 날짜 구하기
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayKey = today.toString();
      
      // 해당 사용자의 API 사용량 가져오기
      final apiUsageKey = 'api_usage_$userId';
      Map<String, dynamic> usageData = {};
      
      if (prefs.getString(apiUsageKey) != null) {
        usageData = Map<String, dynamic>.from(
          await secureStorage.getJson(apiUsageKey) ?? {}
        );
      }
      
      // 오늘 사용량
      final todayCount = (usageData[todayKey] as int?) ?? 0;
      
      // 사용자의 구독 등급에 따른 최대 할당량 가져오기
      final userQuota = subscriptionService.getQuotaForUser(subscriptionService.currentUser);
      
      // 할당량 초과 여부 반환
      return todayCount >= userQuota;
    } catch (e) {
      print('할당량 확인 중 오류 발생: $e');
      return false;
    }
  }
  
  // API 사용량 증가
  Future<void> incrementApiUsage(String userId) async {
    try {
      final secureStorage = SecureStorage();
      final prefs = await SharedPreferences.getInstance();
      
      // 오늘 날짜 구하기
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayKey = today.toString();
      
      // 해당 사용자의 API 사용량 가져오기
      final apiUsageKey = 'api_usage_$userId';
      Map<String, dynamic> usageData = {};
      
      if (prefs.getString(apiUsageKey) != null) {
        usageData = Map<String, dynamic>.from(
          await secureStorage.getJson(apiUsageKey) ?? {}
        );
      }
      
      // 오늘 사용량 증가
      final todayCount = (usageData[todayKey] as int?) ?? 0;
      usageData[todayKey] = todayCount + 1;
      
      // 저장
      await secureStorage.saveJson(apiUsageKey, usageData);
    } catch (e) {
      print('API 사용량 업데이트 중 오류 발생: $e');
    }
  }
} 