import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/web_firebase_initializer.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class FirebaseAuthService with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // 싱글톤 패턴 구현
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal() {
    try {
      _initializeAuth();
    } catch (e) {
      debugPrint('FirebaseAuthService 생성자 오류: $e');
    }
  }
  
  UserModel? get currentUser {
    try {
      return _currentUser;
    } catch (e) {
      return null;
    }
  }
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  Future<void> _initializeAuth() async {
    try {
      // 웹 환경에서 인증 상태 유지 설정
      if (kIsWeb) {
        try {
          // LOCAL: 브라우저를 닫아도 로그인 상태 유지
          await _auth.setPersistence(firebase_auth.Persistence.LOCAL);
        } catch (e) {
          // 오류 무시
        }
      }
      
      // 인증 상태 변경 리스너 설정
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // 현재 사용자 확인
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _loadUserFromFirestore(currentUser.uid);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
    }
  }

  // Firestore에서 사용자 정보 로드
  Future<void> _loadUserFromFirestore(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Firestore에서 사용자 정보 가져오기
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // UserModel 생성
        _currentUser = _createUserModelFromMap(userData, userId);
      } else {
        // 기본 사용자 정보 생성
        _currentUser = _createDefaultUserModel(userId);
        
        // Firestore에 기본 사용자 정보 저장
        await _saveDefaultUserToFirestore(userId);
      }
    } catch (e) {
      // 오류 발생 시 기본 사용자 모델 생성
      _currentUser = _createDefaultUserModel(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 사용자 정보 맵에서 UserModel 생성
  UserModel _createUserModelFromMap(Map<String, dynamic> userData, String userId) {
    try {
      return UserModel(
        id: userId,
        email: userData['email']?.toString() ?? '',
        displayName: userData['name']?.toString() ?? userData['displayName']?.toString() ?? '사용자',
        photoUrl: userData['photoURL']?.toString() ?? userData['photoUrl']?.toString() ?? '',
        createdAt: userData['createdAt'] != null 
            ? DateTime.tryParse(userData['createdAt'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        lastLoginAt: DateTime.now(),
        subscriptionTier: SubscriptionTier.free,
        subscriptionExpiresAt: null,
        apiKey: null,
        apiKeyExpiresAt: null,
        usageCount: 0,
        lastUsageAt: null,
        maxUsagePerDay: 10,
        maxPdfSize: 5 * 1024 * 1024,
        maxTextLength: 10000,
        maxPdfsPerDay: 5,
        maxPdfsTotal: 20,
        maxPdfPages: 50,
        maxPdfTextLength: 50000,
        maxPdfTextLengthPerPage: 1000,
        maxPdfTextLengthPerDay: 100000,
        maxPdfTextLengthPerMonth: 1000000,
        maxPdfTextLengthPerYear: 10000000,
        maxPdfTextLengthPerLifetime: 100000000,
        maxPdfTextLengthPerPdf: 10000,
        maxPdfTextLengthPerPdfPerPage: 1000,
        maxPdfTextLengthPerPdfPerDay: 100000,
        maxPdfTextLengthPerPdfPerMonth: 1000000,
        maxPdfTextLengthPerPdfPerYear: 10000000,
        maxPdfTextLengthPerPdfPerLifetime: 100000000,
        maxPdfTextLengthPerPdfPerPagePerDay: 10000,
        maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
        maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
        maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
      );
    } catch (e) {
      return _createDefaultUserModel(userId);
    }
  }
  
  // 기본 UserModel 생성
  UserModel _createDefaultUserModel(String userId) {
    return UserModel(
      id: userId,
      email: '',
      displayName: '사용자',
      photoUrl: '',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      subscriptionTier: SubscriptionTier.free,
      subscriptionExpiresAt: null,
      apiKey: null,
      apiKeyExpiresAt: null,
      usageCount: 0,
      lastUsageAt: null,
      maxUsagePerDay: 10,
      maxPdfSize: 5 * 1024 * 1024,
      maxTextLength: 10000,
      maxPdfsPerDay: 5,
      maxPdfsTotal: 20,
      maxPdfPages: 50,
      maxPdfTextLength: 50000,
      maxPdfTextLengthPerPage: 1000,
      maxPdfTextLengthPerDay: 100000,
      maxPdfTextLengthPerMonth: 1000000,
      maxPdfTextLengthPerYear: 10000000,
      maxPdfTextLengthPerLifetime: 100000000,
      maxPdfTextLengthPerPdf: 10000,
      maxPdfTextLengthPerPdfPerPage: 1000,
      maxPdfTextLengthPerPdfPerDay: 100000,
      maxPdfTextLengthPerPdfPerMonth: 1000000,
      maxPdfTextLengthPerPdfPerYear: 10000000,
      maxPdfTextLengthPerPdfPerLifetime: 100000000,
      maxPdfTextLengthPerPdfPerPagePerDay: 10000,
      maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
      maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
      maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
      maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
      maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
    );
  }
  
  // Firestore에 기본 사용자 정보 저장
  Future<void> _saveDefaultUserToFirestore(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'email': '',
        'name': '사용자',
        'photoURL': '',
        'createdAt': DateTime.now().toIso8601String(),
        'subscription': 'free',
        'provider': 'unknown',
      });
    } catch (e) {
      // 오류 무시
    }
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        await _loadUserFromFirestore(firebaseUser.uid);
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user?.updateDisplayName(name);
        
        // Firestore에 사용자 데이터 저장
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'email': email,
          'name': name,
          'photoURL': '',
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
          'provider': 'email',
        });
        
        await _loadUserFromFirestore(userCredential.user!.uid);
      }
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kIsWeb) {
        // 웹 환경에서는 팝업으로 Google 로그인
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        
        if (userCredential.user != null) {
          // Firestore에 사용자 데이터가 없으면 저장
          final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
          
          if (!doc.exists) {
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'id': userCredential.user!.uid,
              'email': userCredential.user!.email ?? '',
              'name': userCredential.user!.displayName ?? '사용자',
              'photoURL': userCredential.user!.photoURL ?? '',
              'createdAt': DateTime.now().toIso8601String(),
              'subscription': 'free',
              'provider': 'google',
            });
          }
          
          await _loadUserFromFirestore(userCredential.user!.uid);
        }
      } else {
        // 네이티브 환경에서는 GoogleSignIn 사용 (기존 코드 유지)
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final credential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          final userCredential = await _auth.signInWithCredential(credential);
          
          if (userCredential.user != null) {
            // Firestore에 사용자 데이터가 없으면 저장
            final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
            
            if (!doc.exists) {
              await _firestore.collection('users').doc(userCredential.user!.uid).set({
                'id': userCredential.user!.uid,
                'email': userCredential.user!.email ?? '',
                'name': userCredential.user!.displayName ?? '사용자',
                'photoURL': userCredential.user!.photoURL ?? '',
                'createdAt': DateTime.now().toIso8601String(),
                'subscription': 'free',
                'provider': 'google',
              });
            }
            
            await _loadUserFromFirestore(userCredential.user!.uid);
          }
        }
      }
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Exception _handleFirebaseAuthError(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception('이미 사용 중인 이메일입니다');
        case 'invalid-email':
          return Exception('잘못된 이메일 형식입니다');
        case 'weak-password':
          return Exception('비밀번호가 너무 약합니다');
        case 'user-not-found':
          return Exception('등록되지 않은 이메일입니다');
        case 'wrong-password':
          return Exception('잘못된 비밀번호입니다');
        case 'operation-not-allowed':
          return Exception('이 인증 방식이 비활성화되어 있습니다');
        case 'account-exists-with-different-credential':
          return Exception('이미 다른 방식으로 가입된 이메일입니다');
        case 'popup-closed-by-user':
          return Exception('로그인 창이 닫혔습니다');
        default:
          return Exception('인증 오류: ${e.message}');
      }
    }
    
    return Exception('알 수 없는 오류가 발생했습니다');
  }
} 