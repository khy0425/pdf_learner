import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class FirebaseAuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  FirebaseAuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Firestore에서 사용자 데이터 가져오기
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _currentUser = User.fromMap(doc.data()!);
    } else {
      // 신규 사용자인 경우 기본 데이터 생성
      _currentUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? '사용자',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(
            _currentUser!.toMap(),
          );
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      
      // Firestore에 사용자 데이터 저장은 _onAuthStateChanged에서 처리됨
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Exception _handleFirebaseAuthError(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception('이미 사용 중인 이메일입니다');
        case 'invalid-email':
          return Exception('잘못된 이메일 형식입니다');
        case 'weak-password':
          return Exception('비밀번호가 너무 약합니다');
        case 'user-not-found':
          return Exception('등록되지 않은 이메일입니다');
        case 'wrong-password':
          return Exception('잘못된 비밀번호입니다');
        default:
          return Exception('인증 오류: ${e.message}');
      }
    }
    return Exception('알 수 없는 오류가 발생했습니다');
  }
} 