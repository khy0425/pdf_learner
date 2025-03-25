import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_key_service.dart';
import '../services/rate_limiter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';

part 'auth_viewmodel.freezed.dart';

enum AuthStatus {
  unknown,
  authenticated,
  anonymousAuthenticated,
  unauthenticated,
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required UserModel user}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
  const factory AuthState.passwordResetSent() = _PasswordResetSent;
  const factory AuthState.profileUpdated() = _ProfileUpdated;
  const factory AuthState.passwordChanged() = _PasswordChanged;
}

/// 인증 관련 비즈니스 로직을 담당하는 ViewModel 클래스
@injectable
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ApiKeyService _apiKeyService;
  final RateLimiter _rateLimiter;
  final GoogleSignIn _googleSignIn;
  
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _mounted = true; // ViewModel이 유효한지 여부
  
  /// 현재 로그인된 사용자
  UserModel? get user => _user;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;
  
  /// ViewModel이 여전히 유효한지 여부
  bool get mounted => _mounted;
  
  /// 로그인 여부
  bool get isLoggedIn => _user != null && _user!.uid != null && _user!.uid!.isNotEmpty;
  
  /// 현재 로그인된 사용자
  User? get currentUser {
    try {
      return _authRepository.currentUser;
    } catch (e) {
      debugPrint('currentUser 접근 중 오류: $e');
      return null;
    }
  }
  
  AuthViewModel(
    this._authRepository,
    this._userRepository,
    this._apiKeyService,
    this._rateLimiter,
    this._googleSignIn,
  ) {
    _init();
  }
  
  /// ViewModel 초기화
  void _init() {
    _authRepository.authStateChanges().listen((User? user) {
      _user = user;
      if (user == null) {
        _status = AuthStatus.unauthenticated;
      } else if (user.isAnonymous) {
        _status = AuthStatus.anonymousAuthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }
  
  /// 이메일과 비밀번호로 로그인
  Future<void> signIn(String email, String password) async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('signIn')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.signIn(email, password);
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('로그인 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일과 비밀번호로 회원가입
  Future<void> signUp(String email, String password, String name) async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('signUp')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      final user = await _authRepository.signUp(email, password, name);
      
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        _setError('회원가입 실패');
      }
    } catch (e) {
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Google 로그인
  Future<void> signInWithGoogle() async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('signInWithGoogle')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.signInWithGoogle();
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('Google 로그인 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Facebook 로그인
  Future<void> signInWithFacebook() async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('signInWithFacebook')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.signInWithFacebook();
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('Facebook 로그인 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 애플 로그인
  Future<void> signInWithApple() async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('signInWithApple')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.signInWithApple();
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('Apple 로그인 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    if (_isLoading) return;
    
    try {
      _setLoading(true);
      await _authRepository.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      _setError(null);
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('resetPassword')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.resetPassword(email);
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('비밀번호 재설정 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 프로필 업데이트
  Future<void> updateProfile(UserModel user) async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }
    
    try {
      await _authRepository.updateProfile(user);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _setError('프로필 업데이트 중 오류가 발생했습니다: $e');
      debugPrint('프로필 업데이트 오류: $e');
    }
  }
  
  /// 비밀번호 변경
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.email.isEmpty) {
      _setError('로그인이 필요합니다.');
      return;
    }
    
    if (_isLoading) return;
    
    if (!_rateLimiter.checkRequest('changePassword')) {
      _setError('잠시 후 다시 시도해주세요.');
      return;
    }
    
    try {
      _setLoading(true);
      await _authRepository.changePassword(currentPassword, newPassword);
      _setError(null);
    } catch (e) {
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// 사용자 계정 삭제
  Future<void> deleteAccount() async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }
    
    try {
      if (_user != null && _user!.uid != null) {
        await _userRepository.deleteUser(_user!.uid!);
      }
      await _authRepository.deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
    }
  }
  
  /// API 키 설정
  Future<bool> setApiKey(String key) async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return false;
    }
    
    try {
      await _apiKeyService.setApiKey('gemini', key);
      return true;
    } catch (e) {
      _setError('API 키 저장 중 오류가 발생했습니다: $e');
      return false;
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
  
  /// 오류 메시지 설정
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// 인증 오류 처리
  void _handleAuthError(dynamic e) {
    String errorMessage = '알 수 없는 오류가 발생했습니다.';
    
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '등록되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 일치하지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다.';
          break;
        case 'operation-not-allowed':
          errorMessage = '이 로그인 방식은 현재 비활성화되어 있습니다.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = '다른 로그인 방식으로 이미 가입된 계정입니다.';
          break;
        case 'invalid-credential':
          errorMessage = '잘못된 인증 정보입니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도하세요.';
          break;
        case 'network-request-failed':
          errorMessage = '네트워크 연결이 불안정합니다.';
          break;
        default:
          errorMessage = '인증 오류: ${e.message}';
      }
    }
    
    _setError(errorMessage);
    debugPrint('AuthViewModel 오류: $e');
  }
  
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
} 