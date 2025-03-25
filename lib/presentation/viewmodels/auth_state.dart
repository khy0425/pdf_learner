import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/user_model.dart';

part 'auth_state.freezed.dart';

/// 인증 상태
@freezed
class AuthState with _$AuthState {
  /// 초기 상태
  const factory AuthState.initial() = _Initial;

  /// 로딩 상태
  const factory AuthState.loading() = _Loading;

  /// 인증된 상태
  const factory AuthState.authenticated(UserModel user) = _Authenticated;

  /// 인증되지 않은 상태
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// 에러 상태
  const factory AuthState.error(String message) = _Error;
} 