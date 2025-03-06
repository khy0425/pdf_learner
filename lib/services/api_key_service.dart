import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:async';
import '../services/web_firebase_initializer.dart';

/// API 키 관리를 위한 서비스
class ApiKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userApiKeyKey = 'user_api_key';
  
  /// 현재 사용자 API 키 가져오기
  Future<String> getCurrentApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? userApiKey = prefs.getString(_userApiKeyKey);
    
    // 사용자 API 키가 있으면 사용, 없으면 개발자 키 사용
    return userApiKey ?? _getDeveloperApiKey();
  }
  
  /// 개발자 API 키 가져오기
  String _getDeveloperApiKey() {
    // .env 파일에서 API 키 가져오기
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }
  
  /// 사용자 API 키 저장
  Future<void> saveUserApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userApiKeyKey, apiKey);
  }
  
  /// 사용자 API 키 제거
  Future<void> removeUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userApiKeyKey);
  }
  
  /// 사용자 API 키 존재 여부 확인
  Future<bool> hasUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userApiKeyKey) && 
           prefs.getString(_userApiKeyKey)?.isNotEmpty == true;
  }
  
  /// API 키 유효성 검사 (간단한 형식 검사)
  bool isValidApiKey(String apiKey) {
    // Gemini API 키는 일반적으로 'AIza'로 시작
    return apiKey.startsWith('AIza') && apiKey.length > 20;
  }

  // 사용자의 구독 등급에 따라 적절한 API 키 반환
  Future<String> getAPIKey(String userId, SubscriptionTier tier) async {
    switch (tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.basic:
        // 무료 사용자는 자신의 API 키 사용
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        return doc.data()?['apiKey'] ?? '';
        
      case SubscriptionTier.premium:
      case SubscriptionTier.enterprise:
      case SubscriptionTier.plus:
      case SubscriptionTier.premiumTrial:
      case SubscriptionTier.guest:
        // 유료 회원은 개발자 API 키 사용
        if (kIsWeb) {
          // 웹 환경에서는 JavaScript를 통해 API 키 가져오기
          return await _getWebApiKey('gemini') ?? dotenv.env['GEMINI_API_KEY'] ?? '';
        } else {
          return dotenv.env['GEMINI_API_KEY'] ?? '';
        }
    }
  }

  // 웹 환경에서 JavaScript를 통해 API 키 가져오기
  Future<String?> _getWebApiKey(String keyName) async {
    if (!kIsWeb) return null;
    
    try {
      return await WebFirebaseInitializer.getApiKey(keyName);
    } catch (e) {
      print('웹 API 키 가져오기 예외: $e');
      return null;
    }
  }

  // API 키 저장 (무료 사용자용)
  Future<void> saveAPIKey(String userId, String apiKey) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set({
          'apiKey': apiKey,
        }, SetOptions(merge: true));
  }

  // API 키 유효성 검사
  Future<bool> validateAPIKey(String apiKey) async {
    try {
      // 특정 API 키는 항상 유효하다고 처리 (테스트용)
      if (apiKey == 'AIzaSyBS3xinuJpr9DIGLAqTCKHCg6XqZjeoB74') {
        return true;
      }
      
      if (kIsWeb) {
        // 웹 환경에서는 JavaScript를 통해 API 키 검증
        return await WebFirebaseInitializer.validateApiKey('gemini', apiKey);
      }
      
      // Gemini API 키 검증 로직
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Hello',
                },
              ],
            },
          ],
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('API 키 검증 오류: $e');
      return false;
    }
  }

  // API 키 가져오기
  Future<String?> getApiKey() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 JavaScript를 통해 API 키 가져오기
        final webApiKey = await _getWebApiKey('gemini');
        if (webApiKey?.isNotEmpty ?? false) {
          return webApiKey;
        }
      }
      
      // 1. 먼저 .env 파일의 API 키 확인
      final envApiKey = dotenv.env['GEMINI_API_KEY'];
      if (envApiKey?.isNotEmpty ?? false) {
        return envApiKey;
      }

      // 2. 사용자가 입력한 API 키 확인
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString(_userApiKeyKey);
      if (userApiKey?.isNotEmpty ?? false) {
        return userApiKey;
      }

      return null;
    } catch (e) {
      print('API 키 조회 오류: $e');
      return null;
    }
  }

  // 사용자 API 키 저장
  Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userApiKeyKey, apiKey);
    } catch (e) {
      print('API 키 저장 오류: $e');
      throw Exception('API 키를 저장할 수 없습니다.');
    }
  }

  // 사용자 API 키 제거
  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userApiKeyKey);
    } catch (e) {
      print('API 키 제거 오류: $e');
      throw Exception('API 키를 제거할 수 없습니다.');
    }
  }

  // Firebase API 키 가져오기
  String? getFirebaseApiKey() {
    if (kIsWeb) {
      // 웹 환경에서는 JavaScript를 통해 Firebase 설정에서 API 키 가져오기
      try {
        final config = js.context['firebaseConfig'];
        if (config != null) {
          return config['apiKey']?.toString();
        }
      } catch (e) {
        print('웹 Firebase API 키 가져오기 오류: $e');
      }
    }
    return dotenv.env['FIREBASE_API_KEY'];
  }
} 