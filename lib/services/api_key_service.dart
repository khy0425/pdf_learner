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
import '../repositories/user_repository.dart';

/// API 키 관리를 담당하는 Service 클래스
class ApiKeyService {
  final UserRepository _userRepository;
  
  ApiKeyService({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository();
  
  /// API 키 저장
  Future<void> saveApiKey(String? userId, String apiKey) async {
    try {
      // 유효성 검사
      if (!isValidApiKey(apiKey)) {
        throw Exception('유효하지 않은 API 키입니다.');
      }
      
      // 로그인된 사용자인 경우 Firestore에 저장
      if (userId != null) {
        await _userRepository.saveApiKey(userId, apiKey);
      }
      
      // 로컬 저장소에도 저장 (오프라인 사용 지원)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', apiKey);
      
      debugPrint('API 키 저장 완료');
    } catch (e) {
      debugPrint('API 키 저장 오류: $e');
      rethrow;
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String? userId) async {
    try {
      String? apiKey;
      
      // 로그인된 사용자인 경우 Firestore에서 가져오기
      if (userId != null) {
        apiKey = await _userRepository.getApiKey(userId);
        if (apiKey != null) {
          return apiKey;
        }
      }
      
      // Firestore에 없거나 로그인되지 않은 경우 로컬 저장소에서 가져오기
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('api_key');
      
      // 로컬 저장소에도 없는 경우 환경 변수에서 가져오기
      if (apiKey == null || apiKey.isEmpty) {
        apiKey = dotenv.env['OPENAI_API_KEY'];
      }
      
      return apiKey;
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String? userId) async {
    try {
      // 로그인된 사용자인 경우 Firestore에서 삭제
      if (userId != null) {
        await _userRepository.updateUser(userId, {'apiKey': null});
      }
      
      // 로컬 저장소에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_key');
      
      debugPrint('API 키 삭제 완료');
    } catch (e) {
      debugPrint('API 키 삭제 오류: $e');
      rethrow;
    }
  }
  
  /// API 키 유효성 검사
  bool isValidApiKey(String apiKey) {
    // OpenAI API 키 형식 검사 (sk-로 시작하는 51자 문자열)
    return apiKey.startsWith('sk-') && apiKey.length >= 51;
  }
  
  /// API 키 마스킹 (보안을 위해 일부만 표시)
  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '********';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }
} 