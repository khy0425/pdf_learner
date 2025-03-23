import 'dart:async';
import 'package:flutter/foundation.dart';

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

/// 인증 서비스
class AuthService extends ChangeNotifier {
  // Firebase 인증 관련 변수들은 주석 처리
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  AppUser? _user;
  bool _isGuest = false;
  int _userPoints = 0;
  String? _error;
  
  AuthService() {
    // 기본적으로 게스트 로그인
    signInAsGuest();
  }
  
  /// 현재 사용자
  AppUser? get currentUser {
    if (_isGuest) {
      return AppUser.guest();
    }
    
    if (_user != null) {
      return _user;
    }
    
    // Firebase 없이 사용
    /*
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _user = AppUser.fromFirebaseUser(firebaseUser);
      return _user;
    }
    */
    
    return null;
  }
  
  /// 로그인 여부
  bool get isLoggedIn {
    final user = currentUser;
    return user != null && user.id.isNotEmpty && !user.isAnonymous;
  }
  
  /// 사용자 포인트
  int get userPoints => _userPoints;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 인증 상태 변경 스트림
  Stream<AppUser?> get authStateChanges {
    // 모의 구현, 항상 현재 사용자 반환
    return Stream.value(currentUser);
    
    /*
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Desktop 환경에서는 Firebase 인증 사용 안 함
      return Stream.value(AppUser.guest());
    }
    
    return _auth.authStateChanges().map((User? user) {
      if (_isGuest) {
        return AppUser.guest();
      }
      return AppUser.fromFirebaseUser(user);
    });
    */
  }
  
  /// 이메일 및 비밀번호로 회원가입
  Future<AppUser?> signUpWithEmail(String email, String password) async {
    try {
      // 모의 구현
      _user = AppUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        isAnonymous: false,
      );
      
      /*
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = AppUser.fromFirebaseUser(userCredential.user);
      */
      
      _isGuest = false;
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('이메일 회원가입 실패: $e');
      return null;
    }
  }
  
  /// 이메일 및 비밀번호로 로그인
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      // 모의 구현
      _user = AppUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        isAnonymous: false,
      );
      
      /*
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = AppUser.fromFirebaseUser(userCredential.user);
      */
      
      _isGuest = false;
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('이메일 로그인 실패: $e');
      return null;
    }
  }
  
  /// Google 계정으로 로그인
  Future<AppUser?> signInWithGoogle() async {
    try {
      // 모의 구현
      _user = AppUser(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'google_user@example.com',
        displayName: 'Google User',
        photoUrl: 'https://example.com/avatar.png',
        isAnonymous: false,
      );
      
      /*
      if (kIsWeb) {
        // 웹 환경에서의 Google 로그인
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        _user = AppUser.fromFirebaseUser(userCredential.user);
      } else {
        // 모바일 환경에서의 Google 로그인
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        _user = AppUser.fromFirebaseUser(userCredential.user);
      }
      */
      
      _isGuest = false;
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('Google 로그인 실패: $e');
      return null;
    }
  }
  
  /// 게스트 모드로 로그인
  Future<AppUser> signInAsGuest() async {
    /*
    try {
      await _auth.signOut();
    } catch (e) {
      // 로그아웃 실패는 무시
    }
    */
    
    _isGuest = true;
    final guestUser = AppUser.guest();
    _user = guestUser;
    notifyListeners();
    return guestUser;
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      /*
      if (!_isGuest) {
        await _auth.signOut();
      }
      */
      
      _isGuest = false;
      _user = null;
      _userPoints = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('로그아웃 실패: $e');
    }
  }
  
  /// 포인트 추가
  Future<bool> addPoints(int points) async {
    try {
      if (!isLoggedIn) {
        _error = '로그인 후 포인트를 획득할 수 있습니다.';
        notifyListeners();
        return false;
      }
      
      _userPoints += points;
      notifyListeners();
      
      // 파이어베이스에 포인트 업데이트 (필요시 구현)
      
      return true;
    } catch (e) {
      _error = '포인트 추가 중 오류: $e';
      notifyListeners();
      return false;
    }
  }
} 