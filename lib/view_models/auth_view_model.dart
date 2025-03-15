import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_key_service.dart';

/// 인증 관련 비즈니스 로직을 담당하는 ViewModel 클래스
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ApiKeyService _apiKeyService;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  /// 현재 로그인된 사용자
  UserModel? get user => _user;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 로그인 여부
  bool get isLoggedIn => _user != null;
  
  AuthViewModel({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    ApiKeyService? apiKeyService,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _apiKeyService = apiKeyService ?? ApiKeyService() {
    _initializeAuthState();
    
    // Firebase Auth 상태 변경 리스너 추가
    _authRepository.authStateChanges.listen((firebaseUser) {
      debugPrint('Firebase Auth 상태 변경: ${firebaseUser?.uid}');
      _onAuthStateChanged(firebaseUser);
    });
  }
  
  /// 인증 상태 초기화
  Future<void> _initializeAuthState() async {
    try {
      final currentUser = _authRepository.currentUser;
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
  
  /// 인증 상태 변경 처리
  Future<void> _onAuthStateChanged(firebaseUser) async {
    debugPrint('인증 상태 변경: ${firebaseUser?.uid}');
    
    if (firebaseUser == null) {
      debugPrint('사용자가 로그아웃됨');
      _user = null;
      notifyListeners();
      return;
    }
    
    try {
      final userData = await _userRepository.getUser(firebaseUser.uid);
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
        await _userRepository.saveUser(_user!);
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
  
  /// Google로 로그인
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Google 로그인 시도');
      _setLoading(true);
      
      await _authRepository.signInWithGoogle();
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      _setError('Google 로그인에 실패했습니다.');
      _user = null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      
      await _authRepository.signInWithEmailPassword(email, password);
    } catch (e) {
      debugPrint('이메일/비밀번호 로그인 오류: $e');
      _setError('이메일 또는 비밀번호가 올바르지 않습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      
      final userCredential = await _authRepository.signUpWithEmailPassword(email, password);
      await _authRepository.updateProfile(displayName: displayName);
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      _setError('회원가입에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      _setError('로그아웃에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// API 키 업데이트
  Future<void> updateApiKey(String apiKey) async {
    try {
      if (_user == null) throw Exception('로그인이 필요합니다.');
      
      await _apiKeyService.saveApiKey(_user!.uid, apiKey);
      _user = _user!.copyWith(apiKey: apiKey);
      notifyListeners();
    } catch (e) {
      debugPrint('API 키 업데이트 오류: $e');
      _setError('API 키 업데이트에 실패했습니다.');
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey() async {
    try {
      if (_user == null) return null;
      return await _apiKeyService.getApiKey(_user!.uid);
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 