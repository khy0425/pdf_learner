import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf_learner_v2/models/user_model.dart';

/// 사용자 모델
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  
  AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });
  
  /// Firebase User에서 변환 (Firebase 사용 시)
  factory AppUser.fromFirebaseUser(dynamic user) {
    if (user == null) {
      return AppUser(id: '', isAnonymous: true);
    }
    
    // 실제 구현에서는 Firebase User 객체 사용
    return AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@example.com',
      displayName: 'User',
      photoUrl: null,
      isAnonymous: false,
    );
  }
  
  /// 게스트 사용자 생성
  factory AppUser.guest() {
    return AppUser(
      id: 'guest',
      displayName: '게스트',
      isAnonymous: true,
    );
  }
}

/// 인증 서비스 - Firebase 인증 관리
class AuthService extends ChangeNotifier {
  // Firebase 인증 관련 변수들
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  UserModel? _userModel;
  String? _error;
  
  AuthService() {
    // 인증 상태 변경 감지
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  // 인증 상태 변경 시 호출되는 메서드
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userModel = null;
      notifyListeners();
      return;
    }
    
    try {
      // Firestore에서 사용자 데이터 로드
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        _userModel = UserModel.fromFirebaseUser(firebaseUser, data: doc.data());
      } else {
        // 새 사용자인 경우 기본 데이터 생성
        final newUser = UserModel.fromFirebaseUser(firebaseUser);
        await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        _userModel = newUser;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 데이터 로드 오류: $e');
      _userModel = UserModel.fromFirebaseUser(firebaseUser);
      notifyListeners();
    }
  }
  
  /// 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  /// 사용자 모델
  UserModel? get user => _userModel;
  
  /// 로그인 여부
  bool get isLoggedIn => currentUser != null;
  
  /// 사용자 포인트
  int get userPoints => _userModel?.points ?? 0;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// 이메일 및 비밀번호로 회원가입
  Future<UserModel?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Firestore에 사용자 데이터 저장
      final newUser = UserModel.fromFirebaseUser(userCredential.user!);
      await _db.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
      
      _userModel = newUser;
      _error = null;
      notifyListeners();
      return _userModel;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }
  
  /// 이메일 및 비밀번호로 로그인
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _error = null;
      return _userModel;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }
  
  /// Google로 로그인
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _error = '로그인이 취소되었습니다';
        notifyListeners();
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // 첫 로그인인지 확인
      final docSnapshot = await _db.collection('users').doc(userCredential.user!.uid).get();
      
      if (!docSnapshot.exists) {
        // 첫 로그인이면 사용자 데이터 생성
        final newUser = UserModel.fromFirebaseUser(userCredential.user!);
        await _db.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
      }
      
      _error = null;
      return _userModel;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }
  
  /// 익명 로그인
  Future<UserModel?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      // 사용자 데이터 생성
      final newUser = UserModel.fromFirebaseUser(userCredential.user!);
      await _db.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
      
      _error = null;
      return _userModel;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      _error = '로그아웃 중 오류가 발생했습니다';
      notifyListeners();
    }
  }
  
  /// 게스트로 로그인
  Future<UserModel> signInAsGuest() async {
    try {
      // 익명 로그인으로 구현
      await signInAnonymously();
      
      // 게스트 사용자 생성 및 반환
      if (_userModel == null) {
        _userModel = UserModel.createDefaultUser();
      }
      
      notifyListeners();
      return _userModel!;
    } catch (e) {
      debugPrint('게스트 로그인 오류: $e');
      _error = '게스트 로그인 중 오류가 발생했습니다';
      notifyListeners();
      
      // 에러 발생 시 기본 게스트 모델 반환
      return UserModel.createDefaultUser();
    }
  }
  
  /// 사용자 정보 업데이트
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      
      // Firestore 데이터도 업데이트
      if (_userModel != null) {
        final updatedUser = _userModel!.copyWith(
          displayName: displayName,
          photoURL: photoURL,
        );
        
        await _db.collection('users').doc(user.uid).update({
          'displayName': displayName,
          'photoURL': photoURL,
        });
        
        _userModel = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('프로필 업데이트 오류: $e');
      _error = '프로필 업데이트 중 오류가 발생했습니다';
      notifyListeners();
    }
  }
  
  /// 인증 오류 처리
  void _handleAuthError(dynamic error) {
    debugPrint('인증 오류: $error');
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          _error = '등록되지 않은 이메일입니다';
          break;
        case 'wrong-password':
          _error = '비밀번호가 올바르지 않습니다';
          break;
        case 'email-already-in-use':
          _error = '이미 사용 중인 이메일입니다';
          break;
        case 'weak-password':
          _error = '비밀번호가 너무 약합니다';
          break;
        case 'invalid-email':
          _error = '유효하지 않은 이메일 형식입니다';
          break;
        case 'operation-not-allowed':
          _error = '이 로그인 방식은 현재 비활성화되어 있습니다';
          break;
        default:
          _error = '로그인 중 오류가 발생했습니다: ${error.message}';
      }
    } else {
      _error = '인증 중 오류가 발생했습니다';
    }
    
    notifyListeners();
  }
  
  /// 포인트 추가
  Future<bool> addPoints(int points) async {
    if (_userModel == null || currentUser == null) return false;
    
    try {
      final updatedPoints = _userModel!.points + points;
      await _db.collection('users').doc(currentUser!.uid).update({
        'points': updatedPoints
      });
      
      // 로컬 모델 업데이트
      _userModel = _userModel!.copyWith(points: updatedPoints);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('포인트 추가 오류: $e');
      return false;
    }
  }

  /// 현재 사용자 정보 반환 (로그인하지 않은 경우 게스트 모드)
  UserModel? getCurrentUser() {
    if (_auth.currentUser != null) {
      return _userModel;
    }
    return UserModel.createDefaultUser();
  }
} 