import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
import 'dart:async';
import '../services/web_firebase_initializer.dart';
import '../repositories/user_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API 키 관리를 담당하는 Service 클래스
class ApiKeyService {
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FlutterSecureStorage? _secureStorage;
  final bool _isWeb;
  
  ApiKeyService({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository(),
        _isWeb = kIsWeb {
    // 웹 환경에서는 secure storage를 초기화하지 않음
    _secureStorage = _isWeb ? null : const FlutterSecureStorage();
    debugPrint('ApiKeyService 초기화: 웹 환경 = $_isWeb');
  }
  
  /// API 키 저장
  Future<void> saveApiKey(String userId, String apiKey) async {
    try {
      debugPrint('API 키 저장 시작: $userId');
      
      // API 키 암호화
      final encryptedApiKey = _encryptApiKey(apiKey);
      debugPrint('API 키 암호화 완료');
      
      // 보안 스토리지에 저장 (웹이 아닌 경우만)
      if (!_isWeb && _secureStorage != null) {
        try {
          await _secureStorage!.write(key: 'api_key_$userId', value: encryptedApiKey);
          debugPrint('보안 스토리지에 API 키 저장 완료');
        } catch (e) {
          debugPrint('보안 스토리지 API 키 저장 오류: $e');
          // 보안 스토리지 실패 시 일반 SharedPreferences 사용
        }
      } else {
        debugPrint('웹 환경이므로 보안 스토리지 사용 안함');
      }
      
      // 일반 SharedPreferences 사용 (모든 환경)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_key_$userId', encryptedApiKey);
        debugPrint('일반 스토리지에 API 키 저장 완료');
      } catch (e2) {
        debugPrint('일반 스토리지 API 키 저장 오류: $e2');
        // 로컬 저장 실패 시 Firestore만 업데이트
      }
      
      // Firestore에 저장
      try {
        await _firestore.collection('users').doc(userId).update({
          'apiKey': encryptedApiKey,
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
      String? encryptedApiKey;
      
      // 보안 스토리지에서 조회 (웹이 아닌 경우만)
      if (!_isWeb && _secureStorage != null) {
        try {
          encryptedApiKey = await _secureStorage!.read(key: 'api_key_$userId');
          if (encryptedApiKey != null) {
            debugPrint('보안 스토리지에서 API 키 조회 완료');
            return _decryptApiKey(encryptedApiKey);
          }
        } catch (e) {
          debugPrint('보안 스토리지 API 키 조회 오류: $e');
          // 보안 스토리지 실패 시 일반 SharedPreferences 사용
        }
      } else {
        debugPrint('웹 환경이므로 보안 스토리지 사용 안함');
      }
      
      // 일반 스토리지에서 조회
      try {
        final prefs = await SharedPreferences.getInstance();
        encryptedApiKey = prefs.getString('api_key_$userId');
        if (encryptedApiKey != null) {
          debugPrint('일반 스토리지에서 API 키 조회 완료');
          
          // 보안 스토리지로 마이그레이션 시도 (웹이 아닌 경우만)
          if (!_isWeb && _secureStorage != null) {
            try {
              await _secureStorage!.write(key: 'api_key_$userId', value: encryptedApiKey);
              debugPrint('API 키를 보안 스토리지로 마이그레이션 완료');
            } catch (e) {
              debugPrint('API 키 보안 스토리지 마이그레이션 실패: $e');
              // 마이그레이션 실패는 무시
            }
          }
          
          return _decryptApiKey(encryptedApiKey);
        }
      } catch (e) {
        debugPrint('일반 스토리지 API 키 조회 오류: $e');
        // 일반 스토리지 실패 시 Firestore에서 조회
      }
      
      // Firestore에서 조회
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          encryptedApiKey = doc.data()!['apiKey'] as String?;
          if (encryptedApiKey != null) {
            debugPrint('Firestore에서 API 키 조회 완료');
            
            // 로컬 스토리지에 캐싱 시도
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('api_key_$userId', encryptedApiKey);
              debugPrint('API 키를 일반 스토리지에 캐싱 완료');
              
              // 보안 스토리지에도 캐싱 시도 (웹이 아닌 경우만)
              if (!_isWeb && _secureStorage != null) {
                try {
                  await _secureStorage!.write(key: 'api_key_$userId', value: encryptedApiKey);
                  debugPrint('API 키를 보안 스토리지에 캐싱 완료');
                } catch (e) {
                  debugPrint('API 키 보안 스토리지 캐싱 실패: $e');
                  // 캐싱 실패는 무시
                }
              }
            } catch (e) {
              debugPrint('API 키 일반 스토리지 캐싱 실패: $e');
              // 캐싱 실패는 무시
            }
            
            return _decryptApiKey(encryptedApiKey);
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
      
      // 보안 스토리지에서 삭제 (웹이 아닌 경우만)
      if (!_isWeb && _secureStorage != null) {
        try {
          await _secureStorage!.delete(key: 'api_key_$userId');
          debugPrint('보안 스토리지에서 API 키 삭제 완료');
        } catch (e) {
          debugPrint('보안 스토리지 API 키 삭제 오류: $e');
          // 보안 스토리지 실패는 무시
        }
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
    // Gemini API 키 형식 검사 (일반적으로 'AI'로 시작하는 형식)
    return apiKey.startsWith('AI') && apiKey.length >= 40;
  }
  
  /// API 키 마스킹 (보안을 위해 일부만 표시)
  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '********';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }
  
  /// API 키 암호화 (간단한 구현)
  String _encryptApiKey(String apiKey) {
    // 실제 앱에서는 더 강력한 암호화 방식 사용 필요
    // 간단한 Base64 인코딩 + 솔트 추가 예시
    final bytes = utf8.encode('salt_prefix_$apiKey');
    return base64Encode(bytes);
  }
  
  /// API 키 복호화
  String _decryptApiKey(String encryptedApiKey) {
    try {
      // 복호화 로직 (암호화와 대응되어야 함)
      final decoded = utf8.decode(base64Decode(encryptedApiKey));
      // 솔트 제거
      if (decoded.startsWith('salt_prefix_')) {
        return decoded.substring(12); // 'salt_prefix_' 길이만큼 제거
      }
      return decoded; // 기존 암호화되지 않은 데이터 처리
    } catch (e) {
      debugPrint('API 키 복호화 오류: $e');
      return encryptedApiKey; // 오류 발생 시 원본 반환
    }
  }
} 