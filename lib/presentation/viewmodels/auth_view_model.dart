import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/user_model.dart';
import '../../core/services/firebase_service.dart';

/// 인증 상태
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

/// 인증 뷰모델
@injectable
class AuthViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _error;

  AuthViewModel(this._firebaseService) {
    _init();
  }

  // 게터
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  bool get hasError => _status == AuthStatus.error;

  void _init() {
    _firebaseService.authStateChanges.listen((user) {
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          settings: UserSettings.createDefault(),
        );
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final credential = await _firebaseService.signInWithEmailAndPassword(email, password);
      if (credential?.user == null) {
        _error = '로그인에 실패했습니다.';
        _status = AuthStatus.error;
      } else {
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final credential = await _firebaseService.createUserWithEmailAndPassword(email, password);
      if (credential?.user == null) {
        _error = '회원가입에 실패했습니다.';
        _status = AuthStatus.error;
      } else {
        await credential!.user!.updateDisplayName(displayName);
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _firebaseService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _firebaseService.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (_currentUser != null) {
        final user = _firebaseService.currentUser;
        if (user != null) {
          if (displayName != null) {
            await user.updateDisplayName(displayName);
          }
          if (photoURL != null) {
            await user.updatePhotoURL(photoURL);
          }
          
          _currentUser = _currentUser!.copyWith(
            displayName: displayName ?? _currentUser!.displayName,
            photoURL: photoURL ?? _currentUser!.photoURL,
            updatedAt: DateTime.now(),
          );
        }
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final user = _firebaseService.currentUser;
      if (user != null) {
        await user.delete();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser != null 
        ? AuthStatus.authenticated 
        : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
} 