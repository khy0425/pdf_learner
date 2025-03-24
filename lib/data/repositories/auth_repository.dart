import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 인증 관련 데이터를 처리하는 Repository
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  /// 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;
  
  /// 이메일/비밀번호로 회원가입
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('회원가입 실패: $e');
      rethrow;
    }
  }
  
  /// 이메일/비밀번호로 로그인
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('로그인 실패: 사용자 정보가 없습니다.');
      }
      
      return userCredential.user!;
    } catch (e) {
      debugPrint('로그인 실패: $e');
      rethrow;
    }
  }
  
  /// 구글 로그인
  Future<User> signInWithGoogle() async {
    try {
      // 웹과 네이티브 환경에서 구글 로그인 처리 방식이 다름
      UserCredential userCredential;
      
      if (kIsWeb) {
        // 웹 환경에서는 팝업 방식으로 로그인
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // 네이티브 환경에서는 GoogleSignIn 사용
        final googleSignInAccount = await _googleSignIn.signIn();
        if (googleSignInAccount == null) {
          throw Exception('구글 로그인 취소됨');
        }
        
        final googleSignInAuthentication = await googleSignInAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      if (userCredential.user == null) {
        throw Exception('구글 로그인 실패: 사용자 정보가 없습니다.');
      }
      
      return userCredential.user!;
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      rethrow;
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('로그아웃 실패: $e');
      rethrow;
    }
  }
  
  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('비밀번호 재설정 이메일 전송 실패: $e');
      rethrow;
    }
  }
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// 이메일 인증 메일 전송
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('이메일 인증 메일 전송 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception('로그인된 사용자가 없습니다.');
      }
    } catch (e) {
      debugPrint('계정 삭제 실패: $e');
      rethrow;
    }
  }
  
  /// 비밀번호 변경
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // 현재 비밀번호 확인을 위해 재인증
      if (user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      } else {
        throw Exception('이메일 정보가 없습니다.');
      }
    } catch (e) {
      debugPrint('비밀번호 변경 실패: $e');
      rethrow;
    }
  }
  
  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      } else {
        throw Exception('로그인된 사용자가 없습니다.');
      }
    } catch (e) {
      debugPrint('프로필 업데이트 실패: $e');
      rethrow;
    }
  }
  
  /// Facebook으로 로그인
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Facebook 로그인 과정
      final LoginResult loginResult = await FacebookAuth.instance.login();
      
      if (loginResult.status != LoginStatus.success) {
        throw Exception('Facebook 로그인 실패: ${loginResult.status}');
      }
      
      // Facebook 접근 토큰 가져오기
      final AccessToken accessToken = loginResult.accessToken!;
      
      // Firebase Auth에 Facebook 인증 정보 제공
      final OAuthCredential facebookAuthCredential = 
          FacebookAuthProvider.credential(accessToken.token);
      
      // Firebase에 로그인
      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      debugPrint('Facebook 로그인 실패: $e');
      rethrow;
    }
  }
  
  /// Apple로 로그인
  Future<UserCredential> signInWithApple() async {
    try {
      // Apple Sign In 과정 진행
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // OAuthCredential 생성
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      
      // Firebase에 로그인
      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      debugPrint('Apple 로그인 실패: $e');
      rethrow;
    }
  }
}