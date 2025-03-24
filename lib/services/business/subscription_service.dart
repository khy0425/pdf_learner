import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:pdf_learner_v2/utils/subscription_badge.dart';

/// 구독 등급
enum SubscriptionTier {
  free,
  premium,
  pro
}

/// 구독 상태
enum SubscriptionStatus {
  active,      // 활성화된 구독
  expired,     // 만료된 구독
  canceled,    // 취소된 구독
  pending,     // 결제 대기 중
}

/// 구독 혜택 정보 클래스
class SubscriptionBenefits {
  static const Map<String, Map<String, dynamic>> benefits = {
    'free': {
      'summaryCountPerDay': 3,
      'quizCountPerDay': 5,
      'maxFileSize': 10, // MB
      'watermark': true,
      'ads': true,
    },
    'premium': {
      'summaryCountPerDay': 10,
      'quizCountPerDay': 20,
      'maxFileSize': 50, // MB
      'watermark': false,
      'ads': false,
      'price': '₩9,900/월',
    },
    'pro': {
      'summaryCountPerDay': 100,
      'quizCountPerDay': 100,
      'maxFileSize': 100, // MB
      'watermark': false,
      'ads': false,
      'customColors': true,
      'priority': true,
      'price': '₩19,900/월',
    }
  };
  
  /// 특정 구독 등급의 혜택 정보를 반환
  static Map<String, dynamic> getForTier(String tier) {
    return benefits[tier] ?? benefits['free']!;
  }
  
  /// 일일 요약 생성 가능 횟수를 반환
  static int getSummaryCountForTier(String tier) {
    return benefits[tier]?['summaryCountPerDay'] ?? benefits['free']!['summaryCountPerDay'];
  }
  
  /// 일일 퀴즈 생성 가능 횟수를 반환
  static int getQuizCountForTier(String tier) {
    return benefits[tier]?['quizCountPerDay'] ?? benefits['free']!['quizCountPerDay'];
  }
  
  /// 최대 파일 크기(MB)를 반환
  static int getMaxFileSizeForTier(String tier) {
    return benefits[tier]?['maxFileSize'] ?? benefits['free']!['maxFileSize'];
  }
  
  /// 특정 등급의 가격 정보를 반환
  static String getPriceForTier(String tier) {
    return benefits[tier]?['price'] ?? '무료';
  }
}

/// 구독 관리 서비스
class SubscriptionService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  
  // 현재 구독 상태
  UserModel? _currentUser;
  String _subscriptionTier = 'free';
  DateTime? _subscriptionExpiryDate;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.expired;
  double _subscriptionProgress = 0.0; // 구독 진행 상태 (0.0 ~ 1.0)
  
  // 기타 상태 변수
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  /// 구독 진행 상태 (0.0 ~ 1.0)
  double get subscriptionProgress => _subscriptionProgress;
  
  /// 생성자
  SubscriptionService() {
    _init();
    
    // 인증 상태 변경 리스너 설정
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  /// 인증 상태 변경 처리
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _resetSubscriptionData();
      return;
    }
    
    // 사용자 로그인 시 구독 정보 로드
    await _loadSubscriptionData(firebaseUser.uid);
  }
  
  /// 초기화
  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('구독 서비스 초기화 오류: $e');
    }
  }
  
  /// 구독 데이터 초기화
  void _resetSubscriptionData() {
    _currentUser = null;
    _subscriptionExpiryDate = null;
    _subscriptionTier = 'free';
    _subscriptionStatus = SubscriptionStatus.expired;
    notifyListeners();
  }
  
  /// 사용자 구독 정보 로드
  Future<void> _loadSubscriptionData(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // 구독 만료일 로드
        if (userData['subscriptionExpiryDate'] != null) {
          _subscriptionExpiryDate = (userData['subscriptionExpiryDate'] as Timestamp).toDate();
          
          // 구독 상태 계산
          if (_subscriptionExpiryDate!.isAfter(DateTime.now())) {
            _subscriptionStatus = SubscriptionStatus.active;
          } else {
            _subscriptionStatus = SubscriptionStatus.expired;
          }
        } else {
          _subscriptionExpiryDate = null;
          _subscriptionStatus = SubscriptionStatus.expired;
        }
        
        // 구독 등급 로드
        _subscriptionTier = userData['subscriptionTier'] ?? 'free';
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('구독 정보 로드 중 오류: $e');
    }
  }
  
  /// 사용자 구독 정보 갱신
  void updateSubscriptionData(UserModel user) {
    _currentUser = user;
    _subscriptionTier = user.subscriptionTier;
    _subscriptionExpiryDate = user.subscriptionExpiryDate;
    
    // 구독 상태 계산
    if (_subscriptionExpiryDate != null && 
        _subscriptionExpiryDate!.isAfter(DateTime.now()) &&
        _subscriptionTier != 'free') {
      _subscriptionStatus = SubscriptionStatus.active;
    } else {
      _subscriptionStatus = SubscriptionStatus.expired;
    }
    
    notifyListeners();
  }
  
  /// 구독 업그레이드 (외부 결제 시스템 연동 후 호출)
  Future<void> upgradeSubscription({
    required String tier,
    required int durationInDays,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');
      
      // 만료일 계산
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationInDays));
      
      // Firestore 업데이트
      await _db.collection('users').doc(user.uid).update({
        'subscriptionTier': tier,
        'subscriptionExpiryDate': expiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 로컬 상태 업데이트
      _subscriptionTier = tier;
      _subscriptionExpiryDate = expiryDate;
      _subscriptionStatus = SubscriptionStatus.active;
      
      // 이벤트 기록 (선택사항)
      await _db.collection('subscription_events').add({
        'userId': user.uid,
        'event': 'subscription_upgraded',
        'tier': tier,
        'durationInDays': durationInDays,
        'startDate': now.millisecondsSinceEpoch,
        'expiryDate': expiryDate.millisecondsSinceEpoch,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('구독 업그레이드 중 오류: $e');
      rethrow;
    }
  }
  
  /// 구독 갱신 (자동 또는 수동)
  Future<void> renewSubscription({
    required int durationInDays,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');
      
      // 현재 구독이 없으면 업그레이드로 처리
      if (_subscriptionTier == 'free' || _subscriptionExpiryDate == null) {
        throw Exception('활성화된 구독이 없습니다');
      }
      
      // 새 만료일 계산 (현재 만료일 기준으로 연장)
      final now = DateTime.now();
      final baseDate = _subscriptionExpiryDate!.isAfter(now)
          ? _subscriptionExpiryDate! // 아직 만료되지 않은 경우 현재 만료일 기준
          : now; // 이미 만료된 경우 현재 시간 기준
      
      final newExpiryDate = baseDate.add(Duration(days: durationInDays));
      
      // Firestore 업데이트
      await _db.collection('users').doc(user.uid).update({
        'subscriptionExpiryDate': newExpiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 로컬 상태 업데이트
      _subscriptionExpiryDate = newExpiryDate;
      _subscriptionStatus = SubscriptionStatus.active;
      
      notifyListeners();
    } catch (e) {
      debugPrint('구독 갱신 중 오류: $e');
      rethrow;
    }
  }
  
  /// 구독 취소
  Future<void> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');
      
      // 구독 상태 업데이트 (만료일은 그대로 유지)
      await _db.collection('users').doc(user.uid).update({
        'subscriptionStatus': 'canceled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 로컬 상태 업데이트
      _subscriptionStatus = SubscriptionStatus.canceled;
      
      notifyListeners();
    } catch (e) {
      debugPrint('구독 취소 중 오류: $e');
      rethrow;
    }
  }
  
  /// 남은 구독 일수 계산
  int get remainingDays {
    if (_subscriptionExpiryDate == null) return 0;
    
    final now = DateTime.now();
    if (_subscriptionExpiryDate!.isBefore(now)) return 0;
    
    return _subscriptionExpiryDate!.difference(now).inDays;
  }
  
  /// 구독 만료 예정일 문자열
  String get expiryDateString {
    if (_subscriptionExpiryDate == null) return '구독 정보 없음';
    
    // 연/월/일 형식으로 반환
    return '${_subscriptionExpiryDate!.year}년 ${_subscriptionExpiryDate!.month}월 ${_subscriptionExpiryDate!.day}일';
  }
  
  /// 현재 구독 등급
  String get subscriptionTier => _subscriptionTier;
  
  /// 구독 상태
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  /// 현재 사용자 반환
  UserModel? get currentUser => _currentUser;
  
  /// 특정 사용자의 프리미엄 상태 확인
  Future<bool> isUserPremium(String userId) async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      if (!docSnapshot.exists) return false;
      
      final userData = docSnapshot.data()!;
      final tier = userData['subscriptionTier'] as String? ?? 'free';
      final expiryTimestamp = userData['subscriptionExpiryDate'] as Timestamp?;
      
      if (tier == 'free') return false;
      if (expiryTimestamp == null) return false;
      
      final expiryDate = expiryTimestamp.toDate();
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      debugPrint('프리미엄 상태 확인 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 사용자의 API 할당량 확인
  int getQuotaForUser(UserModel? user) {
    const Map<String, int> tierQuota = {
      'free': 10,
      'premium': 50,
      'pro': 100,
    };
    
    if (user == null) return tierQuota['free']!;
    return tierQuota[user.subscriptionTier] ?? tierQuota['free']!;
  }
  
  /// 활성화된 구독 여부
  bool get hasActiveSubscription {
    return _subscriptionStatus == SubscriptionStatus.active && 
           _subscriptionTier != 'free';
  }
  
  /// 프리미엄 등급 사용자 여부
  bool get isPremium {
    return hasActiveSubscription && _subscriptionTier == 'premium';
  }
  
  /// 프로 등급 사용자 여부
  bool get isPro {
    return hasActiveSubscription && _subscriptionTier == 'pro';
  }
  
  /// 미리 정의된 구독 플랜 목록
  List<Map<String, dynamic>> get subscriptionPlans {
    return [
      {
        'id': 'free',
        'name': '무료',
        'tier': 'free',
        'price': '무료',
        'description': '기본 기능 사용 가능',
        'features': [
          '하루 ${SubscriptionBenefits.getSummaryCountForTier('free')}개 PDF 요약',
          '하루 ${SubscriptionBenefits.getQuizCountForTier('free')}개 퀴즈 생성',
          '최대 ${SubscriptionBenefits.getMaxFileSizeForTier('free')}MB 파일 크기',
        ],
        'recommended': false,
        'color': Colors.grey,
      },
      {
        'id': 'premium_monthly',
        'name': '프리미엄',
        'tier': 'premium',
        'price': '₩9,900/월',
        'description': '더 많은 사용량과 광고 제거',
        'features': [
          '하루 ${SubscriptionBenefits.getSummaryCountForTier('premium')}개 PDF 요약',
          '하루 ${SubscriptionBenefits.getQuizCountForTier('premium')}개 퀴즈 생성',
          '최대 ${SubscriptionBenefits.getMaxFileSizeForTier('premium')}MB 파일 크기',
          '워터마크 제거',
          '광고 없음',
        ],
        'recommended': true,
        'color': Colors.blue,
      },
      {
        'id': 'pro_monthly',
        'name': '프로',
        'tier': 'pro',
        'price': '₩19,900/월',
        'description': '무제한에 가까운 사용량과 고급 기능',
        'features': [
          '하루 ${SubscriptionBenefits.getSummaryCountForTier('pro')}개 PDF 요약',
          '하루 ${SubscriptionBenefits.getQuizCountForTier('pro')}개 퀴즈 생성',
          '최대 ${SubscriptionBenefits.getMaxFileSizeForTier('pro')}MB 파일 크기',
          '워터마크 제거',
          '광고 없음',
          '우선 처리',
          '커스텀 테마',
        ],
        'recommended': false,
        'color': Colors.purple,
      },
    ];
  }
} 