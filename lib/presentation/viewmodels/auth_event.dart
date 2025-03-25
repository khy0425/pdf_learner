import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

/// 인증 이벤트
@freezed
class AuthEvent with _$AuthEvent {
  /// 앱 시작 이벤트
  const factory AuthEvent.appStarted() = _AppStarted;

  /// 로그인 이벤트
  const factory AuthEvent.loggedIn() = _LoggedIn;

  /// 로그아웃 이벤트
  const factory AuthEvent.loggedOut() = _LoggedOut;

  /// 이메일/비밀번호로 로그인
  const factory AuthEvent.signInWithEmailAndPassword({
    required String email,
    required String password,
  }) = _SignInWithEmailAndPassword;

  /// 이메일/비밀번호로 회원가입
  const factory AuthEvent.signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) = _SignUpWithEmailAndPassword;

  /// 구글로 로그인
  const factory AuthEvent.signInWithGoogle() = _SignInWithGoogle;

  /// 페이스북으로 로그인
  const factory AuthEvent.signInWithFacebook() = _SignInWithFacebook;

  /// 애플로 로그인
  const factory AuthEvent.signInWithApple() = _SignInWithApple;

  /// 비밀번호 재설정
  const factory AuthEvent.resetPassword({
    required String email,
  }) = _ResetPassword;

  /// 프로필 업데이트
  const factory AuthEvent.updateProfile({
    String? name,
    String? photoUrl,
  }) = _UpdateProfile;

  /// 계정 삭제
  const factory AuthEvent.deleteAccount() = _DeleteAccount;
} 