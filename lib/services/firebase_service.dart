import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Firebase 서비스를 초기화하고 관리하는 클래스
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static bool _isInitialized = false;

  /// 싱글톤 인스턴스
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  /// Firebase 초기화 
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase가 이미 초기화되어 있습니다.');
      return;
    }

    try {
      debugPrint('Firebase 초기화 시작...');
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('Firebase 초기화 완료: ${app.name}');
    } catch (e) {
      debugPrint('Firebase 초기화 실패: $e');
      rethrow;
    }
  }
} 