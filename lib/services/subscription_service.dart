import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise,
  guest,
  plus,
  premiumTrial
}

class SubscriptionFeatures {
  static const Map<SubscriptionTier, Map<String, dynamic>> features = {
    SubscriptionTier.free: {
      'dailyQuizLimit': 5,
      'summaryLength': 'short',
      'aiAnalysis': false,
      'exportFeatures': false,
      'collaborationFeatures': false,
    },
    SubscriptionTier.basic: {
      'dailyQuizLimit': 20,
      'summaryLength': 'medium',
      'aiAnalysis': true,
      'exportFeatures': false,
      'collaborationFeatures': false,
      'price': '₩9,900/월',
    },
    SubscriptionTier.premium: {
      'dailyQuizLimit': 100,
      'summaryLength': 'long',
      'aiAnalysis': true,
      'exportFeatures': true,
      'collaborationFeatures': true,
      'price': '₩19,900/월',
    },
    SubscriptionTier.enterprise: {
      'dailyQuizLimit': 'unlimited',
      'summaryLength': 'custom',
      'aiAnalysis': true,
      'exportFeatures': true,
      'collaborationFeatures': true,
      'customSupport': true,
      'price': '별도 문의',
    },
  };
}

/// 구독 관련 기능 서비스
class SubscriptionService extends ChangeNotifier {
  /// 싱글톤 패턴 구현
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// 활성 구독 여부
  bool _hasActiveSubscription = false;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  DateTime? _subscriptionEndDate;
  
  /// 광고 무료 기간 (보상형 광고를 통해 얻은 임시 프리미엄 액세스)
  DateTime? _adFreeUntil;
  
  /// 초기화 상태
  bool _isInitialized = false;

  /// 저장소
  late SharedPreferences _prefs;
  
  /// 초기화
  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _hasActiveSubscription = _prefs.getBool('has_active_subscription') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('구독 서비스 초기화 오류: $e');
    }
  }
  
  /// Getter 메소드
  bool get hasActiveSubscription => _hasActiveSubscription || hasTemporaryPremium;
  SubscriptionTier get currentTier => _currentTier;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  bool get isInitialized => _isInitialized;
  
  /// 광고 보상 등으로 인한 임시 프리미엄 상태 확인
  bool get hasTemporaryPremium {
    if (_adFreeUntil == null) return false;
    return DateTime.now().isBefore(_adFreeUntil!);
  }
  
  /// 구독 남은 일수
  int get remainingDays {
    if (_subscriptionEndDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(_subscriptionEndDate!)) return 0;
    return _subscriptionEndDate!.difference(now).inDays;
  }

  /// 현재 사용자 ID 가져오기
  String get userId => _auth.currentUser?.uid ?? 'anonymous';

  /// 유료 사용자 여부
  bool get isPaidUser => false; // 기본값은 false로 설정

  /// 현재 사용자가 프리미엄 구독자인지 여부
  bool get isPremium => _hasActiveSubscription;

  /// 구독 상태 확인
  Future<SubscriptionTier> getCurrentTier([String? userId]) async {
    try {
      final uid = userId ?? this.userId;
      if (uid.isEmpty) {
        return SubscriptionTier.free;
      }
      
      final doc = await _db.collection('subscriptions')
          .doc(uid)
          .get();
      
      if (!doc.exists) return SubscriptionTier.free;
      
      final data = doc.data();
      if (data == null) return SubscriptionTier.free;
      
      final tierName = data['tier'] as String?;
      if (tierName == null) return SubscriptionTier.free;
      
      try {
        return SubscriptionTier.values.byName(tierName);
      } catch (e) {
        print('구독 티어 파싱 오류: $e');
        return SubscriptionTier.free;
      }
    } catch (e) {
      print('getCurrentTier 오류: $e');
      return SubscriptionTier.free;
    }
  }
  
  /// 구독 상태 변경 감지
  Stream<SubscriptionTier> get subscriptionChanges {
    if (_auth.currentUser == null) {
      return Stream.value(SubscriptionTier.free);
    }
    
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    return _db.collection('subscriptions')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return SubscriptionTier.free;
          final data = snapshot.data();
          if (data == null) return SubscriptionTier.free;
          
          final tierName = data['tier'] as String?;
          if (tierName == null) return SubscriptionTier.free;
          
          try {
            return SubscriptionTier.values.byName(tierName);
          } catch (e) {
            print('구독 티어 파싱 오류: $e');
            return SubscriptionTier.free;
          }
        });
  }
  
  /// 사용량 체크
  Future<bool> checkUsageLimit({
    required String userId,
    required String feature,
    required int amount,
  }) async {
    try {
      if (userId.isEmpty) {
        return true; // 익명 사용자는 제한을 체크하지 않음
      }
      
      final usage = await _db.collection('usage')
          .doc(userId)
          .collection('daily')
          .doc(DateTime.now().toIso8601String().split('T')[0])
          .get();

      final currentUsage = usage.data()?[feature] ?? 0;
      final tier = await getCurrentTier(userId);
      
      /// 구독 티어와 기능이 있는지 확인
      final featureMap = SubscriptionFeatures.features[tier];
      if (featureMap == null) {
        print('알 수 없는 구독 티어: $tier');
        return true; // 기본적으로 허용
      }
      
      final limit = featureMap[feature];
      if (limit == null) {
        print('$tier 티어에 $feature 기능이 정의되지 않음');
        return true; // 기본적으로 허용
      }
      
      /// 숫자가 아닌 'unlimited' 등의 값이 있을 수 있음
      if (limit is String && limit == 'unlimited') {
        return true;
      }
      
      if (limit is! int) {
        print('$feature의 제한이 숫자가 아님: $limit');
        return true; // 제한 형식이 잘못된 경우 기본적으로 허용
      }
      
      return currentUsage + amount <= limit;
    } catch (e) {
      print('사용량 확인 오류: $e');
      return true; // 오류 발생 시 기본적으로 허용
    }
  }
  
  /// 결제 처리
  Future<bool> processPurchase({
    required SubscriptionTier tier,
    required String paymentMethod,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }
      
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        print('사용자 ID가 없어 결제를 처리할 수 없습니다.');
        return false;
      }
      
      /// 구독 정보 업데이트
      await _db.collection('subscriptions')
          .doc(uid)
          .set({
            'tier': tier.name,
            'startDate': FieldValue.serverTimestamp(),
            'paymentMethod': paymentMethod,
            'status': 'active',
          }, SetOptions(merge: true));
      
      /// 결제 내역 기록
      await _db.collection('payments')
          .add({
            'userId': uid,
            'tier': tier.name,
            'amount': _getTierPrice(tier),
            'paymentMethod': paymentMethod,
            'timestamp': FieldValue.serverTimestamp(),
          });
      
      return true;
    } catch (e) {
      print('결제 처리 오류: $e');
      return false;
    }
  }
  
  /// 티어별 가격 반환
  double _getTierPrice(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.basic:
        return 9900;
      case SubscriptionTier.premium:
        return 19900;
      case SubscriptionTier.premiumTrial:
        return 1000;
      case SubscriptionTier.plus:
        return 4900;
      default:
        return 0;
    }
  }
  
  /// 현재 구독 정보 가져오기
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final tier = await getCurrentTier();
    return {
      'tier': tier,
      'features': SubscriptionFeatures.features[tier] ?? {},
    };
  }
  
  /// 일일 AI 사용량 가져오기
  Future<int> getDailyAIUsage() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final doc = await _db.collection('usage')
        .doc(userId)
        .collection('daily')
        .doc(today)
        .get();
    
    return doc.data()?['aiUsage'] ?? 0;
  }
  
  /// 기능 사용량 증가
  Future<void> incrementUsage(dynamic feature) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _db.collection('usage')
        .doc(userId)
        .collection('daily')
        .doc(today)
        .set({
          feature.toString(): FieldValue.increment(1),
          'aiUsage': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// 초기화 메소드
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadSubscriptionData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('구독 서비스 초기화 실패: $e');
    }
  }
  
  /// 구독 데이터 로드
  Future<void> _loadSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();
    
    /// 구독 상태 확인
    _hasActiveSubscription = prefs.getBool('has_active_subscription') ?? false;
    
    /// 구독 티어 확인
    final tierString = prefs.getString('subscription_tier') ?? 'free';
    _currentTier = _stringToSubscriptionTier(tierString);
    
    /// 구독 종료일 확인
    final endDateMillis = prefs.getInt('subscription_end_date');
    if (endDateMillis != null) {
      _subscriptionEndDate = DateTime.fromMillisecondsSinceEpoch(endDateMillis);
      
      /// 구독이 만료되었는지 확인
      if (DateTime.now().isAfter(_subscriptionEndDate!)) {
        await _resetSubscription();
      }
    }
    
    /// 임시 프리미엄 기간 확인
    final adFreeUntilMillis = prefs.getInt('ad_free_until');
    if (adFreeUntilMillis != null) {
      _adFreeUntil = DateTime.fromMillisecondsSinceEpoch(adFreeUntilMillis);
    }
  }
  
  /// 구독 데이터 저장
  Future<void> _saveSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('has_active_subscription', _hasActiveSubscription);
    await prefs.setString('subscription_tier', _currentTier.toString().split('.').last);
    
    if (_subscriptionEndDate != null) {
      await prefs.setInt(
        'subscription_end_date', 
        _subscriptionEndDate!.millisecondsSinceEpoch
      );
    } else {
      await prefs.remove('subscription_end_date');
    }
    
    if (_adFreeUntil != null) {
      await prefs.setInt(
        'ad_free_until', 
        _adFreeUntil!.millisecondsSinceEpoch
      );
    } else {
      await prefs.remove('ad_free_until');
    }
  }
  
  /// 구독 티어 문자열을 열거형으로 변환
  SubscriptionTier _stringToSubscriptionTier(String tierString) {
    switch (tierString.toLowerCase()) {
      case 'basic':
        return SubscriptionTier.basic;
      case 'premium':
        return SubscriptionTier.premium;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }
  
  /// 구독 시작
  Future<bool> subscribe(SubscriptionTier tier, int months) async {
    try {
      /// 실제 결제 처리 코드가 여기에 들어갑니다
      /// 결제 API를 호출하고 결제가 성공적으로 처리되면 아래 로직이 실행됩니다
      
      /// 결제가 성공했다고 가정
      final bool paymentSuccess = true;
      
      if (paymentSuccess) {
        _hasActiveSubscription = true;
        _currentTier = tier;
        
        /// 종료일 설정 (현재 날짜에서 구독 개월 수만큼 추가)
        final now = DateTime.now();
        _subscriptionEndDate = DateTime(
          now.year,
          now.month + months,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );
        
        await _saveSubscriptionData();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('구독 처리 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 구독 취소
  Future<bool> cancelSubscription() async {
    try {
      /// 실제 구독 취소 API 호출 코드가 여기에 들어갑니다
      
      /// 구독 취소가 성공했다고 가정
      final bool cancellationSuccess = true;
      
      if (cancellationSuccess) {
        /// 구독은 취소되었지만 현재 구독 기간이 끝날 때까지는 유지됩니다
        /// 실제 구독 상태는 바꾸지 않고, 종료일이 되면 자동으로 만료됩니다
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('구독 취소 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 구독 리셋 (만료 시)
  Future<void> _resetSubscription() async {
    _hasActiveSubscription = false;
    _currentTier = SubscriptionTier.free;
    _subscriptionEndDate = null;
    
    await _saveSubscriptionData();
    notifyListeners();
  }
  
  /// 보상형 광고를 통한 임시 프리미엄 액세스 부여
  Future<void> grantTemporaryPremium(Duration duration) async {
    /// 현재 시간에 지정된 기간을 더함
    _adFreeUntil = DateTime.now().add(duration);
    
    await _saveSubscriptionData();
    notifyListeners();
  }
  
  /// 현재 사용자 구독 정보 업데이트
  Future<void> updateFromUser(UserModel? user) async {
    if (user == null) {
      await _resetSubscription();
      return;
    }
    
    /// 사용자 모델에서 구독 정보 추출
    if (user.subscriptionTier == 'basic') {
      _currentTier = SubscriptionTier.basic;
      _hasActiveSubscription = true;
    } else if (user.subscriptionTier == 'premium') {
      _currentTier = SubscriptionTier.premium;
      _hasActiveSubscription = true;
    } else {
      _currentTier = SubscriptionTier.free;
      _hasActiveSubscription = false;
    }
    
    _subscriptionEndDate = user.subscriptionEndDate;
    
    /// 만료된 구독 확인
    if (_hasActiveSubscription && 
        _subscriptionEndDate != null && 
        DateTime.now().isAfter(_subscriptionEndDate!)) {
      await _resetSubscription();
    } else {
      await _saveSubscriptionData();
      notifyListeners();
    }
  }

  /// 구독 상태 설정
  Future<void> setSubscriptionStatus(bool isActive) async {
    _hasActiveSubscription = isActive;
    try {
      await _prefs.setBool('has_active_subscription', isActive);
    } catch (e) {
      debugPrint('구독 상태 저장 오류: $e');
    }
    notifyListeners();
  }
} 