import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 사용자 데이터 저장
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('사용자 데이터 저장 오류: $e');
      rethrow;
    }
  }

  // 사용자 데이터 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('사용자 데이터 가져오기 오류: $e');
      return null;
    }
  }

  // 사용자 데이터 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('사용자 데이터 업데이트 오류: $e');
      rethrow;
    }
  }

  // API 키 저장
  Future<void> saveApiKey(String uid, String apiKey) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'apiKey': apiKey,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('API 키 저장 오류: $e');
      rethrow;
    }
  }

  // API 키 가져오기
  Future<String?> getApiKey(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['apiKey'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }

  // 사용자 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('사용자 삭제 오류: $e');
      rethrow;
    }
  }

  // 사용량 업데이트
  Future<void> updateUsage(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'usageCount': FieldValue.increment(1),
        'lastUsageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('사용량 업데이트 오류: $e');
      rethrow;
    }
  }
} 