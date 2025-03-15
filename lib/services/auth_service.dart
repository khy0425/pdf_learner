import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'web_firebase_initializer.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  
  AuthService() {
    debugPrint('AuthService 초기화');
    _initializeAuthState();
    // Firebase Auth 상태 변경 리스너 추가
    _auth.authStateChanges().listen((User? firebaseUser) {
      debugPrint('Firebase Auth 상태 변경: ${firebaseUser?.uid}');
      _onAuthStateChanged(firebaseUser);
    });
    
    // 현재 로그인 상태 확인
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      debugPrint('현재 로그인된 사용자: ${currentUser.uid}');
    } else {
      debugPrint('현재 로그인된 사용자 없음');
    }
  }
  
  Future<void> _initializeAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('현재 로그인된 사용자 발견: ${currentUser.uid}');
        await _onAuthStateChanged(currentUser);
      } else {
        debugPrint('로그인된 사용자 없음');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('인증 상태 초기화 오류: $e');
      _error = '인증 상태를 확인하는 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('인증 상태 변경: ${firebaseUser?.uid}');
    
    if (firebaseUser == null) {
      debugPrint('사용자가 로그아웃됨');
      _user = null;
      notifyListeners();
      return;
    }
    
    try {
      final userData = await _databaseHelper.getUser(firebaseUser.uid);
      debugPrint('사용자 데이터 조회 결과: ${userData?.uid}');
      
      if (userData != null) {
        debugPrint('기존 사용자 정보 로드');
        _user = userData;
      } else {
        debugPrint('신규 사용자 정보 생성');
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
          maxPdfTextLengthPerPdf: 10000,
          maxPdfTextLengthPerPdfPerPage: 1000,
          maxPdfTextLengthPerPdfPerDay: 100000,
          maxPdfTextLengthPerPdfPerMonth: 1000000,
          maxPdfTextLengthPerPdfPerYear: 10000000,
          maxPdfTextLengthPerPdfPerLifetime: 100000000,
          maxPdfTextLengthPerPdfPerPagePerDay: 10000,
          maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
        );
        
        debugPrint('신규 사용자 정보 저장 시도');
        await _databaseHelper.saveUser(_user!);
        debugPrint('신규 사용자 정보 저장 완료');
      }
      
      debugPrint('사용자 상태 업데이트 완료: ${_user?.uid}');
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 데이터 로드 오류: $e');
      _error = '사용자 데이터를 불러오는 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Google 로그인 시도');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signInWithGoogle();
        debugPrint('웹 Google 로그인 결과: $userData');
        
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _databaseHelper.saveUser(_user!);
          debugPrint('웹 Google 로그인 성공: ${_user?.uid}');
        } else {
          throw Exception('Google 로그인 실패: 사용자 데이터를 받지 못했습니다.');
        }
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google 로그인이 취소되었습니다.');
        
        debugPrint('Google 계정 선택 완료');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        debugPrint('Firebase 인증 완료: ${userCredential.user?.uid}');
      }
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      _error = 'Google 로그인에 실패했습니다.';
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signInWithEmailPassword(email, password);
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _databaseHelper.saveUser(_user!);
        }
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      debugPrint('이메일/비밀번호 로그인 오류: $e');
      _error = '이메일 또는 비밀번호가 올바르지 않습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (kIsWeb) {
        final userData = await WebFirebaseInitializer.signUpWithEmailPassword(email, password);
        if (userData != null) {
          _user = UserModel.fromMap(userData);
          await _databaseHelper.saveUser(_user!);
        }
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        await userCredential.user?.updateDisplayName(displayName);
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      _error = '회원가입에 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      _error = '로그아웃에 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateApiKey(String apiKey) async {
    try {
      if (_user == null) throw Exception('로그인이 필요합니다.');
      
      await _databaseHelper.saveApiKey(_user!.uid, apiKey);
      _user = _user!.copyWith(apiKey: apiKey);
      notifyListeners();
    } catch (e) {
      debugPrint('API 키 업데이트 오류: $e');
      _error = 'API 키 업데이트에 실패했습니다.';
      notifyListeners();
    }
  }
  
  Future<String?> getApiKey() async {
    try {
      if (_user == null) return null;
      return await _databaseHelper.getApiKey(_user!.uid);
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 