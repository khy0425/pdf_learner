import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:web_firebase_initializer/web_firebase_initializer.dart';
import 'package:user_model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _db;

  AuthService(this._db);

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일 회원가입
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 소셜 로그인
  Future<UserModel?> signInWithGoogle() async {
    try {
      debugPrint('Google 로그인 시작');
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signInWithGoogle();
        if (userData != null) {
          debugPrint('Google 로그인 성공: ${userData['id']}');
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          debugPrint('Google 로그인 취소됨');
          return null;
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;
        
        if (user != null) {
          debugPrint('Google 로그인 성공: ${user.uid}');
          
          final userData = {
            'id': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'emailVerified': user.emailVerified,
            'providerId': user.providerData.first.providerId,
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
          };
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      }
      
      debugPrint('Google 로그인 실패: 사용자 정보 없음');
      return null;
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      rethrow;
    }
  }

  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      debugPrint('이메일/비밀번호 로그인 시작: $email');
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signInWithEmailPassword(email, password);
        if (userData != null) {
          debugPrint('이메일/비밀번호 로그인 성공: ${userData['id']}');
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      } else {
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        final User? user = userCredential.user;
        if (user != null) {
          debugPrint('이메일/비밀번호 로그인 성공: ${user.uid}');
          
          final userData = {
            'id': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'emailVerified': user.emailVerified,
            'providerId': user.providerData.first.providerId,
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
          };
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      }
      
      debugPrint('이메일/비밀번호 로그인 실패: 사용자 정보 없음');
      return null;
    } catch (e) {
      debugPrint('이메일/비밀번호 로그인 오류: $e');
      rethrow;
    }
  }

  Future<UserModel?> signUpWithEmailPassword(String email, String password) async {
    try {
      debugPrint('이메일/비밀번호 회원가입 시작: $email');
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signUpWithEmailPassword(email, password);
        if (userData != null) {
          debugPrint('이메일/비밀번호 회원가입 성공: ${userData['id']}');
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      } else {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        final User? user = userCredential.user;
        if (user != null) {
          debugPrint('이메일/비밀번호 회원가입 성공: ${user.uid}');
          
          final userData = {
            'id': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'emailVerified': user.emailVerified,
            'providerId': user.providerData.first.providerId,
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
          };
          
          // Firestore에 사용자 정보 저장
          await WebFirebaseInitializer.saveUserData(userData);
          
          return UserModel.fromJson(userData);
        }
      }
      
      debugPrint('이메일/비밀번호 회원가입 실패: 사용자 정보 없음');
      return null;
    } catch (e) {
      debugPrint('이메일/비밀번호 회원가입 오류: $e');
      rethrow;
    }
  }

  Future<void> signOut() {
    _auth.signOut();
  }

  // 사용자 데이터 관리
  Stream<User?> get authStateChanges => Stream.fromIterable([_auth.currentUser]);
} 