import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/web_firebase_initializer.dart';

/// 인증 관련 데이터 액세스를 담당하는 Repository 클래스
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  
  // 생성자에서 GoogleSignIn 초기화
  AuthRepository() {
    if (kIsWeb) {
      // 웹 환경에서는 클라이언트 ID를 명시적으로 사용하지 않음 
      // (HTML의 meta 태그에서 자동으로 가져옴)
      _googleSignIn = GoogleSignIn();
      debugPrint('웹 환경에서 GoogleSignIn 초기화 완료');
    } else {
      // 모바일 환경에서는 일반적인 방법으로 초기화
      _googleSignIn = GoogleSignIn();
      debugPrint('모바일 환경에서 GoogleSignIn 초기화 완료');
    }
  }
  
  /// 현재 로그인된 사용자 가져오기
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint('AuthRepository.currentUser 접근 오류: $e');
      return null;
    }
  }
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('AuthRepository.authStateChanges 접근 오류: $e');
      // 오류 발생 시 빈 사용자로 스트림 생성
      return Stream<User?>.value(null);
    }
  }
  
  /// 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      if (kIsWeb) {
        debugPrint('웹 환경에서 이메일/비밀번호 로그인 시도: $email');
        
        // 웹 환경에서는 Firebase Auth 직접 사용
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        debugPrint('웹 환경에서 이메일/비밀번호 로그인 성공: ${userCredential.user?.uid}');
        
        // 로그인 성공 후 WebFirebaseInitializer 상태 업데이트
        if (userCredential.user != null) {
          try {
            await WebFirebaseInitializer().initialize();
            debugPrint('WebFirebaseInitializer 초기화 완료');
          } catch (e) {
            debugPrint('WebFirebaseInitializer 초기화 오류: $e');
          }
        }
        
        return userCredential;
      } else {
        // 모바일 환경에서는 Firebase Auth 직접 사용
        debugPrint('모바일 환경에서 이메일/비밀번호 로그인 시도: $email');
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      debugPrint('로그인 오류: $e');
      rethrow; // 오류를 상위 레이어로 전파
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      if (kIsWeb) {
        debugPrint('웹 환경에서 이메일/비밀번호 회원가입 시도: $email');
        
        // 웹 환경에서는 Firebase Auth 직접 사용
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        debugPrint('웹 환경에서 이메일/비밀번호 회원가입 성공: ${userCredential.user?.uid}');
        
        // 회원가입 성공 후 WebFirebaseInitializer 상태 업데이트
        if (userCredential.user != null) {
          try {
            await WebFirebaseInitializer().initialize();
            debugPrint('WebFirebaseInitializer 초기화 완료');
          } catch (e) {
            debugPrint('WebFirebaseInitializer 초기화 오류: $e');
          }
        }
        
        return userCredential;
      } else {
        // 모바일 환경에서는 Firebase Auth 직접 사용
        debugPrint('모바일 환경에서 이메일/비밀번호 회원가입 시도: $email');
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      rethrow; // 오류를 상위 레이어로 전파
    }
  }
  
  /// Google로 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        debugPrint('웹 환경에서 Google 로그인 시도');
        
        // 웹 환경에서는 Firebase Auth의 팝업 방식 사용
        final googleProvider = GoogleAuthProvider();
        // 사용자 프로필, 이메일 권한 요청
        googleProvider.addScope('profile');
        googleProvider.addScope('email');
        
        final userCredential = await _auth.signInWithPopup(googleProvider);
        
        debugPrint('웹 환경에서 Google 로그인 성공: ${userCredential.user?.uid}');
        
        // 로그인 성공 후 WebFirebaseInitializer 상태 업데이트
        if (userCredential.user != null) {
          try {
            await WebFirebaseInitializer().initialize();
            debugPrint('WebFirebaseInitializer 초기화 완료');
          } catch (e) {
            debugPrint('WebFirebaseInitializer 초기화 오류: $e');
          }
        }
        
        return userCredential;
      } else {
        // 모바일 환경에서는 GoogleSignIn 사용
        debugPrint('모바일 환경에서 Google 로그인 시도');
        
        // Google 로그인 다이얼로그 표시
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'cancelled-popup-request',
            message: 'Google 로그인이 취소되었습니다.',
          );
        }
        
        // Google 인증 정보 가져오기
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // Firebase 인증 정보 생성
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // Firebase에 로그인
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      rethrow; // 오류를 상위 레이어로 전파
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await WebFirebaseInitializer.signOut();
      } else {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      // 오류가 발생해도 로그아웃 시도
      await _auth.signOut();
    }
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