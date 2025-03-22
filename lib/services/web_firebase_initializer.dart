import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/env_loader.dart';

/// 민감한 정보를 안전하게 로깅하는 함수
void secureLog(String message, {bool isSensitive = false}) {
  if (kDebugMode) {
    if (isSensitive) {
      // 민감한 정보는 마스킹 처리
      debugPrint('🔒 [보안] 민감한 정보 로깅 (마스킹됨)');
    } else {
      debugPrint('📝 $message');
    }
  }
}

/// 웹 환경에서 Firebase를 초기화하는 클래스
class WebFirebaseInitializer {
  static final WebFirebaseInitializer _instance = WebFirebaseInitializer._internal();
  
  factory WebFirebaseInitializer() => _instance;
  
  WebFirebaseInitializer._internal();
  
  final EnvLoader _envLoader = EnvLoader();
  bool _initialized = false;
  bool _isInitializing = false; // 초기화 진행 중 여부
  
  // 로그인 상태 관련 변수
  bool _isUserLoggedIn = false;
  String? _userId;
  
  /// 초기화 여부
  bool get isInitialized => _initialized;
  bool get isUserLoggedIn => _isUserLoggedIn;
  String? get userId => _userId;
  
  // 초기화 완료를 기다리는 Completer
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationComplete => _initializationCompleter.future;

  // Firebase 인스턴스
  late firebase_auth.FirebaseAuth _auth;

  /// Firebase 초기화
  Future<bool> initializeFirebase() async {
    if (_initialized) {
      return true;
    }
    
    if (_isInitializing) {
      await initializationComplete;
      return _initialized;
    }
    
    _isInitializing = true;
    
    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      _auth = firebase_auth.FirebaseAuth.instance;
      
      // 현재 로그인 상태 확인
      final currentUser = _auth.currentUser;
      _isUserLoggedIn = currentUser != null;
      _userId = currentUser?.uid;
      
      _initialized = true;
      
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      
      debugPrint('🔥 Firebase 초기화 완료: $_initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase 초기화 오류: $e');
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Firebase 옵션 설정
  FirebaseOptions _getFirebaseOptions() {
    return FirebaseOptions(
      apiKey: _envLoader.firebaseApiKey?.toString() ?? '',
      appId: _envLoader.firebaseAppId?.toString() ?? '',
      messagingSenderId: _envLoader.firebaseMessagingSenderId?.toString() ?? '',
      projectId: _envLoader.firebaseProjectId?.toString() ?? '',
      authDomain: _envLoader.firebaseAuthDomain?.toString(),
      storageBucket: _envLoader.firebaseStorageBucket?.toString(),
      measurementId: _envLoader.firebaseMeasurementId?.toString(),
    );
  }

  /// Google 로그인 (웹 전용)
  Future<UserModel?> signInWithGoogle() async {
    try {
      if (!_initialized) {
        await initializeFirebase();
      }
      
      // Google 로그인 제공자 설정
      final googleProvider = firebase_auth.GoogleAuthProvider();
      
      // 팝업으로 로그인
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final user = userCredential.user;
      
      if (user != null) {
        _isUserLoggedIn = true;
        _userId = user.uid;
        
        return _createUserModelFromCurrentUser(user);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Google 로그인 오류: $e');
      return null;
    }
  }

  /// 로그아웃
  Future<bool> signOut() async {
    try {
      if (!_initialized) {
        await initializeFirebase();
      }
      
      await _auth.signOut();
      
      _isUserLoggedIn = false;
      _userId = null;
      
      return true;
    } catch (e) {
      debugPrint('❌ 로그아웃 오류: $e');
      return false;
    }
  }

  /// Firebase User에서 UserModel 생성
  UserModel? _createUserModelFromCurrentUser(firebase_auth.User? currentUser) {
    if (currentUser == null) return null;
    
    return UserModel(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      displayName: currentUser.displayName ?? '사용자',
      photoURL: currentUser.photoURL,
      emailVerified: currentUser.emailVerified,
      phoneNumber: currentUser.phoneNumber,
      createdAt: currentUser.metadata.creationTime,
      lastSignInAt: currentUser.metadata.lastSignInTime,
    );
  }

  /// 초기화 상태를 리셋합니다.
  void resetInitialization() {
    _initialized = false;
    debugPrint('Firebase 초기화 상태가 리셋되었습니다.');
  }
} 