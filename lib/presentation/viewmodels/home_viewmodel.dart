import 'package:flutter/foundation.dart';

import 'auth_viewmodel.dart';

class HomeViewModel with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  final AuthViewModel? _authViewModel;

  HomeViewModel({AuthViewModel? authViewModel}) 
    : _authViewModel = authViewModel;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;

  // 사용자 이름 가져오기
  String getUserDisplayName() {
    if (_authViewModel == null || !_authViewModel!.isLoggedIn) {
      return "게스트";
    }
    return _authViewModel!.user?.displayName ?? "사용자";
  }

  // 로딩 상태 설정
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 메시지 설정
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 선택된 탭 변경
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
  
  // 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 