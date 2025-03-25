import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// 사용자 모델
@freezed
class UserModel with _$UserModel {
  /// 사용자 모델 생성자
  const factory UserModel({
    /// 사용자 ID
    required String id,

    /// 이메일
    required String email,

    /// 이름
    String? displayName,

    /// 프로필 사진 URL
    String? photoURL,

    /// 이메일 인증 여부
    @Default(false) bool isEmailVerified,

    /// 생성일
    required DateTime createdAt,

    /// 마지막 로그인 일시
    required DateTime lastSignInTime,
  }) = _UserModel;

  /// JSON으로부터 사용자 모델 생성
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Firebase User로부터 사용자 모델 생성
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignInTime: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }
} 