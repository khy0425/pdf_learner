import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('인증 상태 변경: ${firebaseUser?.uid}');
    
    if (firebaseUser == null) {
      debugPrint('사용자가 로그아웃됨');
      _user = null;
      notifyListeners();
      return;
    }
    
    try {
      // 로딩 상태 설정
      _setLoading(true);
      
      // 사용자 데이터 조회 시도
      UserModel? userData;
      try {
        userData = await _userRepository.getUser(firebaseUser.uid);
        debugPrint('사용자 데이터 조회 결과: ${userData?.uid}');
      } catch (e) {
        debugPrint('사용자 데이터 조회 실패: $e');
        // 조회 실패 시 기본 사용자 모델 생성
        userData = _createDefaultUserModel(firebaseUser);
      }
      
      if (userData != null) {
        debugPrint('기존 사용자 정보 로드');
        _user = userData;
      } else {
        debugPrint('신규 사용자 정보 생성');
        
        // 기본값 설정
        String displayName = firebaseUser.displayName ?? '';
        if (displayName.isEmpty && firebaseUser.email != null) {
          displayName = firebaseUser.email!.split('@')[0];
        }
        if (displayName.isEmpty) {
          displayName = '사용자';
        }
        
        try {
          // 새 사용자 모델 생성
          final newUser = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: displayName,
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
            maxPdfsPerDay: 5,
            maxPdfsPerMonth: 100,
            maxPdfsPerYear: 1000,
            maxPdfsPerLifetime: 10000,
            maxPdfsTotal: 20,
            maxPdfSize: 5 * 1024 * 1024, // 5MB
            maxPdfPages: 50,
            maxUsagePerDay: 10,
            maxTextLength: 10000,
            usageCount: 0,
            lastUsageAt: DateTime.now(),
          );
          
          // Firestore에 새 사용자 정보 저장 시도
          try {
            await _userRepository.saveUser(newUser);
            debugPrint('신규 사용자 정보 저장 완료: ${newUser.uid}');
            _user = newUser;
          } catch (e) {
            debugPrint('신규 사용자 정보 저장 실패: $e');
            // 저장 실패 시에도 메모리에는 유지
            _user = newUser;
          }
        } catch (e) {
          debugPrint('사용자 모델 생성 오류: $e');
          // 기본 사용자 모델 생성
          _user = _createDefaultUserModel(firebaseUser);
        }
      }
      
      // 오류 초기화
      _error = null;
      
    } catch (e) {
      debugPrint('사용자 정보 로드 오류: $e');
      _error = '사용자 정보를 로드하는 중 오류가 발생했습니다.';
      
      // 오류 발생 시 기본 사용자 모델 생성
      if (firebaseUser != null) {
        _user = _createDefaultUserModel(firebaseUser);
      }
    } finally {
      // 로딩 상태 해제
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Google로 로그인
  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      
      await _authRepository.signInWithGoogle();
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Google 로그인 오류: ${e.code}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      throw _error!;
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      _error = '구글 로그인 중 오류가 발생했습니다: $e';
      notifyListeners();
      throw _error!;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _authRepository.signInWithEmailPassword(email, password);
      
    } on FirebaseAuthException catch (e) {
      debugPrint('이메일 로그인 오류: ${e.code}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      throw _error!;
    } catch (e) {
      debugPrint('이메일 로그인 오류: $e');
      _error = '로그인 중 오류가 발생했습니다: $e';
      notifyListeners();
      throw _error!;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      
      final userCredential = await _authRepository.signUpWithEmailPassword(email, password);
      
      // 사용자 정보 저장
      if (userCredential.user != null) {
        final displayName = email.split('@')[0];
        
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          photoURL: null,
          emailVerified: false,
          createdAt: DateTime.now(),
          subscriptionTier: 'free',
          maxPdfTextLength: 50000,
          maxPdfTextLengthPerPage: 1000,
          maxPdfTextLengthPerDay: 100000,
          maxPdfTextLengthPerMonth: 1000000,
          maxPdfTextLengthPerYear: 10000000,
          maxPdfTextLengthPerLifetime: 100000000,
          maxPdfsPerDay: 5,
          maxPdfsPerMonth: 100,
          maxPdfsPerYear: 1000,
          maxPdfsPerLifetime: 10000,
          maxPdfsTotal: 20,
          maxPdfSize: 5 * 1024 * 1024, // 5MB
          maxPdfPages: 50,
          maxUsagePerDay: 10,
          maxTextLength: 10000,
          usageCount: 0,
          lastUsageAt: DateTime.now(),
        );
        
        try {
          await _userRepository.saveUser(newUser);
          debugPrint('회원가입 후 사용자 정보 저장 완료: ${newUser.uid}');
        } catch (e) {
          debugPrint('회원가입 후 사용자 정보 저장 실패: $e');
          // 저장 실패 시에도 계속 진행 (Firebase Auth 리스너에서 다시 시도)
        }
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('회원가입 오류: ${e.code}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      throw _error!;
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      _error = '회원가입 중 오류가 발생했습니다: $e';
      notifyListeners();
      throw _error!;
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
  
  /// 오류 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Firebase 인증 오류 메시지 변환
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return '유효하지 않은 이메일 주소입니다.';
      case 'user-disabled':
        return '이 계정은 비활성화되었습니다.';
      case 'user-not-found':
        return '등록되지 않은 이메일 주소입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일 주소입니다.';
      case 'operation-not-allowed':
        return '이 로그인 방식은 현재 허용되지 않습니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 사용해주세요.';
      case 'network-request-failed':
        return '네트워크 연결에 문제가 있습니다. 인터넷 연결을 확인해주세요.';
      case 'too-many-requests':
        return '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'account-exists-with-different-credential':
        return '이 이메일은 다른 로그인 방식으로 이미 등록되어 있습니다.';
      case 'popup-closed-by-user':
        return '로그인 창이 닫혔습니다. 다시 시도해주세요.';
      default:
        return '인증 오류가 발생했습니다: $errorCode';
    }
  }
  
  /// 기본 사용자 모델 생성
  UserModel _createDefaultUserModel(User? firebaseUser) {
    return UserModel(
      uid: firebaseUser!.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '사용자',
      photoURL: null,
      emailVerified: false,
      createdAt: DateTime.now(),
      subscriptionTier: 'free',
      maxPdfTextLength: 50000,
      maxPdfTextLengthPerPage: 1000,
      maxPdfTextLengthPerDay: 100000,
      maxPdfTextLengthPerMonth: 1000000,
      maxPdfTextLengthPerYear: 10000000,
      maxPdfTextLengthPerLifetime: 100000000,
      maxPdfsPerDay: 5,
      maxPdfsPerMonth: 100,
      maxPdfsPerYear: 1000,
      maxPdfsPerLifetime: 10000,
      maxPdfsTotal: 20,
      maxPdfSize: 5 * 1024 * 1024,
      maxPdfPages: 50,
      maxUsagePerDay: 10,
      maxTextLength: 10000,
      usageCount: 0,
      lastUsageAt: DateTime.now(),
    );
  }
} 