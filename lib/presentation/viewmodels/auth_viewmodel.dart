import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../core/base/base_viewmodel.dart';
import '../../core/models/result.dart';
import '../../services/firebase_service.dart';
import '../../domain/models/user_model.dart';

/// 인증 상태
enum AuthStatus {
  /// 초기 상태
  initial,
  
  /// 인증 중
  authenticating,
  
  /// 인증됨
  authenticated,
  
  /// 인증 오류
  error,
  
  /// 로그아웃됨
  unauthenticated
}

/// 인증 관리 ViewModel
@injectable
class AuthViewModel extends BaseViewModel {
  /// Firebase 서비스
  final FirebaseService _firebaseService;
  
  /// 인증 상태
  AuthStatus _status = AuthStatus.initial;
  
  /// 현재 사용자
  User? _currentUser;
  
  /// 오류 메시지
  String _errorMessage = '';
  
  /// 게스트 모드 여부
  bool _isGuestMode = false;
  
  /// AI 기능 사용 횟수
  int _summarizeUsageCount = 3;
  int _chatUsageCount = 3;
  int _quizUsageCount = 1;
  int _mindmapUsageCount = 1;
  int _pdfOpenCount = 5;
  
  /// 생성자
  AuthViewModel({
    required FirebaseService firebaseService,
  }) : _firebaseService = firebaseService {
    checkAuthState();
    _loadUsageCounts();
  }
  
  /// 인증 상태 getter
  AuthStatus get status => _status;
  
  /// 현재 사용자 getter
  User? get currentUser => _currentUser;
  
  /// 오류 메시지 getter
  String get errorMessage => _errorMessage;
  
  /// 오류 메시지 getter (별칭)
  String? get error => _errorMessage.isEmpty ? null : _errorMessage;
  
  /// 사용자 인증 여부
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  
  /// 게스트 모드 여부
  bool get isGuestMode => _isGuestMode;
  
  /// 게스트 모드 설정
  set isGuestMode(bool value) {
    _isGuestMode = value;
    notifyListeners();
  }
  
  /// AI 기능 사용 횟수 getter
  int get summarizeUsageCount => _summarizeUsageCount;
  int get chatUsageCount => _chatUsageCount;
  int get quizUsageCount => _quizUsageCount;
  int get mindmapUsageCount => _mindmapUsageCount;
  int get pdfOpenCount => _pdfOpenCount;
  
  /// PDF 열기 가능 여부
  bool get canOpenPdf => !_isGuestMode || _pdfOpenCount > 0;
  
  /// AI 기능 사용 가능 여부
  bool get canUseSummarize => !_isGuestMode || _summarizeUsageCount > 0;
  bool get canUseChat => !_isGuestMode || _chatUsageCount > 0;
  bool get canUseQuiz => !_isGuestMode || _quizUsageCount > 0;
  bool get canUseMindmap => !_isGuestMode || _mindmapUsageCount > 0;
  
  /// 에러 상태
  bool get hasError => _errorMessage.isNotEmpty;
  
  /// 인증 상태 설정
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String message) {
    _errorMessage = message;
    _setStatus(AuthStatus.error);
  }
  
  /// 오류 지우기
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  /// 인증 상태 확인
  Future<void> checkAuthState() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _currentUser = user;
      _isGuestMode = false;
      _setStatus(AuthStatus.authenticated);
    } else {
      _setStatus(AuthStatus.unauthenticated);
    }
  }
  
  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setStatus(AuthStatus.authenticating);
      
      final result = await _firebaseService.signInWithEmailAndPassword(email, password);
      
      if (result.isSuccess) {
        _currentUser = result.getOrNull();
        _isGuestMode = false;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setError(result.error.toString());
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _setStatus(AuthStatus.authenticating);
      
      final result = await _firebaseService.signUpWithEmailAndPassword(email, password);
      
      if (result.isSuccess) {
        _currentUser = result.getOrNull();
        _isGuestMode = false;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setError(result.error.toString());
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 구글로 로그인
  Future<void> signInWithGoogle() async {
    try {
      _setStatus(AuthStatus.authenticating);
      
      final result = await _firebaseService.signInWithGoogle();
      
      if (result.isSuccess) {
        _currentUser = result.getOrNull();
        _isGuestMode = false;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setError(result.error.toString());
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 게스트 모드로 로그인
  Future<void> signInAsGuest() async {
    try {
      _isGuestMode = true;
      _currentUser = null;
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 익명으로 로그인
  Future<void> signInAnonymously() async {
    try {
      _setStatus(AuthStatus.authenticating);
      
      final result = await _firebaseService.signInAnonymously();
      
      if (result.isSuccess) {
        _currentUser = result.getOrNull();
        _isGuestMode = true; // 익명 로그인은 게스트 모드로 취급
        _setStatus(AuthStatus.authenticated);
      } else {
        _setError(result.error.toString());
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _currentUser = null;
      _isGuestMode = false;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// AI 기능 사용
  void useSummarize() {
    if (_isGuestMode && _summarizeUsageCount > 0) {
      _summarizeUsageCount--;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  void useChat() {
    if (_isGuestMode && _chatUsageCount > 0) {
      _chatUsageCount--;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  void useQuiz() {
    if (_isGuestMode && _quizUsageCount > 0) {
      _quizUsageCount--;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  void useMindmap() {
    if (_isGuestMode && _mindmapUsageCount > 0) {
      _mindmapUsageCount--;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  void usePdfOpen() {
    if (_isGuestMode && _pdfOpenCount > 0) {
      _pdfOpenCount--;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  /// 광고 시청 후 사용량 충전
  Future<void> rewardAfterAd() async {
    if (_isGuestMode) {
      _summarizeUsageCount += 1;
      _chatUsageCount += 1;
      _quizUsageCount += 1;
      _mindmapUsageCount += 1;
      _pdfOpenCount += 2;
      _saveUsageCounts();
      notifyListeners();
    }
  }
  
  /// 광고 시청 후 사용량 충전 (내부 구현)
  Future<void> addUsageCountFromAd() async {
    await rewardAfterAd();
  }
  
  /// 사용자 정보 설정을 위한 로그인 준비
  Future<void> prepareForLogin() async {
    _setStatus(AuthStatus.initial);
  }
  
  /// 사용량 저장
  Future<void> _saveUsageCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('summarize_usage', _summarizeUsageCount);
      await prefs.setInt('chat_usage', _chatUsageCount);
      await prefs.setInt('quiz_usage', _quizUsageCount);
      await prefs.setInt('mindmap_usage', _mindmapUsageCount);
      await prefs.setInt('pdf_open', _pdfOpenCount);
    } catch (e) {
      debugPrint('사용량 저장 오류: $e');
    }
  }
  
  /// 사용량 불러오기
  Future<void> _loadUsageCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _summarizeUsageCount = prefs.getInt('summarize_usage') ?? 3;
      _chatUsageCount = prefs.getInt('chat_usage') ?? 3;
      _quizUsageCount = prefs.getInt('quiz_usage') ?? 1;
      _mindmapUsageCount = prefs.getInt('mindmap_usage') ?? 1;
      _pdfOpenCount = prefs.getInt('pdf_open') ?? 5;
      notifyListeners();
    } catch (e) {
      debugPrint('사용량 불러오기 오류: $e');
    }
  }

  /// 로그인 상태 여부
  bool get isLoggedIn => _currentUser != null;
} 