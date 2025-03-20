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
  }) : _authRepository = authRepository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _apiKeyService = apiKeyService ?? ApiKeyService() {
    _initializeAuthState();
    
    // Firebase Auth 상태 변경 리스너 추가
    try {
      _authRepository.authStateChanges.listen((firebaseUser) {
        debugPrint('Firebase Auth 상태 변경: ${firebaseUser?.uid}');
        _onAuthStateChanged(firebaseUser);
      });
    } catch (e) {
      debugPrint('Auth 상태 변경 리스너 등록 오류: $e');
      // 리스너 등록 실패 시에도 기본 상태 설정
      _user = UserModel.createDefaultUser();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// 인증 상태 초기화
  Future<void> _initializeAuthState() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 현재 인증된 사용자 확인
      final firebaseUser = _authRepository.currentUser;
      
      if (firebaseUser != null) {
        debugPrint('인증 상태 초기화: 사용자 발견 - ${firebaseUser.uid}');
        await _onAuthStateChanged(firebaseUser);
      } else {
        debugPrint('인증 상태 초기화: 사용자 없음');
        // 기본 사용자 모델 생성 (게스트 모드)
        _user = UserModel.createDefaultUser();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('인증 상태 초기화 오류: $e');
      _error = '인증 상태를 초기화하는 중 오류가 발생했습니다.';
      // 오류 발생 시에도 기본 사용자 모델 생성
      _user = UserModel.createDefaultUser();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
    
    // 인증 상태 변경 리스너 등록
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }
  
  /// 인증 상태 변경 처리
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('인증 상태 변경: ${firebaseUser?.uid ?? 'null'}');
    
    try {
      // 로딩 상태 설정 전에 현재 객체가 유효한지 확인
      if (!mounted) {
        debugPrint('인증 상태 변경 처리 중 ViewModel이 disposed 상태');
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      if (firebaseUser == null) {
        debugPrint('사용자가 로그아웃됨');
        _user = UserModel.createDefaultUser();
        _error = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final uid = firebaseUser.uid;
      
      // 사용자 데이터 가져오기
      UserModel? userModel;
      try {
        userModel = await _userRepository.getUser(uid);
        debugPrint('사용자 데이터 조회 결과: ${userModel != null ? "성공" : "실패"}');
      } catch (e) {
        debugPrint('사용자 데이터 가져오기 실패: $e');
        userModel = null;
      }
      
      // 객체가 여전히 유효한지 다시 확인
      if (!mounted) {
        debugPrint('사용자 데이터 로드 후 ViewModel이 disposed 상태');
        return;
      }
      
      // 사용자 데이터가 없으면 새로 생성
      if (userModel == null) {
        debugPrint('새 사용자 생성: $uid');
        
        try {
          userModel = UserModel(
            uid: uid,
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
        } catch (e) {
          debugPrint('UserModel 생성 중 오류 발생: $e');
          userModel = UserModel.createDefaultUser();
        }
        
        // 새 사용자 저장
        try {
          if (!mounted) return;
          await _userRepository.saveUser(userModel);
          debugPrint('새 사용자 저장 완료');
        } catch (e) {
          debugPrint('새 사용자 저장 실패: $e');
          // 저장 실패 시에도 계속 진행
        }
      } else {
        debugPrint('기존 사용자 데이터 로드: ${userModel.uid}');
      }
      
      if (!mounted) return;
      _user = userModel;
      _error = null;
    } catch (e) {
      debugPrint('사용자 데이터 가져오기 오류: $e');
      
      if (!mounted) return;
      _error = '사용자 데이터를 가져오는 중 오류가 발생했습니다.';
      
      // 오류 발생 시 기본 사용자 모델 생성
      if (firebaseUser != null) {
        final safeUid = firebaseUser.uid;
        
        try {
          _user = UserModel(
            uid: safeUid,
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
        } catch (e) {
          debugPrint('오류 처리 중 UserModel 생성 실패: $e');
          _user = UserModel.createDefaultUser();
        }
      } else {
        _user = UserModel.createDefaultUser();
      }
    } finally {
      if (mounted) {
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    }
  }
  
  /// Google로 로그인
  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      
      // 웹 환경에서는 리디렉트 처리로 인해 UserCredential 대신 void를 반환할 수 있음
      final userCredential = await _authRepository.signInWithGoogle();
      // 사용자가 성공적으로 로그인한 경우, 상태 업데이트는 authStateChanges에서 처리됨
      debugPrint('구글 로그인 성공: ${userCredential.user?.uid}');
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Google 로그인 오류: ${e.code}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      _error = '구글 로그인 중 오류가 발생했습니다: $e';
      notifyListeners();
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
    } catch (e) {
      debugPrint('이메일 로그인 오류: $e');
      _error = '로그인 중 오류가 발생했습니다: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmailPassword(String email, String password, {String? geminiApiKey}) async {
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
          apiKey: geminiApiKey,
        );
        
        try {
          await _userRepository.saveUser(newUser);
          debugPrint('회원가입 후 사용자 정보 저장 완료: ${newUser.uid}');
          
          // Gemini API 키가 제공된 경우 저장
          if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
            await _apiKeyService.saveApiKey(newUser.uid, geminiApiKey);
            debugPrint('Gemini API 키 저장 완료');
          }
          
          // 사용자 모델 업데이트
          _user = newUser;
          notifyListeners();
        } catch (e) {
          debugPrint('회원가입 후 사용자 정보 저장 실패: $e');
          // 저장 실패 시에도 계속 진행 (Firebase Auth 리스너에서 다시 시도)
        }
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('회원가입 오류: ${e.code}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      _error = '회원가입 중 오류가 발생했습니다: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      await _authRepository.signOut();
      _user = UserModel.createDefaultUser();
      notifyListeners();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      _setError('로그아웃에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// API 키 업데이트
  Future<void> updateApiKey(String apiKey) async {
    if (!mounted) return;
    
    try {
      _setLoading(true);
      
      // 사용자 객체가 null인 경우 안전하게 처리
      if (_user == null) {
        _setError('로그인이 필요합니다.');
        return;
      }
      
      final userId = _user!.uid;
      if (userId.isEmpty) {
        _setError('유효하지 않은 사용자입니다.');
        return;
      }
      
      // API 키 저장
      await _apiKeyService.saveApiKey(userId, apiKey);
      
      // 사용자 객체 업데이트 전 다시 확인
      if (_user == null || !mounted) return;
      
      try {
        _user = _user!.copyWith(apiKey: apiKey);
      } catch (e) {
        debugPrint('사용자 모델 업데이트 중 오류: $e');
        // 모델 업데이트 실패 시에도 API 키는 저장됨
      }
      
      if (mounted) notifyListeners();
    } catch (e) {
      if (!mounted) return;
      debugPrint('API 키 업데이트 오류: $e');
      _setError('API 키 업데이트에 실패했습니다.');
    } finally {
      if (mounted) _setLoading(false);
    }
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey() async {
    if (!mounted) return null;
    
    try {
      // 사용자 객체가 null인 경우
      if (_user == null) return null;
      
      final userId = _user!.uid;
      if (userId.isEmpty) return null;
      
      // 이미 모델에 API 키가 있으면 바로 반환
      if (_user!.apiKey != null && _user!.apiKey!.isNotEmpty) {
        return _user!.apiKey;
      }
      
      // API 키 서비스에서 가져오기
      final apiKey = await _apiKeyService.getApiKey(userId);
      
      // 모델 업데이트 (필요한 경우)
      if (apiKey != null && apiKey.isNotEmpty && _user != null && mounted) {
        try {
          _user = _user!.copyWith(apiKey: apiKey);
          notifyListeners();
        } catch (e) {
          debugPrint('API 키로 사용자 모델 업데이트 중 오류: $e');
          // 모델 업데이트 실패 시에도 API 키는 반환
        }
      }
      
      return apiKey;
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
  
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
} 