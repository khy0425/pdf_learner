import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 사용자 데이터 관련 데이터 액세스를 담당하는 Repository 클래스
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';
  
  /// 사용자 정보 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('사용자 정보 조회 시작: $uid');
      
      // UID 유효성 검사
      if (uid.isEmpty) {
        debugPrint('getUser: 빈 uid가 전달됨');
        return null;
      }
      
      // 로컬 스토리지에서 먼저 확인
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_$uid');
      
      if (userJson != null) {
        try {
          debugPrint('로컬 스토리지에서 사용자 정보 발견');
          final userMap = json.decode(userJson) as Map<String, dynamic>?;
          if (userMap != null) {
            return UserModel.fromJson(userMap);
          } else {
            debugPrint('로컬 스토리지의 JSON 데이터가 null입니다');
            await prefs.remove('user_$uid');
          }
        } catch (e) {
          debugPrint('로컬 스토리지의 사용자 정보 파싱 오류: $e');
          // 로컬 데이터가 손상된 경우 삭제
          await prefs.remove('user_$uid');
        }
      } else {
        debugPrint('사용자 정보가 로컬 스토리지에 없습니다.');
      }
      
      // Firestore에서 조회
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        
        if (doc.exists && doc.data() != null) {
          debugPrint('Firestore에서 사용자 정보 발견');
          final userData = UserModel.fromFirestore(doc);
          
          // 로컬 스토리지에 캐싱
          try {
            await prefs.setString('user_$uid', json.encode(userData.toJson()));
            debugPrint('사용자 정보를 로컬 스토리지에 캐싱 완료');
          } catch (e) {
            debugPrint('사용자 정보 로컬 캐싱 실패: $e');
            // 캐싱 실패는 무시하고 계속 진행
          }
          
          return userData;
        } else {
          debugPrint('Firestore에 사용자 정보가 없습니다: $uid');
          return null;
        }
      } catch (e) {
        debugPrint('Firestore 사용자 정보 조회 오류: $e');
        throw Exception('사용자 정보를 가져오는 중 오류가 발생했습니다: $e');
      }
    } catch (e) {
      debugPrint('getUser 메서드 오류: $e');
      // 모든 오류 상황에서 null 반환
      return null;
    }
  }
  
  /// 사용자 정보 저장
  Future<void> saveUser(UserModel user) async {
    try {
      debugPrint('사용자 정보 저장 시작: ${user.uid}');
      
      // Firestore에 저장
      try {
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        debugPrint('Firestore에 사용자 정보 저장 완료');
      } catch (e) {
        debugPrint('Firestore 사용자 정보 저장 오류: $e');
        throw Exception('사용자 정보를 Firestore에 저장하는 중 오류가 발생했습니다: $e');
      }
      
      // 로컬 스토리지에 캐싱
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_${user.uid}', json.encode(user.toJson()));
        debugPrint('로컬 스토리지에 사용자 정보 캐싱 완료');
      } catch (e) {
        debugPrint('로컬 스토리지 사용자 정보 캐싱 오류: $e');
        // 로컬 캐싱 실패는 무시하고 계속 진행
      }
    } catch (e) {
      debugPrint('saveUser 메서드 오류: $e');
      throw Exception('사용자 정보 저장 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 사용자 정보 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(uid).update(data);
    } catch (e) {
      debugPrint('사용자 정보 업데이트 오류: $e');
      throw Exception('사용자 정보를 업데이트할 수 없습니다.');
    }
  }
  
  /// API 키 저장
  Future<void> saveApiKey(String uid, String apiKey) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'apiKey': apiKey,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('API 키 저장 오류: $e');
      throw Exception('API 키를 저장할 수 없습니다.');
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return data['apiKey'] as String?;
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 사용자 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      debugPrint('사용자 삭제 오류: $e');
      throw Exception('사용자를 삭제할 수 없습니다.');
    }
  }
  
  /// 사용량 업데이트
  Future<void> updateUsage(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'usageCount': FieldValue.increment(1),
        'lastUsageAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('사용량 업데이트 오류: $e');
      // 사용량 업데이트는 중요하지 않으므로 예외를 던지지 않음
    }
  }
} 