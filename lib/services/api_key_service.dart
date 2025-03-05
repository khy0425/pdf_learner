import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_tier.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// API 키 관리를 위한 서비스
class ApiKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userApiKeyKey = 'user_api_key';
  
  /// 현재 사용할 API 키 가져오기
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
  
  /// 사용자 API 키 삭제
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
    // OpenAI API 키는 일반적으로 'sk-'로 시작하고 길이가 51자
    return apiKey.startsWith('sk-') && apiKey.length > 20;
  }

  // 사용자의 구독 등급에 따라 적절한 API 키 반환
  Future<String> getAPIKey(String userId, SubscriptionTier tier) async {
    switch (tier) {
      case SubscriptionTier.guest:
      case SubscriptionTier.basic:
        // 무료 사용자는 자신의 API 키 사용
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        return doc.data()?['apiKey'] ?? '';
        
      case SubscriptionTier.plus:
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumTrial:
        // 유료 회원은 개발자 API 키 사용
        return dotenv.env['GEMINI_API_KEY'] ?? '';
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
      // Gemini API 키 검증 로직
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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
      return false;
    }
  }

  // API 키 가져오기
  Future<String?> getApiKey() async {
    try {
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

  // 사용자 API 키 삭제
  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userApiKeyKey);
    } catch (e) {
      print('API 키 삭제 오류: $e');
      throw Exception('API 키를 삭제할 수 없습니다.');
    }
  }

  // Firebase API 키 가져오기
  String? getFirebaseApiKey() {
    return dotenv.env['FIREBASE_API_KEY'];
  }
} 