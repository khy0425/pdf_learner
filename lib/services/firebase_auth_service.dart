import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:js' as js;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // AppLogger 사용을 위한 import

/// Firebase 인증을 관리하는 서비스 클래스
class FirebaseAuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 웹 환경에서의 Google 로그인을 위한 설정
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 생성자
  FirebaseAuthService() {
    _initAuth();
  }
  
  // 인증 초기화 (현재 사용자 확인)
  Future<void> _initAuth() async {
    try {
      AppLogger.log('FirebaseAuthService 초기화 시작');
      
      // Firebase 인증 상태 변경 구독
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        
        if (user != null) {
          AppLogger.log('사용자 로그인 상태: ${user.displayName ?? user.email}');
          
          // 웹 환경에서 로컬 스토리지에 사용자 정보 저장
          if (kIsWeb) {
            _saveUserToLocalStorage(user);
          }
        } else {
          AppLogger.log('사용자 로그아웃 상태');
        }
        
        notifyListeners();
      });
      
      // 현재 로그인 상태 확인
      _user = _auth.currentUser;
      
      // 웹 환경에서 추가 확인
      if (kIsWeb && _user == null) {
        _checkWebLoginStatus();
      }
      
    } catch (e) {
      AppLogger.error('FirebaseAuthService 초기화 오류', e);
      _errorMessage = '인증 초기화 오류: $e';
    }
  }
  
  // 웹 환경에서 로그인 상태 확인 (로컬 스토리지 사용)
  void _checkWebLoginStatus() {
    try {
      final userDetails = js.context.callMethod('getUserDetails', []);
      if (userDetails != null && userDetails['uid'] != null) {
        final uid = userDetails['uid'].toString();
        
        if (uid.isNotEmpty && uid != 'null') {
          AppLogger.log('웹에서 저장된 사용자 발견: $uid');
        }
      }
    } catch (e) {
      AppLogger.error('웹 로그인 상태 확인 오류', e);
    }
  }
  
  // 웹 환경에서 로컬 스토리지에 사용자 정보 저장
  void _saveUserToLocalStorage(User user) {
    if (kIsWeb) {
      try {
        js.context.callMethod('setUserDetails', [
          user.uid,
          user.displayName ?? '',
          user.email ?? ''
        ]);
        
        AppLogger.log('사용자 정보가 로컬 스토리지에 저장됨');
      } catch (e) {
        AppLogger.error('사용자 정보 저장 오류', e);
      }
    }
  }
  
  // 이메일/비밀번호 로그인
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      _user = credential.user;
      
      // SharedPreferences에도 사용자 ID 저장
      if (_user != null) {
        await _saveUserIdToPrefs(_user!.uid);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return _user;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = '해당 이메일의 사용자가 없습니다.';
          break;
        case 'wrong-password':
          _errorMessage = '비밀번호가 올바르지 않습니다.';
          break;
        case 'invalid-email':
          _errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        default:
          _errorMessage = '로그인 오류: ${e.message}';
      }
      
      AppLogger.error('이메일 로그인 오류', e);
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '로그인 오류: $e';
      
      AppLogger.error('이메일 로그인 오류', e);
      notifyListeners();
      return null;
    }
  }
  
  // 구글 로그인
  Future<User?> loginWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      if (kIsWeb) {
        // 웹 환경에서 팝업 방식의 구글 로그인
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        final credential = await _auth.signInWithPopup(googleProvider);
        _user = credential.user;
      } else {
        // 네이티브 환경에서 구글 로그인
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          _isLoading = false;
          _errorMessage = '구글 로그인이 취소되었습니다.';
          notifyListeners();
          return null;
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        _user = userCredential.user;
      }
      
      // SharedPreferences에도 사용자 ID 저장
      if (_user != null) {
        await _saveUserIdToPrefs(_user!.uid);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return _user;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = '구글 로그인 오류: ${e.message}';
      
      AppLogger.error('구글 로그인 오류', e);
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '구글 로그인 오류: $e';
      
      AppLogger.error('구글 로그인 오류', e);
      notifyListeners();
      return null;
    }
  }
  
  // 이메일/비밀번호 회원가입
  Future<User?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      _user = credential.user;
      
      // 사용자 표시 이름 설정
      if (_user != null) {
        await _user!.updateDisplayName(name);
        
        // 프로필 갱신을 위해 사용자 정보 다시 로드
        await _user!.reload();
        _user = _auth.currentUser;
        
        // SharedPreferences에도 사용자 ID 저장
        await _saveUserIdToPrefs(_user!.uid);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return _user;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'weak-password':
          _errorMessage = '비밀번호가 너무 약합니다.';
          break;
        case 'invalid-email':
          _errorMessage = '이메일 형식이 올바르지 않습니다.';
          break;
        default:
          _errorMessage = '회원가입 오류: ${e.message}';
      }
      
      AppLogger.error('회원가입 오류', e);
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '회원가입 오류: $e';
      
      AppLogger.error('회원가입 오류', e);
      notifyListeners();
      return null;
    }
  }
  
  // 로그아웃
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 구글 로그인 상태 해제
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Firebase 로그아웃
      await _auth.signOut();
      
      // 웹 환경에서 로컬 스토리지에서 사용자 정보 삭제
      if (kIsWeb) {
        js.context.callMethod('logoutUser', []);
      }
      
      // SharedPreferences에서 사용자 ID 삭제
      await _removeUserIdFromPrefs();
      
      _isLoading = false;
      _user = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '로그아웃 오류: $e';
      
      AppLogger.error('로그아웃 오류', e);
      notifyListeners();
    }
  }
  
  // SharedPreferences에 사용자 ID 저장
  Future<void> _saveUserIdToPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
    } catch (e) {
      AppLogger.error('SharedPreferences 저장 오류', e);
    }
  }
  
  // SharedPreferences에서 사용자 ID 삭제
  Future<void> _removeUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
    } catch (e) {
      AppLogger.error('SharedPreferences 삭제 오류', e);
    }
  }
  
  // 회원 등급 업그레이드 (프리미엄 업그레이드 구현 시 사용)
  Future<void> upgradeSubscription() async {
    // 이 부분은 실제 구독 시스템 구현 시 필요한 로직 추가
    AppLogger.log('사용자 구독 업그레이드 요청 (미구현)');
  }
} 