import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/web_firebase_initializer.dart';

class FirebaseAuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  FirebaseAuthService() {
    if (kIsWeb) {
      // 웹 환경에서는 JavaScript를 통해 현재 사용자 정보 가져오기
      _initWebAuth();
    } else {
      // 네이티브 환경에서는 Firebase SDK를 통해 인증 상태 변경 감지
      _auth.authStateChanges().listen(_onAuthStateChanged);
    }
  }

  Future<void> _initWebAuth() async {
    try {
      final userData = await WebFirebaseInitializer.getCurrentUser();
      if (userData != null) {
        await _onWebAuthStateChanged(userData);
      }
    } catch (e) {
      print('웹 인증 초기화 오류: $e');
    }
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Firestore에서 사용자 데이터 가져오기
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _currentUser = User.fromMap(doc.data()!);
    } else {
      // 신규 사용자인 경우 기본 데이터 생성
      _currentUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? '사용자',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(
            _currentUser!.toMap(),
          );
    }
    notifyListeners();
  }

  Future<void> _onWebAuthStateChanged(Map<String, dynamic> userData) async {
    // Firestore에서 사용자 데이터 가져오기
    final doc = await _firestore.collection('users').doc(userData['uid']).get();
    if (doc.exists) {
      _currentUser = User.fromMap(doc.data()!);
    } else {
      // 신규 사용자인 경우 기본 데이터 생성
      _currentUser = User(
        id: userData['uid'],
        email: userData['email'],
        name: userData['displayName'] ?? '사용자',
        createdAt: userData['createdAt'] != null 
            ? DateTime.parse(userData['createdAt']) 
            : DateTime.now(),
      );
      await _firestore.collection('users').doc(userData['uid']).set(
            _currentUser!.toMap(),
          );
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 JavaScript를 통해 회원가입
        debugPrint('웹 환경에서 회원가입 시도: $email');
        final userData = await WebFirebaseInitializer.signUpWithEmailPassword(email, password);
        debugPrint('웹 회원가입 성공, 사용자 데이터 저장 중');
        
        // 사용자 이름 업데이트는 Firestore에서 처리
        await _firestore.collection('users').doc(userData['uid']).set({
          'id': userData['uid'],
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
        });
        debugPrint('사용자 데이터 저장 완료');
        await _onWebAuthStateChanged(userData);
      } else {
        // 네이티브 환경에서는 Firebase SDK를 통해 회원가입
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.updateDisplayName(name);
        // Firestore에 사용자 데이터 저장은 _onAuthStateChanged에서 처리됨
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 JavaScript를 통해 로그인
        final userData = await WebFirebaseInitializer.signInWithEmailPassword(email, password);
        await _onWebAuthStateChanged(userData);
      } else {
        // 네이티브 환경에서는 Firebase SDK를 통해 로그인
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 JavaScript를 통해 Google 로그인
        debugPrint('웹 환경에서 Google 로그인 시도');
        final userData = await WebFirebaseInitializer.signInWithGoogle();
        debugPrint('Google 로그인 성공, 사용자 데이터 처리 중');
        
        try {
          // Firestore에 사용자 데이터가 없으면 저장
          final doc = await _firestore.collection('users').doc(userData['uid']).get();
          debugPrint('사용자 문서 조회 성공: ${doc.exists ? '문서 존재' : '문서 없음'}');
          
          if (!doc.exists) {
            debugPrint('새 사용자 문서 생성 시도');
            await _firestore.collection('users').doc(userData['uid']).set({
              'id': userData['uid'],
              'email': userData['email'],
              'name': userData['displayName'] ?? '사용자',
              'photoURL': userData['photoURL'],
              'createdAt': DateTime.now().toIso8601String(),
              'subscription': 'free',
              'provider': 'google',
            });
            debugPrint('Google 사용자 데이터 저장 완료');
          }
        } catch (firestoreError) {
          debugPrint('Firestore 오류 상세: $firestoreError');
          // Firestore 오류가 발생해도 로그인은 계속 진행
          // 사용자 데이터는 나중에 다시 시도할 수 있음
        }
        
        // 로그인 성공으로 처리
        _currentUser = User(
          id: userData['uid'],
          email: userData['email'],
          name: userData['displayName'] ?? '사용자',
          createdAt: DateTime.now(),
          photoUrl: userData['photoURL'],
          subscription: SubscriptionTier.free,
        );
        notifyListeners();
        return;
      } else {
        // 네이티브 환경에서는 Firebase SDK를 통해 Google 로그인
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        
        // Firestore에 사용자 데이터 저장은 _onAuthStateChanged에서 처리됨
      }
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      // 웹 환경에서는 JavaScript를 통해 로그아웃
      await WebFirebaseInitializer.signOut();
      _currentUser = null;
      notifyListeners();
    } else {
      // 네이티브 환경에서는 Firebase SDK를 통해 로그아웃
      await _auth.signOut();
    }
  }

  Exception _handleFirebaseAuthError(dynamic e) {
    debugPrint('Firebase 인증 오류 처리: $e');
    
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
    
    // 웹 환경에서 발생하는 오류 처리
    if (e is Map) {
      debugPrint('웹 인증 오류 맵: $e');
      final code = e['code'] as String? ?? '';
      final message = e['message'] as String? ?? '알 수 없는 오류';
      
      switch (code) {
        case 'auth/email-already-in-use':
          return Exception('이미 사용 중인 이메일입니다');
        case 'auth/invalid-email':
          return Exception('잘못된 이메일 형식입니다');
        case 'auth/weak-password':
          return Exception('비밀번호가 너무 약합니다');
        case 'auth/user-not-found':
          return Exception('등록되지 않은 이메일입니다');
        case 'auth/wrong-password':
          return Exception('잘못된 비밀번호입니다');
        case 'auth/operation-not-allowed':
          return Exception('이 인증 방식이 비활성화되어 있습니다. Firebase 콘솔에서 이메일/비밀번호 인증을 활성화해주세요.');
        case 'auth/account-exists-with-different-credential':
          return Exception('이미 다른 방식으로 가입된 이메일입니다');
        case 'auth/popup-closed-by-user':
          return Exception('로그인 창이 닫혔습니다');
        case 'auth/cancelled-popup-request':
          return Exception('이전 로그인 요청이 진행 중입니다');
        case 'auth/popup-blocked':
          return Exception('팝업이 차단되었습니다. 팝업 차단을 해제해주세요.');
        case 'firebase-not-initialized':
          return Exception('Firebase가 초기화되지 않았습니다');
        case 'firebase-auth-unavailable':
          return Exception('Firebase 인증 서비스를 사용할 수 없습니다');
        default:
          return Exception('인증 오류: $message');
      }
    }
    
    return Exception('알 수 없는 오류가 발생했습니다: $e');
  }
} 