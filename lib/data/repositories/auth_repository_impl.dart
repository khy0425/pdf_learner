import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:injectable/injectable.dart';
import 'package:pdf_learner_v2/domain/models/user_model.dart';
import 'package:pdf_learner_v2/domain/repositories/auth_repository.dart';
import 'package:pdf_learner_v2/services/firebase_service.dart';
import 'package:flutter/foundation.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._firebaseService, this._googleSignIn);

  @override
  Stream<User?> authStateChanges() {
    return _firebaseService.authStateChanges;
  }

  @override
  User? getCurrentUser() {
    return _firebaseService.currentUser;
  }

  @override
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('이메일에 해당하는 사용자가 없습니다.');
        case 'wrong-password':
          throw Exception('비밀번호가 잘못되었습니다.');
        case 'invalid-email':
          throw Exception('유효하지 않은 이메일 형식입니다.');
        case 'user-disabled':
          throw Exception('이 계정은 비활성화되었습니다. 관리자에게 문의하세요.');
        case 'too-many-requests':
          throw Exception('너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
        default:
          throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      throw Exception('로그인 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  @override
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('이미 사용 중인 이메일입니다. 다른 이메일을 사용하거나 로그인하세요.');
        case 'invalid-email':
          throw Exception('유효하지 않은 이메일 형식입니다.');
        case 'operation-not-allowed':
          throw Exception('이메일/비밀번호 계정이 비활성화되어 있습니다. 관리자에게 문의하세요.');
        case 'weak-password':
          throw Exception('비밀번호가 너무 약합니다. 보다 강력한 비밀번호를 사용하세요.');
        default:
          throw Exception('회원가입 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      throw Exception('회원가입 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    try {
      return await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          throw Exception('익명 로그인이 비활성화되어 있습니다. 관리자에게 문의하세요.');
        default:
          throw Exception('익명 로그인 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      throw Exception('익명 로그인 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 Firebase Auth의 팝업 방식 사용
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // 모바일 환경에서는 GoogleSignIn 패키지 사용
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('구글 로그인이 취소되었습니다.');
        }

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
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
    throw UnimplementedError('페이스북 로그인은 구현되지 않았습니다.');
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