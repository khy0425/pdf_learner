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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API 키 관리를 담당하는 Service 클래스
class ApiKeyService {
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  ApiKeyService({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository();
  
  /// API 키 저장
  Future<void> saveApiKey(String userId, String apiKey) async {
    try {
      debugPrint('API 키 저장 시작: $userId');
      
      // 보안 스토리지에 저장
      try {
        await _secureStorage.write(key: 'api_key_$userId', value: apiKey);
        debugPrint('보안 스토리지에 API 키 저장 완료');
      } catch (e) {
        debugPrint('보안 스토리지 API 키 저장 오류: $e');
        // 보안 스토리지 실패 시 일반 SharedPreferences 사용
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('api_key_$userId', apiKey);
          debugPrint('일반 스토리지에 API 키 저장 완료');
        } catch (e2) {
          debugPrint('일반 스토리지 API 키 저장 오류: $e2');
          // 로컬 저장 실패 시 Firestore만 업데이트
        }
      }
      
      // Firestore에 저장
      try {
        await _firestore.collection('users').doc(userId).update({
          'apiKey': apiKey,
        });
        debugPrint('Firestore에 API 키 저장 완료');
      } catch (e) {
        debugPrint('Firestore API 키 저장 오류: $e');
        throw Exception('API 키를 Firestore에 저장하는 중 오류가 발생했습니다: $e');
      }
    } catch (e) {
      debugPrint('saveApiKey 메서드 오류: $e');
      throw Exception('API 키 저장 중 오류가 발생했습니다: $e');
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String userId) async {
    try {
      debugPrint('API 키 조회 시작: $userId');
      String? apiKey;
      
      // 보안 스토리지에서 조회
      try {
        apiKey = await _secureStorage.read(key: 'api_key_$userId');
        if (apiKey != null) {
          debugPrint('보안 스토리지에서 API 키 조회 완료');
          return apiKey;
        }
      } catch (e) {
        debugPrint('보안 스토리지 API 키 조회 오류: $e');
        // 보안 스토리지 실패 시 일반 SharedPreferences 사용
      }
      
      // 일반 스토리지에서 조회
      try {
        final prefs = await SharedPreferences.getInstance();
        apiKey = prefs.getString('api_key_$userId');
        if (apiKey != null) {
          debugPrint('일반 스토리지에서 API 키 조회 완료');
          
          // 보안 스토리지로 마이그레이션 시도
          try {
            await _secureStorage.write(key: 'api_key_$userId', value: apiKey);
            debugPrint('API 키를 보안 스토리지로 마이그레이션 완료');
          } catch (e) {
            debugPrint('API 키 보안 스토리지 마이그레이션 실패: $e');
            // 마이그레이션 실패는 무시
          }
          
          return apiKey;
        }
      } catch (e) {
        debugPrint('일반 스토리지 API 키 조회 오류: $e');
        // 일반 스토리지 실패 시 Firestore에서 조회
      }
      
      // Firestore에서 조회
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          apiKey = doc.data()!['apiKey'] as String?;
          if (apiKey != null) {
            debugPrint('Firestore에서 API 키 조회 완료');
            
            // 로컬 스토리지에 캐싱 시도
            try {
              await _secureStorage.write(key: 'api_key_$userId', value: apiKey);
              debugPrint('API 키를 보안 스토리지에 캐싱 완료');
            } catch (e) {
              debugPrint('API 키 보안 스토리지 캐싱 실패: $e');
              // 캐싱 실패는 무시
            }
            
            return apiKey;
          }
        }
      } catch (e) {
        debugPrint('Firestore API 키 조회 오류: $e');
        // Firestore 조회 실패 시 null 반환
      }
      
      debugPrint('API 키를 찾을 수 없음: $userId');
      return null;
    } catch (e) {
      debugPrint('getApiKey 메서드 오류: $e');
      return null;
    }
  }
  
  /// API 키 삭제
  Future<void> deleteApiKey(String userId) async {
    try {
      debugPrint('API 키 삭제 시작: $userId');
      
      // 보안 스토리지에서 삭제
      try {
        await _secureStorage.delete(key: 'api_key_$userId');
        debugPrint('보안 스토리지에서 API 키 삭제 완료');
      } catch (e) {
        debugPrint('보안 스토리지 API 키 삭제 오류: $e');
        // 보안 스토리지 실패는 무시
      }
      
      // 일반 스토리지에서 삭제
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('api_key_$userId');
        debugPrint('일반 스토리지에서 API 키 삭제 완료');
      } catch (e) {
        debugPrint('일반 스토리지 API 키 삭제 오류: $e');
        // 일반 스토리지 실패는 무시
      }
      
      // Firestore에서 삭제
      try {
        await _firestore.collection('users').doc(userId).update({
          'apiKey': FieldValue.delete(),
        });
        debugPrint('Firestore에서 API 키 삭제 완료');
      } catch (e) {
        debugPrint('Firestore API 키 삭제 오류: $e');
        throw Exception('API 키를 Firestore에서 삭제하는 중 오류가 발생했습니다: $e');
      }
    } catch (e) {
      debugPrint('deleteApiKey 메서드 오류: $e');
      throw Exception('API 키 삭제 중 오류가 발생했습니다: $e');
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