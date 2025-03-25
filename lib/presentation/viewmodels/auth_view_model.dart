import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// 인증 상태 열거형
enum AuthStatus {
  initial,       // 초기 상태
  loading,       // 로딩 중
  authenticated, // 인증됨
  guest,         // 게스트 모드
  unauthenticated, // 인증되지 않음
  error,         // 오류 발생
}

/// 인증 뷰모델
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserModel? _currentUser;
  String? _error;
  bool _isGuestMode = false;
  bool _isLoading = false;

  AuthViewModel(this._authRepository) {
    _init();
  }
  
  /// 현재 로그인된 사용자
  UserModel? get currentUser => _currentUser;
  
  /// 인증 오류 메시지
  String? get error => _error;
  
  /// 게스트 모드 상태
  bool get isGuestMode => _status == AuthStatus.guest;
  
  /// 로그인된 상태 (일반 또는 게스트)
  bool get isAuthenticated => _status == AuthStatus.authenticated || _status == AuthStatus.guest;
  
  /// 로그인되지 않은 상태
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  
  /// 로딩 상태
  bool get isLoading => _status == AuthStatus.loading;
  
  /// 오류 상태
  bool get hasError => _status == AuthStatus.error;
  
  /// 오류 상태
  bool get isError => _status == AuthStatus.error;
  
  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '사용자',
          photoURL: user.photoURL ?? '',
          settings: UserSettings.createDefault(),
        );
        
        _isGuestMode = user.isAnonymous;
        
        _status = AuthStatus.authenticated;
      } else if (_isGuestMode) {
        _currentUser = UserModel.guest();
        _status = AuthStatus.guest;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
      
      _error = null;
      _isLoading = false;
      notifyListeners();
    });
  }
  
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signIn(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signUp(email, password);
      await updateProfile(displayName: displayName);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signInAnonymously() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signInAnonymously();
      
      _status = AuthStatus.guest;
      _currentUser = UserModel.guest();
      _error = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      
      if (e.toString().contains('operation-not-allowed')) {
        _error = '익명 로그인이 비활성화되어 있습니다. Firebase 콘솔에서 익명 로그인을 활성화해주세요.';
      } else {
        _error = e.toString();
      }
      
      notifyListeners();
      
      debugPrint('익명 로그인 에러: $e');
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_error != null) {
          _status = AuthStatus.unauthenticated;
          _error = null;
          notifyListeners();
        }
      });
    }
  }
  
  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signInWithGoogle();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.resetPassword(email);
      _status = _user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signOut();
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = _user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}