import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 사용자 데이터 관리를 위한 Repository
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'users';
  
  /// 사용자 프로필 생성
  Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      // Firestore에 사용자 정보 저장
      await _firestore.collection(_collection).doc(userId).set({
        ...userData,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // 로컬 스토리지에도 캐싱
      await _cacheUserData(userId, userData);
    } catch (e) {
      debugPrint('사용자 프로필 생성 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 프로필 가져오기
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      // 오프라인 지원을 위해 로컬 캐시 먼저 확인
      final cachedData = await _getCachedUserData(userId);
      if (cachedData != null) {
        return cachedData;
      }
      
      // 네트워크에서 데이터 가져오기
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        throw Exception('사용자 프로필을 찾을 수 없습니다.');
      }
      
      final userData = doc.data()!;
      
      // 로컬 스토리지에 캐싱
      await _cacheUserData(userId, userData);
      
      return userData;
    } catch (e) {
      debugPrint('사용자 프로필 가져오기 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      // Firestore에서 사용자 정보 업데이트
      await _firestore.collection(_collection).doc(userId).update({
        ...userData,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // 로컬 캐시도 업데이트
      final cachedData = await _getCachedUserData(userId);
      if (cachedData != null) {
        await _cacheUserData(userId, {
          ...cachedData,
          ...userData,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('사용자 프로필 업데이트 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 프로필 삭제
  Future<void> deleteUserProfile(String userId) async {
    try {
      // Firestore에서 사용자 정보 삭제
      await _firestore.collection(_collection).doc(userId).delete();
      
      // 로컬 캐시도 삭제
      await _clearCachedUserData(userId);
    } catch (e) {
      debugPrint('사용자 프로필 삭제 실패: $e');
      rethrow;
    }
  }
  
  /// 현재 로그인된 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    
    try {
      return await getUserProfile(user.uid);
    } catch (e) {
      debugPrint('현재 사용자 프로필 가져오기 실패: $e');
      return null;
    }
  }
  
  /// 사용자 설정 저장
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await updateUserProfile(userId, {'settings': settings});
    } catch (e) {
      debugPrint('사용자 설정 저장 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 설정 가져오기
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final userData = await getUserProfile(userId);
      return userData['settings'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('사용자 설정 가져오기 실패: $e');
      return {};
    }
  }
  
  /// 로컬 스토리지에 사용자 데이터 캐싱
  Future<void> _cacheUserData(String userId, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData);
      await prefs.setString('user_$userId', userDataJson);
    } catch (e) {
      debugPrint('사용자 데이터 캐싱 실패: $e');
    }
  }
  
  /// 로컬 스토리지에서 캐시된 사용자 데이터 가져오기
  Future<Map<String, dynamic>?> _getCachedUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_$userId');
      if (userDataJson == null) {
        return null;
      }
      
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('캐시된 사용자 데이터 가져오기 실패: $e');
      return null;
    }
  }
  
  /// 로컬 스토리지에서 캐시된 사용자 데이터 삭제
  Future<void> _clearCachedUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_$userId');
    } catch (e) {
      debugPrint('캐시된 사용자 데이터 삭제 실패: $e');
    }
  }
  
  /// 특정 ID의 사용자 정보 가져오기 
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      // 오프라인 지원을 위해 로컬 캐시 먼저 확인
      final cachedData = await _getCachedUserData(userId);
      if (cachedData != null) {
        return cachedData;
      }
      
      // 네트워크에서 데이터 가져오기
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        return null; // 사용자가 존재하지 않음
      }
      
      final userData = doc.data()!;
      
      // 로컬 스토리지에 캐싱
      await _cacheUserData(userId, userData);
      
      return userData;
    } catch (e) {
      debugPrint('사용자 정보 가져오기 실패 (ID: $userId): $e');
      return null;
    }
  }
  
  /// UserModel 객체로 사용자 생성
  Future<void> createUser(dynamic user) async {
    try {
      // user 객체를 Map으로 변환
      final Map<String, dynamic> userData;
      if (user is Map<String, dynamic>) {
        userData = user;
      } else {
        userData = user.toJson(); // UserModel이 toJson 메서드를 가지고 있다고 가정
      }
      
      final userId = userData['uid'] as String? ?? userData['id'] as String;
      if (userId.isEmpty) {
        throw Exception('유효하지 않은 사용자 ID');
      }
      
      // Firestore에 사용자 정보 저장
      await _firestore.collection(_collection).doc(userId).set({
        ...userData,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // 로컬 스토리지에도 캐싱
      await _cacheUserData(userId, userData);
    } catch (e) {
      debugPrint('사용자 생성 실패: $e');
      rethrow;
    }
  }
  
  /// UserModel 객체로 사용자 정보 업데이트
  Future<void> updateUser(dynamic user) async {
    try {
      // user 객체를 Map으로 변환
      final Map<String, dynamic> userData;
      if (user is Map<String, dynamic>) {
        userData = user;
      } else {
        userData = user.toJson(); // UserModel이 toJson 메서드를 가지고 있다고 가정
      }
      
      final userId = userData['uid'] as String? ?? userData['id'] as String;
      if (userId.isEmpty) {
        throw Exception('유효하지 않은 사용자 ID');
      }
      
      // 업데이트 타임스탬프 추가
      userData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      
      // Firestore에서 사용자 정보 업데이트
      await _firestore.collection(_collection).doc(userId).update(userData);
      
      // 로컬 캐시도 업데이트
      final cachedData = await _getCachedUserData(userId);
      if (cachedData != null) {
        await _cacheUserData(userId, {
          ...cachedData,
          ...userData,
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 업데이트 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 삭제
  Future<void> deleteUser(String userId) async {
    try {
      // Firestore에서 사용자 정보 삭제
      await _firestore.collection(_collection).doc(userId).delete();
      
      // 로컬 캐시도 삭제
      await _clearCachedUserData(userId);
    } catch (e) {
      debugPrint('사용자 삭제 실패: $e');
      rethrow;
    }
  }
}