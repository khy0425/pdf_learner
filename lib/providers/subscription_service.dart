import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/device_fingerprint.dart'; // 디바이스 지문 유틸리티 추가

// 구독 플랜 열거형
enum SubscriptionPlan {
  free,      // 무료 사용자
  basic,     // 베이직 플랜 ($4.99/월)
  premium,   // 프리미엄 플랜 ($9.99/월)
}

// 무료 체험 상태
enum TrialStatus {
  notStarted,  // 무료 체험 시작 전
  active,      // 무료 체험 중
  expired,     // 무료 체험 종료됨
}

/// PDF Learner 앱의 구독 관리 서비스
/// providers/subscription_service.dart에 위치
class SubscriptionService with ChangeNotifier {
  // 안전한 실행을 위해 FirebaseFirestore를 메서드 내에서 사용합니다
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  // 서비스 상태 관리
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  DateTime? _expiryDate;
  String _userId = 'anonymous'; // 기본값은 'anonymous'
  bool _isLoading = false;
  
  // 무료 체험 관련 변수
  TrialStatus _trialStatus = TrialStatus.notStarted;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;
  
  // 미회원 사용 관련 변수
  int _guestUsageCount = 0;
  final int _maxGuestUsage = 3;  // 미회원 최대 사용 횟수
  String _deviceId = ''; // 디바이스 ID 저장

  // Getter 메서드들
  SubscriptionPlan get currentPlan => _currentPlan;
  DateTime? get expiryDate => _expiryDate;
  bool get isLoading => _isLoading;
  String get deviceId => _deviceId;
  String get userId => _userId;
  
  // 유료 사용자 여부 확인
  bool get isPaidUser {
    final result = _currentPlan != SubscriptionPlan.free;
    if (kDebugMode) {
      print('[SubscriptionService] isPaidUser 호출됨: $result (현재 플랜: $_currentPlan)');
    }
    return result;
  }
  
  // 프리미엄 사용자 여부 확인
  bool get isPremiumUser => _currentPlan == SubscriptionPlan.premium;
  
  // 크로스 디바이스 지원 기능 사용 가능 여부
  bool get hasCrossDeviceSupport => isPaidUser;
  
  // 무료 체험 관련 getter
  TrialStatus get trialStatus => _trialStatus;
  DateTime? get trialEndDate => _trialEndDate;
  bool get isTrialActive => _trialStatus == TrialStatus.active;
  
  // 미회원 사용 관련 getter
  int get guestUsageCount => _guestUsageCount;
  int get maxGuestUsage => _maxGuestUsage;
  bool get canUseAsGuest => _guestUsageCount < _maxGuestUsage;
  
  // 생성자에서 미회원 사용 횟수 로드 및 디바이스 지문 초기화
  SubscriptionService() {
    if (kDebugMode) {
      print('[SubscriptionService] 초기화됨');
    }
    
    // 테스트용 기본 플랜 설정 (개발 중에만)
    if (kDebugMode) {
      // 디버그 모드에서는 기본적으로 무료 플랜으로 설정
      _currentPlan = SubscriptionPlan.free;
    }
    
    _initializeDeviceFingerprint();
  }
  
  // 디바이스 지문 초기화
  Future<void> _initializeDeviceFingerprint() async {
    try {
      // 디바이스 ID 가져오기
      _deviceId = await DeviceFingerprint.instance.getDeviceId();
      
      // 디바이스 기반 미회원 사용 횟수 가져오기
      _guestUsageCount = await DeviceFingerprint.instance.getUsageCount();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionService] 디바이스 지문 초기화 오류: $e');
      }
      
      // 오류 발생 시 로컬 스토리지에서만 정보 가져오기
      await _loadGuestUsageCount();
    }
  }
  
  // 사용자 ID 설정
  void setUserId(String userId) {
    if (userId.isEmpty) {
      userId = 'anonymous';
    }
    
    _userId = userId;
    
    if (kDebugMode) {
      print('[SubscriptionService] 사용자 ID 설정됨: $userId');
    }
    
    // 사용자 ID가 설정되면 디바이스 사용 횟수 초기화
    if (_userId != 'anonymous') {
      resetGuestUsageCount();
    }
    
    loadSubscription(); // 사용자 ID가 변경되면 구독 정보 로드
  }

  // 구독 정보 로드
  Future<void> loadSubscription() async {
    if (_userId == 'anonymous') {
      if (kDebugMode) {
        print('[SubscriptionService] 익명 사용자는 구독 정보를 로드하지 않습니다.');
      }
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('[SubscriptionService] 구독 정보 로드 중...');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final subscriptionDataJson = prefs.getString('subscription_${_userId}');
      
      if (subscriptionDataJson != null) {
        final subscriptionData = json.decode(subscriptionDataJson);
        _currentPlan = SubscriptionPlan.values[subscriptionData['planIndex'] ?? 0];
        _expiryDate = subscriptionData['expiryDate'] != null 
            ? DateTime.parse(subscriptionData['expiryDate']) 
            : null;
            
        // 무료 체험 정보 로드
        if (subscriptionData.containsKey('trialStatus')) {
          _trialStatus = TrialStatus.values[subscriptionData['trialStatus'] ?? 0];
          _trialStartDate = subscriptionData['trialStartDate'] != null
              ? DateTime.parse(subscriptionData['trialStartDate'])
              : null;
          _trialEndDate = subscriptionData['trialEndDate'] != null
              ? DateTime.parse(subscriptionData['trialEndDate'])
              : null;
              
          // 무료 체험 상태 확인 및 업데이트
          _updateTrialStatus();
        }
            
        // 만료된 구독 확인 및 처리
        if (_expiryDate != null && _expiryDate!.isBefore(DateTime.now())) {
          _currentPlan = SubscriptionPlan.free;
          _expiryDate = null;
          await _saveSubscription(); // 만료된 구독 정보 업데이트
        }
        
        if (kDebugMode) {
          print('[SubscriptionService] 구독 정보 로드 완료: $_currentPlan');
        }
      } else {
        if (kDebugMode) {
          print('[SubscriptionService] 저장된 구독 정보 없음, 기본값으로 설정');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionService] 구독 정보 로드 오류: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 구독 정보 저장
  Future<void> _saveSubscription() async {
    if (_userId == 'anonymous') return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionData = {
        'planIndex': _currentPlan.index,
        'expiryDate': _expiryDate?.toIso8601String(),
        'trialStatus': _trialStatus.index,
        'trialStartDate': _trialStartDate?.toIso8601String(),
        'trialEndDate': _trialEndDate?.toIso8601String(),
      };
      
      await prefs.setString('subscription_${_userId}', json.encode(subscriptionData));
      
      if (kDebugMode) {
        print('[SubscriptionService] 구독 정보 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionService] 구독 정보 저장 오류: $e');
      }
    }
  }
  
  // 미회원 사용 횟수 증가 (디바이스 지문 및 로컬 스토리지 모두 업데이트)
  Future<bool> incrementGuestUsage() async {
    if (_guestUsageCount >= _maxGuestUsage) {
      return false; // 최대 사용 횟수 초과
    }
    
    try {
      // 디바이스 지문 사용 횟수 증가
      _guestUsageCount = await DeviceFingerprint.instance.incrementUsageCount();
      
      // 로컬 스토리지 백업
      await _saveGuestUsageCount();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('미회원 사용 횟수 업데이트 오류: $e');
      
      // 디바이스 지문 에러시 로컬만 업데이트
      _guestUsageCount++;
      await _saveGuestUsageCount();
      notifyListeners();
      return _guestUsageCount <= _maxGuestUsage;
    }
  }
  
  // 미회원 사용 횟수 로드
  Future<void> _loadGuestUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _guestUsageCount = prefs.getInt('guest_usage_count') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('미회원 사용 횟수 로드 오류: $e');
    }
  }
  
  // 미회원 사용 횟수 저장
  Future<void> _saveGuestUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guest_usage_count', _guestUsageCount);
    } catch (e) {
      debugPrint('미회원 사용 횟수 저장 오류: $e');
    }
  }
  
  // 미회원 사용 횟수 초기화 (사용자가 로그인한 경우)
  Future<void> resetGuestUsageCount() async {
    try {
      // 디바이스 지문 기반 사용 횟수 초기화
      await DeviceFingerprint.instance.resetUsageCount();
      
      // 로컬 스토리지 초기화
      _guestUsageCount = 0;
      await _saveGuestUsageCount();
      
      notifyListeners();
    } catch (e) {
      debugPrint('미회원 사용 횟수 초기화 오류: $e');
      
      // 디바이스 지문 에러시 로컬만 초기화
      _guestUsageCount = 0;
      await _saveGuestUsageCount();
      notifyListeners();
    }
  }
  
  // 프리미엄 무료 체험 시작
  Future<bool> startPremiumTrial({int trialDays = 7}) async {
    if (_userId == 'anonymous' || _trialStatus != TrialStatus.notStarted) {
      return false;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final now = DateTime.now();
      _trialStartDate = now;
      _trialEndDate = now.add(Duration(days: trialDays));
      _trialStatus = TrialStatus.active;
      _currentPlan = SubscriptionPlan.premium; // 체험 기간 동안 프리미엄 적용
      
      await _saveSubscription();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionService] 프리미엄 무료 체험 시작 오류: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // 무료 체험 상태 업데이트
  void _updateTrialStatus() {
    if (_trialStatus == TrialStatus.active && _trialEndDate != null) {
      if (DateTime.now().isAfter(_trialEndDate!)) {
        _trialStatus = TrialStatus.expired;
        // 무료 체험이 만료되었고 유료 구독이 없으면 무료 플랜으로 변경
        if (_currentPlan == SubscriptionPlan.premium && (_expiryDate == null || DateTime.now().isAfter(_expiryDate!))) {
          _currentPlan = SubscriptionPlan.free;
        }
      }
    }
  }
  
  // 구독 업그레이드 (실제 결제 처리는 추후 구현)
  Future<bool> upgradeToPlan(SubscriptionPlan plan, {int months = 1}) async {
    if (_userId == 'anonymous') return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // 여기에 실제 결제 처리 로직이 들어갈 예정
      // 결제 성공 시 아래 로직 실행
      
      _currentPlan = plan;
      
      // 만료일 계산 (현재 날짜 + 개월 수)
      final now = DateTime.now();
      _expiryDate = DateTime(now.year, now.month + months, now.day);
      
      await _saveSubscription();
      
      return true;
    } catch (e) {
      debugPrint('구독 업그레이드 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 테스트용 메서드: 기본 플랜으로 업그레이드
  Future<bool> upgradeToBasicPlan() async {
    return await upgradeToPlan(SubscriptionPlan.basic);
  }
  
  // 테스트용 메서드: 프리미엄 플랜으로 업그레이드
  Future<bool> upgradeToPremiumPlan() async {
    return await upgradeToPlan(SubscriptionPlan.premium);
  }
  
  // 테스트용 메서드: 무료 플랜으로 다운그레이드
  Future<bool> downgradeToFreePlan() async {
    return await upgradeToPlan(SubscriptionPlan.free);
  }
  
  // 플랜 이름 반환
  String getPlanName() {
    // 무료 체험 중인 경우
    if (_trialStatus == TrialStatus.active && _currentPlan == SubscriptionPlan.premium) {
      return '프리미엄 체험 중';
    }
    
    switch (_currentPlan) {
      case SubscriptionPlan.free:
        return '무료 플랜';
      case SubscriptionPlan.basic:
        return '베이직 (\$4.99/월)';
      case SubscriptionPlan.premium:
        return '프리미엄 (\$9.99/월)';
    }
  }
  
  // 남은 구독 기간 문자열 반환
  String getRemainingTime() {
    // 무료 체험 중인 경우
    if (_trialStatus == TrialStatus.active && _trialEndDate != null) {
      final now = DateTime.now();
      final difference = _trialEndDate!.difference(now);
      
      if (difference.isNegative) {
        return '체험 기간 만료됨';
      }
      
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      
      if (days > 0) {
        return '체험 기간: $days일 남음';
      } else {
        return '체험 기간: $hours시간 남음';
      }
    }
    
    // 일반 구독의 경우
    if (_expiryDate == null || _currentPlan == SubscriptionPlan.free) {
      return '';
    }
    
    final now = DateTime.now();
    final difference = _expiryDate!.difference(now);
    
    if (difference.isNegative) {
      return '만료됨';
    }
    
    final days = difference.inDays;
    return '$days일 남음';
  }

  /// 사용자의 구독을 업그레이드합니다.
  Future<void> upgradeSubscription(
    String userId,
    SubscriptionTier tier,
    DateTime expiresAt,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': tier.name,
        'subscriptionExpiresAt': expiresAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('구독 업그레이드 오류: $e');
      throw Exception('구독 업그레이드 중 오류가 발생했습니다: $e');
    }
  }

  /// 사용자의 구독이 만료되었는지 확인합니다.
  Future<bool> isSubscriptionExpired(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('subscriptionExpiresAt')) {
        final expiresAt = DateTime.parse(doc.data()!['subscriptionExpiresAt']);
        return DateTime.now().isAfter(expiresAt);
      }
      return true; // 만료 날짜가 없으면 만료된 것으로 간주
    } catch (e) {
      debugPrint('구독 만료 확인 오류: $e');
      return true; // 오류 발생 시 만료된 것으로 간주
    }
  }

  /// 사용자의 구독을 무료로 다운그레이드합니다.
  Future<void> downgradeToFree(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': SubscriptionTier.free.name,
        'subscriptionExpiresAt': null,
      });
    } catch (e) {
      debugPrint('구독 다운그레이드 오류: $e');
      throw Exception('구독 다운그레이드 중 오류가 발생했습니다: $e');
    }
  }

  // API 키 정보 관리 (새로 추가)
  static const String _apiKeyKey = 'user_api_key';
  String? _apiKey;
  
  // API 키 getter/setter
  String? get apiKey => _apiKey;
  
  // API 키 저장
  Future<void> setApiKey(String apiKey) async {
    if (apiKey.isEmpty) return;
    
    try {
      _apiKey = apiKey;
      
      if (_userId != 'anonymous') {
        // 로그인 상태면 Firestore에 저장
        await _firestore.collection('users').doc(_userId).update({
          'apiKey': _encryptApiKey(apiKey), // 실제로는 암호화해서 저장해야 함
        });
      } else {
        // 로그인 상태가 아니면 로컬에만 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_apiKeyKey, apiKey);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('API 키 저장 오류: $e');
    }
  }
  
  // API 키 로드
  Future<String?> getApiKey() async {
    if (_apiKey != null) return _apiKey;
    
    try {
      if (_userId != 'anonymous') {
        // 로그인 상태면 Firestore에서 가져오기
        final doc = await _firestore.collection('users').doc(_userId).get();
        if (doc.exists && doc.data()!.containsKey('apiKey')) {
          _apiKey = _decryptApiKey(doc.data()!['apiKey']); // 복호화 필요
          return _apiKey;
        }
      }
      
      // Firestore에 없거나 로그인 상태가 아니면 로컬에서 가져오기
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_apiKeyKey);
      return _apiKey;
    } catch (e) {
      debugPrint('API 키 로드 오류: $e');
      return null;
    }
  }
  
  // API 키 검증 (실제 구현은 API 호출 필요)
  Future<bool> validateApiKey(String apiKey) async {
    // 여기에 실제 Gemini API 키 검증 로직 추가
    // 간단한 테스트 예시
    if (apiKey.length < 10) {
      return false;
    }
    
    // 실제로는 API 호출해서 검증해야 함
    return true;
  }
  
  // API 키 암호화 (간단한 예시)
  String _encryptApiKey(String apiKey) {
    // 실제 앱에서는 적절한 암호화 알고리즘 사용 필요
    return apiKey; // 간단한 예시에서는 그대로 반환
  }
  
  // API 키 복호화 (간단한 예시)
  String _decryptApiKey(String encryptedApiKey) {
    // 실제 앱에서는 적절한 복호화 알고리즘 사용 필요
    return encryptedApiKey; // 간단한 예시에서는 그대로 반환
  }

  // 테스트 목적으로 사용할 메서드
  void setTestPlan(SubscriptionPlan plan) {
    _currentPlan = plan;
    if (kDebugMode) {
      print('[SubscriptionService] 테스트용 플랜 설정: $plan');
    }
    notifyListeners();
  }
}