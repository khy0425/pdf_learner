import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// 사용자 데이터 관련 데이터 액세스를 담당하는 Repository 클래스
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';
  
  /// 사용자 정보 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data);
    } catch (e) {
      debugPrint('사용자 정보 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 사용자 정보 저장
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('사용자 정보 저장 오류: $e');
      throw Exception('사용자 정보를 저장할 수 없습니다.');
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