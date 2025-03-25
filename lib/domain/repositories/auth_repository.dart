import 'package:firebase_auth/firebase_auth.dart';

/// 인증 관련 기능을 위한 리포지토리 인터페이스
abstract class AuthRepository {
  /// 사용자 인증 상태 변화 추적
  Stream<User?> authStateChanges();
  
  /// 현재 인증된 사용자 정보 가져오기
  User? getCurrentUser();
  
  /// 이메일, 비밀번호로 로그인
  Future<UserCredential> signIn(String email, String password);
  
  /// 이메일, 비밀번호로 회원가입
  Future<UserCredential> signUp(String email, String password);
  
  /// 익명으로 로그인
  Future<UserCredential> signInAnonymously();
  
  /// Google 계정으로 로그인
  Future<UserCredential> signInWithGoogle();
  
  /// 로그아웃
  Future<void> signOut();
  
  /// 비밀번호 재설정 이메일 전송
  Future<void> resetPassword(String email);
  
  /// 사용자 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  });
}