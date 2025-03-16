import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/web_firebase_initializer.dart';

/// 인증 관련 데이터 액세스를 담당하는 Repository 클래스
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  /// 현재 로그인된 사용자 가져오기
  User? get currentUser => _auth.currentUser;
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    if (kIsWeb) {
      final userData = await WebFirebaseInitializer.signInWithEmailPassword(email, password);
      if (userData == null) {
        throw Exception('이메일/비밀번호 로그인 실패');
      }
      
      // 웹에서는 Firebase Auth가 자동으로 상태를 업데이트하므로 현재 사용자 반환
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인 후 사용자 정보를 가져올 수 없습니다.');
      }
      
      // UserCredential 객체를 직접 생성하는 대신 Firebase에서 제공하는 메서드 사용
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    if (kIsWeb) {
      final userData = await WebFirebaseInitializer.signUpWithEmailPassword(email, password);
      if (userData == null) {
        throw Exception('이메일/비밀번호 회원가입 실패');
      }
      
      // 웹에서는 Firebase Auth가 자동으로 상태를 업데이트하므로 현재 사용자 반환
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('회원가입 후 사용자 정보를 가져올 수 없습니다.');
      }
      
      // UserCredential 객체를 직접 생성하는 대신 Firebase에서 제공하는 메서드 사용
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }
  
  /// Google로 로그인
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final userData = await WebFirebaseInitializer.signInWithGoogle();
      if (userData == null) {
        throw Exception('Google 로그인 실패');
      }
      
      // 웹에서는 Firebase Auth가 자동으로 상태를 업데이트하므로 현재 사용자 반환
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Google 로그인 후 사용자 정보를 가져올 수 없습니다.');
      }
      
      // Google 로그인 결과를 반환
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    } else {
      // 모바일에서의 Google 로그인 로직
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await _auth.signInWithCredential(credential);
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    if (kIsWeb) {
      await WebFirebaseInitializer.signOut();
    } else {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
  
  /// 사용자 프로필 업데이트
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    
    await user.updateDisplayName(displayName);
    await user.updatePhotoURL(photoURL);
  }
}

/// 웹 환경에서 사용하기 위한 UserCredential 확장 클래스
class UserCredential_ {
  final User user;
  final AuthCredential? credential;
  
  UserCredential_(this.user, this.credential);
} 