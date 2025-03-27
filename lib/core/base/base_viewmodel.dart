import 'package:flutter/foundation.dart';

/// 뷰모델 상태 열거형
enum ViewModelState {
  initial,
  loading,
  loaded,
  error,
  disposed
}

/// 기본 뷰모델 클래스
/// 모든 뷰모델의 기본 기능을 제공하는 추상 클래스입니다.
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  /// 현재 뷰모델의 상태
  ViewModelState get state => _isLoading ? ViewModelState.loading : ViewModelState.initial;
  
  /// 로딩 상태 여부
  bool get isLoading => _isLoading;
  
  /// 오류 발생 여부
  bool get hasError => _hasError;
  
  /// 오류 메시지
  String get errorMessage => _errorMessage;
  
  /// 로딩 상태로 설정
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }
  
  /// 로딩 완료 상태로 설정
  void setLoaded() {
    _isLoading = false;
    notifyListeners();
  }
  
  /// 오류 상태로 설정
  void setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('오류 발생: $message');
    }
  }
  
  /// 상태 초기화
  void resetState() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
  
  /// 오류 메시지 초기화
  void clearError() {
    _errorMessage = '';
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';
    super.dispose();
  }
} 