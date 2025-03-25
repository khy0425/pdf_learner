import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_learner_v2/domain/models/user_model.dart';

/// 인증 저장소 인터페이스
abstract class AuthRepository {
  /// 사용자 인증 상태 스트림
  Stream<UserModel?> get authStateChanges;

  /// 이메일/비밀번호 인증
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();

  /// 사용자 정보 관리
  Future<UserModel?> getCurrentUser();
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser();

  /// 비밀번호 관리
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);

  /// 소셜 로그인
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithApple();
  Future<UserModel?> signInWithFacebook();

  /// 이메일 인증
  Future<void> sendEmailVerification();
  Future<void> verifyEmail();
  Future<bool> isEmailVerified();
  Future<void> changeEmail(String newEmail);

  /// 프로필 관리
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  });

  /// 계정 삭제
  Future<void> deleteAccount();

  /// 전화번호 인증
  Future<void> verifyPhoneNumber(String phoneNumber);
  Future<void> verifyPhoneCode(String verificationId, String code);
} 