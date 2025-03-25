import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:pdf_learner_v2/domain/models/user_model.dart';
import 'package:pdf_learner_v2/domain/repositories/auth_repository.dart';
import 'package:pdf_learner_v2/core/services/firebase_service.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth;
  UserModel? _currentUser;

  AuthRepositoryImpl(this._firebaseService, this._googleSignIn) 
      : _auth = FirebaseAuth.instance {
    _init();
  }

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
          settings: UserSettings(
            theme: 'light',
            language: 'ko',
            notificationsEnabled: true,
          ),
        );
      } else {
        _currentUser = null;
      }
    });
  }

  @override
  Stream<UserModel?> get authStateChanges => _firebaseService.authStateChanges.map((user) {
    if (user == null) return null;
    
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      settings: UserSettings.createDefault(),
    );
  });

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseService.signInWithEmailAndPassword(email, password);
      final user = credential?.user;
      
      if (user == null) return null;
      
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        settings: UserSettings.createDefault(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseService.createUserWithEmailAndPassword(email, password);
      final user = credential?.user;
      
      if (user == null) return null;
      
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        settings: UserSettings.createDefault(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseService.currentUser;
    if (user == null) return null;
    
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      settings: UserSettings.createDefault(),
    );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firebaseService.updateUser(user);
  }

  @override
  Future<void> deleteUser() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;
    
    await user.delete();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseService.sendPasswordResetEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('사용자를 찾을 수 없습니다');
    
    await user.updatePassword(newPassword);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) return null;
      
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        settings: UserSettings.createDefault(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithApple() async {
    throw UnimplementedError('애플 로그인은 아직 구현되지 않았습니다');
  }

  @override
  Future<UserModel?> signInWithFacebook() async {
    throw UnimplementedError('페이스북 로그인은 아직 구현되지 않았습니다');
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('사용자를 찾을 수 없습니다');
    
    await user.sendEmailVerification();
  }

  @override
  Future<void> verifyEmail() async {
    // 이메일 인증은 Firebase 콘솔에서 설정해야 합니다
    throw UnimplementedError('이 메서드는 클라이언트에서 직접 구현할 수 없습니다');
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseService.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<void> changeEmail(String newEmail) async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('사용자를 찾을 수 없습니다');
    
    await user.updateEmail(newEmail);
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('사용자를 찾을 수 없습니다');
    
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('사용자를 찾을 수 없습니다');
    
    await user.delete();
  }

  @override
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    throw UnimplementedError('전화번호 인증은 아직 구현되지 않았습니다');
  }

  @override
  Future<void> verifyPhoneCode(String verificationId, String code) async {
    throw UnimplementedError('전화번호 인증 코드 확인은 아직 구현되지 않았습니다');
  }
} 