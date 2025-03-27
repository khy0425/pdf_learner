import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인증 상태 열거형
enum AuthStatus {
  initial,       // 초기 상태
  loading,       // 로딩 중
  authenticated, // 인증됨
  guest,         // 게스트 모드
  unauthenticated, // 인증되지 않음
  error,         // 오류 발생
}

/// 인증 뷰모델
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserModel? _currentUser;
  String? _error;
  bool _isGuestMode = false;
  bool _isLoading = false;

  // 미회원 사용자의 기능 사용 횟수 관련 변수
  int _summarizeUsageCount = 1; // 요약 기능 사용 가능 횟수
  int _chatUsageCount = 3; // PDF 대화 기능 사용 가능 횟수
  int _quizUsageCount = 0; // 퀴즈 생성 기능 사용 가능 횟수
  int _mindmapUsageCount = 0; // 마인드맵 생성 기능 사용 가능 횟수
  int _pdfOpenCount = 3; // PDF 열기 가능 횟수

  // SharedPreferences 키 상수
  static const String _guestKey = 'guest_mode';
  static const String _pdfOpenCountKey = 'pdf_open_count';
  static const String _summarizeUsageKey = 'summarize_usage';
  static const String _chatUsageKey = 'chat_usage';
  static const String _quizUsageKey = 'quiz_usage';
  static const String _mindmapUsageKey = 'mindmap_usage';

  AuthViewModel(this._authRepository) {
    _init();
  }
  
  /// 현재 로그인된 사용자
  UserModel? get currentUser => _currentUser;
  
  /// 인증 오류 메시지
  String? get error => _error;
  
  /// 게스트 모드 상태
  bool get isGuestMode => _status == AuthStatus.guest;
  
  /// 로그인된 상태 (일반 또는 게스트)
  bool get isAuthenticated => _status == AuthStatus.authenticated || _status == AuthStatus.guest;
  
  /// 로그인되지 않은 상태
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  
  /// 로딩 상태
  bool get isLoading => _status == AuthStatus.loading;
  
  /// 오류 상태
  bool get hasError => _status == AuthStatus.error;
  
  /// 오류 상태
  bool get isError => _status == AuthStatus.error;
  
  // 미회원 사용자의 기능 사용 횟수 게터
  int get summarizeUsageCount => _summarizeUsageCount;
  int get chatUsageCount => _chatUsageCount;
  int get quizUsageCount => _quizUsageCount;
  int get mindmapUsageCount => _mindmapUsageCount;
  int get pdfOpenCount => _pdfOpenCount;
  
  // 미회원 사용자의 기능 사용 가능 여부 확인
  bool get canUseSummarize => !isGuestMode || _summarizeUsageCount > 0;
  bool get canUseChat => !isGuestMode || _chatUsageCount > 0;
  bool get canUseQuiz => !isGuestMode || _quizUsageCount > 0;
  bool get canUseMindmap => !isGuestMode || _mindmapUsageCount > 0;
  bool get canOpenPdf => !isGuestMode || _pdfOpenCount > 0;
  
  void _init() {
    _isLoading = true;
    notifyListeners();

    try {
      // Firebase Auth 상태 변경 감지
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '사용자',
            photoURL: user.photoURL ?? '',
            settings: UserSettings.createDefault(),
          );
          
          _isGuestMode = user.isAnonymous;
          
          _status = AuthStatus.authenticated;
        } else if (_isGuestMode) {
          _currentUser = UserModel.guest();
          _status = AuthStatus.guest;
        } else {
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
        }
        
        _error = null;
        _isLoading = false;
        notifyListeners();
      });

      // 저장된 게스트 정보 불러오기
      _loadGuestInfo();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signIn(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signUp(email, password);
      await updateProfile(displayName: displayName);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signInAnonymously() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.signInAnonymously();
      
      _status = AuthStatus.guest;
      _currentUser = UserModel.guest();
      _error = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      
      if (e.toString().contains('operation-not-allowed')) {
        _error = '익명 로그인이 비활성화되어 있습니다. Firebase 콘솔에서 익명 로그인을 활성화해주세요.';
      } else {
        _error = e.toString();
      }
      
      notifyListeners();
      
      debugPrint('익명 로그인 에러: $e');
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_error != null) {
          _status = AuthStatus.unauthenticated;
          _error = null;
          notifyListeners();
        }
      });
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authRepository.signInWithGoogle();
      final user = userCredential.user;
      
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '사용자',
          photoURL: user.photoURL ?? '',
          settings: UserSettings.createDefault(),
        );
        _isGuestMode = false;
        _error = null;
      } else {
        _error = '구글 로그인이 취소되었습니다.';
      }
    } catch (e) {
      _error = '구글 로그인 중 오류가 발생했습니다: ${e.toString()}';
      debugPrint('Google 로그인 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.resetPassword(email);
      _status = _user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Firebase에서 로그아웃
      await _auth.signOut();
      
      // 게스트 모드로 전환
      _isGuestMode = true;
      _currentUser = UserModel.guest();
      _status = AuthStatus.guest;
      
      // 게스트 정보 저장
      await _saveGuestInfo();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = _user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // 기능 사용 횟수 차감
  void useSummarize() {
    if (isGuestMode && _summarizeUsageCount > 0) {
      _summarizeUsageCount--;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  void useChat() {
    if (isGuestMode && _chatUsageCount > 0) {
      _chatUsageCount--;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  void useQuiz() {
    if (isGuestMode && _quizUsageCount > 0) {
      _quizUsageCount--;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  void useMindmap() {
    if (isGuestMode && _mindmapUsageCount > 0) {
      _mindmapUsageCount--;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  void usePdfOpen() {
    if (isGuestMode && _pdfOpenCount > 0) {
      _pdfOpenCount--;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  // 광고 시청으로 기능 사용 횟수 추가
  void addUsageCountFromAd() {
    if (isGuestMode) {
      _summarizeUsageCount += 1;
      _chatUsageCount += 3;
      _quizUsageCount += 1;
      _mindmapUsageCount += 1;
      _pdfOpenCount += 2;
      _saveGuestInfo();
      notifyListeners();
    }
  }
  
  // 상태 초기화 (로그아웃 시 호출)
  void resetUsageCounts() {
    if (isGuestMode) {
      _summarizeUsageCount = 1;
      _chatUsageCount = 3;
      _quizUsageCount = 0;
      _mindmapUsageCount = 0;
      _pdfOpenCount = 3;
      notifyListeners();
    }
  }

  // 광고 시청 후 보상 제공
  Future<void> rewardAfterAd() async {
    if (isGuestMode) {
      _summarizeUsageCount += 1;
      _chatUsageCount += 1;
      _quizUsageCount += 1;
      _mindmapUsageCount += 1;
      await _saveGuestInfo();
      notifyListeners();
    }
  }

  // 게스트 정보 저장
  Future<void> _saveGuestInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, _isGuestMode);
    await prefs.setInt(_pdfOpenCountKey, _pdfOpenCount);
    await prefs.setInt(_summarizeUsageKey, _summarizeUsageCount);
    await prefs.setInt(_chatUsageKey, _chatUsageCount);
    await prefs.setInt(_quizUsageKey, _quizUsageCount);
    await prefs.setInt(_mindmapUsageKey, _mindmapUsageCount);
  }

  // 게스트 정보 불러오기
  Future<void> _loadGuestInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuestMode = prefs.getBool(_guestKey) ?? false;
    _pdfOpenCount = prefs.getInt(_pdfOpenCountKey) ?? 3;
    _summarizeUsageCount = prefs.getInt(_summarizeUsageKey) ?? 1;
    _chatUsageCount = prefs.getInt(_chatUsageKey) ?? 3;
    _quizUsageCount = prefs.getInt(_quizUsageKey) ?? 0;
    _mindmapUsageCount = prefs.getInt(_mindmapUsageKey) ?? 0;
    notifyListeners();
  }

  // 게스트 모드로 전환
  Future<void> switchToGuestMode() async {
    _isGuestMode = true;
    _currentUser = null;
    await _saveGuestInfo();
    notifyListeners();
  }

  // 로그인 페이지로 이동하기 전에 호출할 메서드
  Future<void> prepareForLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 현재 로그인 상태 확인
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // 이미 로그인된 상태면 로그아웃
        await signOut();
      } else if (_isGuestMode) {
        // 게스트 모드면 게스트 정보만 초기화
        _isGuestMode = false;
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        await _saveGuestInfo();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}