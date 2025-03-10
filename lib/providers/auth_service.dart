import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_auth_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuthService _firebaseAuthService;
  
  AuthService(this._firebaseAuthService);
  
  UserModel? get currentUser {
    try {
      return _firebaseAuthService.currentUser;
    } catch (e) {
      debugPrint('currentUser 접근 중 오류: $e');
      return null;
    }
  }
  
  bool get isLoading {
    try {
      return _firebaseAuthService.isLoading;
    } catch (e) {
      debugPrint('isLoading 접근 중 오류: $e');
      return false;
    }
  }
  
  bool get isLoggedIn {
    try {
      return currentUser != null;
    } catch (e) {
      debugPrint('isLoggedIn 접근 중 오류: $e');
      return false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _firebaseAuthService.signUp(
      email: email,
      password: password,
      name: name,
    );
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _firebaseAuthService.signIn(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _firebaseAuthService.signInWithGoogle();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _firebaseAuthService.signOut();
    notifyListeners();
  }
} 