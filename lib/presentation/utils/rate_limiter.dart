import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// 요청 제한 관리 클래스
class RateLimiter {
  /// 각 서비스별 일일 요청 제한
  final Map<String, int> _dailyLimits = {
    'pdf_chat': 10,
    'pdf_summary': 5,
    'pdf_qa': 10,
    'pdf_translate': 20,
    'pdf_analyze': 5,
    'pdf_search': 15,
    'pdf_quiz': 3,
  };
  
  /// 각 서비스별 현재 요청 횟수
  final Map<String, int> _usageCounts = {};
  
  /// 마지막 리셋 시간
  DateTime? _lastResetTime;
  
  /// 기본 생성자
  RateLimiter() {
    _loadUsageCounts();
    _checkAndResetCounts();
  }
  
  /// 사용 횟수 로드
  Future<void> _loadUsageCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 마지막 리셋 시간 로드
      final lastResetTimeStr = prefs.getString('rate_limiter_last_reset');
      if (lastResetTimeStr != null) {
        _lastResetTime = DateTime.parse(lastResetTimeStr);
      }
      
      // 각 서비스별 사용 횟수 로드
      for (final service in _dailyLimits.keys) {
        final count = prefs.getInt('rate_limiter_$service') ?? 0;
        _usageCounts[service] = count;
      }
    } catch (e) {
      print('RateLimiter 사용 횟수 로드 오류: $e');
      
      // 오류 발생 시 기본값으로 설정
      _resetCounts();
    }
  }
  
  /// 사용 횟수 저장
  Future<void> _saveUsageCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 마지막 리셋 시간 저장
      if (_lastResetTime != null) {
        await prefs.setString('rate_limiter_last_reset', _lastResetTime!.toIso8601String());
      }
      
      // 각 서비스별 사용 횟수 저장
      for (final entry in _usageCounts.entries) {
        await prefs.setInt('rate_limiter_${entry.key}', entry.value);
      }
    } catch (e) {
      print('RateLimiter 사용 횟수 저장 오류: $e');
    }
  }
  
  /// 사용 횟수 리셋
  void _resetCounts() {
    for (final service in _dailyLimits.keys) {
      _usageCounts[service] = 0;
    }
    _lastResetTime = DateTime.now();
    _saveUsageCounts();
  }
  
  /// 일일 리셋 확인 및 수행
  void _checkAndResetCounts() {
    final now = DateTime.now();
    
    if (_lastResetTime == null) {
      _lastResetTime = now;
      _saveUsageCounts();
      return;
    }
    
    // 날짜가 변경된 경우 리셋
    if (_lastResetTime!.day != now.day || 
        _lastResetTime!.month != now.month || 
        _lastResetTime!.year != now.year) {
      _resetCounts();
    }
  }
  
  /// 요청 가능 여부 확인
  bool checkRequest(String service) {
    // 서비스가 존재하지 않는 경우
    if (!_dailyLimits.containsKey(service)) {
      return false;
    }
    
    _checkAndResetCounts();
    
    final currentCount = _usageCounts[service] ?? 0;
    final limit = _dailyLimits[service] ?? 0;
    
    // 제한 범위 내인 경우
    if (currentCount < limit) {
      _usageCounts[service] = currentCount + 1;
      _saveUsageCounts();
      return true;
    }
    
    return false;
  }
  
  /// 남은 요청 횟수 가져오기
  int getRemainingRequests(String service) {
    if (!_dailyLimits.containsKey(service)) {
      return 0;
    }
    
    _checkAndResetCounts();
    
    final currentCount = _usageCounts[service] ?? 0;
    final limit = _dailyLimits[service] ?? 0;
    
    return limit - currentCount;
  }
  
  /// 특정 서비스의 사용 제한 설정
  void setLimit(String service, int limit) {
    _dailyLimits[service] = limit;
  }
  
  /// 특정 서비스의 사용 횟수 증가
  void addUsage(String service, int count) {
    if (!_dailyLimits.containsKey(service)) {
      return;
    }
    
    final currentCount = _usageCounts[service] ?? 0;
    _usageCounts[service] = currentCount + count;
    _saveUsageCounts();
  }
  
  /// 모든 서비스 사용 횟수 리셋
  void resetAllCounts() {
    _resetCounts();
  }
  
  /// 특정 서비스의 사용 횟수 리셋
  void resetServiceCount(String service) {
    if (_usageCounts.containsKey(service)) {
      _usageCounts[service] = 0;
      _saveUsageCounts();
    }
  }
  
  /// 리소스 해제
  void dispose() {
    // 필요한 리소스 해제 작업 수행
  }
} 