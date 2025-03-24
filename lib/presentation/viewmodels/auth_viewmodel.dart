import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_key_service.dart';
import '../utils/rate_limiter.dart';

/// 인증 관련 비즈니스 로직을 담당하는 ViewModel 클래스
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ApiKeyService _apiKeyService;
  final RateLimiter _rateLimiter;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _mounted = true; // ViewModel이 유효한지 여부
  
  /// 현재 로그인된 사용자
  UserModel get user => _user ?? UserModel.createDefaultUser();
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;
  
  /// ViewModel이 여전히 유효한지 여부
  bool get mounted => _mounted;
  
  /// 로그인 여부
  bool get isLoggedIn => _user != null && _user!.uid.isNotEmpty;
  
  /// 현재 로그인된 사용자
  User? get currentUser {
    try {
      return _authRepository.currentUser;
    } catch (e) {
      debugPrint('currentUser 접근 중 오류: $e');
      return null;
    }
  }
  
  AuthViewModel({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    ApiKeyService? apiKeyService,
    RateLimiter? rateLimiter,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _apiKeyService = apiKeyService ?? ApiKeyService(),
        _rateLimiter = rateLimiter ?? RateLimiter() {
    _initialize();
  }
  
  /// ViewModel 초기화
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      // 현재 인증 상태 확인
      final currentUser = _authRepository.currentUser;
      
      if (currentUser != null) {
        // 사용자 정보 로드
        final userDoc = await _userRepository.getUserById(currentUser.uid);
        
        if (userDoc != null) {
          _user = userDoc;
        } else {
          // 사용자 문서가 없는 경우 새로 생성
          final newUser = UserModel(
            uid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? '',
            photoURL: currentUser.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _userRepository.createUser(newUser);
          _user = newUser;
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      _setError('초기화 중 오류 발생: $e');
      debugPrint('AuthViewModel 초기화 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일과 비밀번호로 로그인
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    if (!_rateLimiter.checkRequest('login')) {
      _setError('로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final userCredential = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
        await _updateLastLoginTime();
        return true;
      }
      
      return false;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일과 비밀번호로 회원가입
  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    if (!_rateLimiter.checkRequest('signup')) {
      _setError('회원가입 시도가 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final userCredential = await _authRepository.createUserWithEmailAndPassword(
        email,
        password,
      );
      
      if (userCredential.user != null) {
        // 사용자 프로필 업데이트
        await _authRepository.updateUserProfile(displayName: displayName);
        
        // 사용자 문서 생성
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          photoURL: null,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _userRepository.createUser(newUser);
        _user = newUser;
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Google 로그인
  Future<bool> signInWithGoogle() async {
    if (!_rateLimiter.checkRequest('google_login')) {
      _setError('로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final userCredential = await _authRepository.signInWithGoogle();
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // 새 사용자인 경우 문서 생성
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _userRepository.createUser(newUser);
          _user = newUser;
        } else {
          // 기존 사용자인 경우 정보 로드
          await _loadUserData(user.uid);
          await _updateLastLoginTime();
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Facebook 로그인
  Future<bool> signInWithFacebook() async {
    if (!_rateLimiter.checkRequest('facebook_login')) {
      _setError('로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final userCredential = await _authRepository.signInWithFacebook();
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // 새 사용자인 경우 문서 생성
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _userRepository.createUser(newUser);
          _user = newUser;
        } else {
          // 기존 사용자인 경우 정보 로드
          await _loadUserData(user.uid);
          await _updateLastLoginTime();
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 애플 로그인
  Future<bool> signInWithApple() async {
    if (!_rateLimiter.checkRequest('apple_login')) {
      _setError('로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final userCredential = await _authRepository.signInWithApple();
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // 새 사용자인 경우 문서 생성
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Apple User',
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _userRepository.createUser(newUser);
          _user = newUser;
        } else {
          // 기존 사용자인 경우 정보 로드
          await _loadUserData(user.uid);
          await _updateLastLoginTime();
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authRepository.signOut();
      _user = null;
      
      notifyListeners();
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다: $e');
      debugPrint('로그아웃 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 비밀번호 재설정 이메일 발송
  Future<bool> sendPasswordResetEmail(String email) async {
    if (!_rateLimiter.checkRequest('reset_password')) {
      _setError('비밀번호 재설정 요청이 너무 많습니다. 잠시 후 다시 시도하세요.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 프로필 업데이트
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return false;
    }
    
    _setLoading(true);
    
    try {
      // Firebase Auth 프로필 업데이트
      await _authRepository.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // DB의 사용자 문서 업데이트
      final updatedUser = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoURL: photoURL ?? _user!.photoURL,
      );
      
      await _userRepository.updateUser(updatedUser);
      _user = updatedUser;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('프로필 업데이트 중 오류가 발생했습니다: $e');
      debugPrint('프로필 업데이트 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 비밀번호 변경
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.email.isEmpty) {
      _setError('로그인이 필요합니다.');
      return false;
    }
    
    _setLoading(true);
    
    try {
      await _authRepository.changePassword(
        _user!.email,
        currentPassword,
        newPassword,
      );
      
      return true;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 사용자 계정 삭제
  Future<bool> deleteAccount(String password) async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return false;
    }
    
    _setLoading(true);
    
    try {
      // Firebase Auth 계정 삭제
      await _authRepository.deleteAccount(password);
      
      // DB에서 사용자 문서 삭제
      await _userRepository.deleteUser(_user!.uid);
      
      // 상태 초기화
      _user = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// API 키 설정
  Future<bool> setApiKey(String key) async {
    if (_user == null) {
      _setError('로그인이 필요합니다.');
      return false;
    }
    
    try {
      await _apiKeyService.setApiKey('gemini', key);
      return true;
    } catch (e) {
      _setError('API 키 저장 중 오류가 발생했습니다: $e');
      return false;
    }
  }
  
  /// 사용자 데이터 로드
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _userRepository.getUserById(uid);
      
      if (userData != null) {
        _user = userData;
      } else {
        // 사용자 문서가 없는 경우 Firebase Auth 정보로 생성
        final currentUser = _authRepository.currentUser;
        
        if (currentUser != null) {
          final newUser = UserModel(
            uid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? '',
            photoURL: currentUser.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _userRepository.createUser(newUser);
          _user = newUser;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 데이터 로드 오류: $e');
    }
  }
  
  /// 마지막 로그인 시간 업데이트
  Future<void> _updateLastLoginTime() async {
    if (_user == null) return;
    
    try {
      final updatedUser = _user!.copyWith(
        lastLoginAt: DateTime.now(),
      );
      
      await _userRepository.updateUser(updatedUser);
      _user = updatedUser;
      
      notifyListeners();
    } catch (e) {
      debugPrint('로그인 시간 업데이트 오류: $e');
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    if (_mounted) notifyListeners();
  }
  
  /// 오류 메시지 설정
  void _setError(String? error) {
    _error = error;
    if (_mounted) notifyListeners();
  }
  
  /// 인증 오류 처리
  void _handleAuthError(dynamic e) {
    String errorMessage = '알 수 없는 오류가 발생했습니다.';
    
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '등록되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 일치하지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다.';
          break;
        case 'operation-not-allowed':
          errorMessage = '이 로그인 방식은 현재 비활성화되어 있습니다.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = '다른 로그인 방식으로 이미 가입된 계정입니다.';
          break;
        case 'invalid-credential':
          errorMessage = '잘못된 인증 정보입니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도하세요.';
          break;
        default:
          errorMessage = '인증 오류: ${e.message}';
      }
    }
    
    _setError(errorMessage);
    debugPrint('AuthViewModel 오류: $e');
  }
  
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
} 