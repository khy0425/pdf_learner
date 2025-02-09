import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      await _auth.signInWithPopup(googleProvider);
    } catch (e) {
      print('Google 로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
} 