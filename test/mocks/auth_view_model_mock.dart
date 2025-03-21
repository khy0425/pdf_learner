import 'package:flutter/foundation.dart';

/// 테스트용 User 모델
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;
  final DateTime? createdAt;
  final String? apiKey;
  
  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified,
    this.createdAt,
    this.apiKey,
  });
  
  /// 기본 사용자 모델 생성
  factory UserModel.createDefaultUser() {
    return UserModel(
      uid: '',
      email: '',
      displayName: '',
    );
  }
  
  /// 불변 객체로 사용하기 위한 복사 메서드
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    DateTime? createdAt,
    String? apiKey,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

/// 테스트용 AuthViewModel 모의 클래스
class MockAuthViewModel extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = true;
  
  /// 현재 로그인된 사용자
  UserModel get user => _user ?? UserModel.createDefaultUser();
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;
  
  /// 로그인 여부
  bool get isLoggedIn => _user != null && _user!.uid.isNotEmpty;
  
  MockAuthViewModel() {
    _user = UserModel.createDefaultUser();
  }
  
  /// 테스트 오류 설정 (테스트용)
  void setTestError(String error) {
    _error = error;
    notifyListeners();
  }
  
  /// 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// 테스트용 모의 로그인
  Future<void> mockSignIn({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    // 비동기 작업 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    _user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
    );
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// 테스트용 모의 로그아웃
  Future<void> mockSignOut() async {
    _isLoading = true;
    notifyListeners();
    
    // 비동기 작업 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    _user = UserModel.createDefaultUser();
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// API 키 설정 (테스트용)
  Future<void> mockSetApiKey(String apiKey) async {
    _isLoading = true;
    notifyListeners();
    
    // 비동기 작업 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    
    _user = user.copyWith(apiKey: apiKey);
    
    _isLoading = false;
    notifyListeners();
    
    return;
  }
  
  /// API 키 가져오기 (테스트용)
  Future<String?> getApiKey() async {
    return user.apiKey;
  }
} 