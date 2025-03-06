import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuthService _firebaseAuthService;

  AuthService() : _firebaseAuthService = FirebaseAuthService();

  bool get isLoggedIn => _firebaseAuthService.currentUser != null;
  
  User? get currentUser => _firebaseAuthService.currentUser;

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