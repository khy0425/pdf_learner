import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/web_firebase_initializer.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  
  final WebFirebaseInitializer _webFirebaseInitializer = WebFirebaseInitializer();
  
  AuthService() {
    if (kDebugMode) {
      print('AuthService 초기화');
      print('현재 인증된 사용자: ${_auth.currentUser?.uid}');
    }
    
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('현재 로그인된 사용자 발견: ${currentUser.uid}');
        await _onAuthStateChanged(currentUser);
      } else {
        print('로그인된 사용자 없음');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('인증 상태 초기화 오류: $e');
      _error = '인증 상태를 확인하는 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    print('인증 상태 변경: ${firebaseUser?.uid}');
    
    if (firebaseUser == null) {
      print('사용자가 로그아웃됨');
      _user = null;
      notifyListeners();
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_${firebaseUser.uid}');
      
      if (userJson != null) {
        print('기존 사용자 정보 로드');
        _user = UserModel.fromJson(
          Map<String, dynamic>.from(const JsonDecoder().convert(userJson))
        );
      } else {
        print('신규 사용자 정보 생성');
        _user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '사용자',
          photoURL: firebaseUser.photoURL,
          emailVerified: firebaseUser.emailVerified,
          createdAt: DateTime.now(),
          subscriptionTier: 'free',
          maxPdfTextLength: 50000,
          maxPdfTextLengthPerPage: 1000,
          maxPdfTextLengthPerDay: 100000,
          maxPdfTextLengthPerMonth: 1000000,
          maxPdfTextLengthPerYear: 10000000,
          maxPdfTextLengthPerLifetime: 100000000,
        );
        
        print('신규 사용자 정보 저장 시도');
        await _saveUser(_user!);
        print('신규 사용자 정보 저장 완료');
      }
      
      print('사용자 상태 업데이트 완료: ${_user?.uid}');
      notifyListeners();
    } catch (e) {
      print('사용자 데이터 로드 오류: $e');
      _error = '사용자 데이터를 불러오는 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> _saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_${user.uid}',
        JsonEncoder().convert(user.toJson())
      );
    } catch (e) {
      print('사용자 정보 저장 오류: $e');
      throw Exception('사용자 정보 저장 실패: $e');
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      print('Google 로그인 시도');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await _webFirebaseInitializer.signInWithGoogle();
        print('웹 Google 로그인 결과: $userData');
        
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _saveUser(_user!);
          print('웹 Google 로그인 성공: ${_user?.uid}');
        } else {
          throw Exception('Google 로그인 실패: 사용자 데이터를 받지 못했습니다.');
        }
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google 로그인이 취소되었습니다.');
        
        print('Google 계정 선택 완료');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        print('Firebase 인증 완료: ${userCredential.user?.uid}');
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      _error = 'Google 로그인에 실패했습니다.';
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      print('이메일/비밀번호 로그인 시도');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await _webFirebaseInitializer.signInWithEmailPassword(email, password);
        
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _saveUser(_user!);
        } else {
          throw Exception('로그인 실패: 사용자 데이터를 받지 못했습니다.');
        }
      } else {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user == null) {
          throw Exception('Firebase 로그인 실패');
        }
      }
    } catch (e) {
      print('이메일/비밀번호 로그인 오류: $e');
      _error = '이메일 또는 비밀번호가 올바르지 않습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      print('이메일/비밀번호 회원가입 시도');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await _webFirebaseInitializer.signUpWithEmailPassword(email, password);
        
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _saveUser(_user!);
        } else {
          throw Exception('회원가입 실패: 사용자 데이터를 받지 못했습니다.');
        }
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user == null) {
          throw Exception('Firebase 회원가입 실패');
        }
        
        await userCredential.user!.updateDisplayName(displayName);
      }
    } catch (e) {
      print('회원가입 오류: $e');
      _error = '회원가입에 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signOut();
    } catch (e) {
      print('로그아웃 오류: $e');
      _error = '로그아웃에 실패했습니다.';
    } finally {
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateApiKey(String apiKey) async {
    try {
      if (_user == null) throw Exception('로그인이 필요합니다.');
      
      await _saveApiKey(_user!.uid, apiKey);
      notifyListeners();
    } catch (e) {
      print('API 키 업데이트 오류: $e');
      _error = 'API 키 업데이트에 실패했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> _saveApiKey(String userId, String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apiKey_$userId', apiKey);
    } catch (e) {
      print('API 키 저장 오류: $e');
      throw Exception('API 키 저장 실패: $e');
    }
  }
  
  Future<String?> getStoredApiKey() async {
    try {
      if (_user == null) return null;
      return await _getApiKey(_user!.uid);
    } catch (e) {
      print('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  Future<String?> _getApiKey(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('apiKey_$userId');
    } catch (e) {
      print('API 키 불러오기 오류: $e');
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 