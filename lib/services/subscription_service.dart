import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

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

class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 현재 사용자 ID 가져오기
  String get userId => _auth.currentUser?.uid ?? 'anonymous';

  // 구독 상태 확인
  Future<SubscriptionTier> getCurrentTier([String? userId]) async {
    final uid = userId ?? this.userId;
    final doc = await _db.collection('subscriptions')
        .doc(uid)
        .get();
    
    if (!doc.exists) return SubscriptionTier.free;
    return SubscriptionTier.values.byName(doc.data()!['tier']);
  }
  
  // 구독 상태 변경 감지
  Stream<SubscriptionTier> get subscriptionChanges {
    if (_auth.currentUser == null) {
      return Stream.value(SubscriptionTier.free);
    }
    
    return _db.collection('subscriptions')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return SubscriptionTier.free;
          return SubscriptionTier.values.byName(snapshot.data()!['tier']);
        });
  }
  
  // 사용량 체크
  Future<bool> checkUsageLimit({
    required String userId,
    required String feature,
    required int amount,
  }) async {
    final usage = await _db.collection('usage')
        .doc(userId)
        .collection('daily')
        .doc(DateTime.now().toIso8601String().split('T')[0])
        .get();

    final currentUsage = usage.data()?[feature] ?? 0;
    final tier = await getCurrentTier(userId);
    final limit = SubscriptionFeatures.features[tier]![feature];
    
    return currentUsage + amount <= limit;
  }
  
  // 결제 처리
  Future<bool> processPurchase({
    required SubscriptionTier tier,
    required String paymentMethod,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }
      
      // 구독 정보 업데이트
      await _db.collection('subscriptions')
          .doc(_auth.currentUser!.uid)
          .set({
            'tier': tier.name,
            'startDate': FieldValue.serverTimestamp(),
            'paymentMethod': paymentMethod,
            'status': 'active',
          }, SetOptions(merge: true));
      
      // 결제 내역 기록
      await _db.collection('payments')
          .add({
            'userId': _auth.currentUser!.uid,
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
  
  // 티어별 가격 반환
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
  
  // 현재 구독 정보 가져오기
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final tier = await getCurrentTier();
    return {
      'tier': tier,
      'features': SubscriptionFeatures.features[tier] ?? {},
    };
  }
  
  // 일일 AI 사용량 가져오기
  Future<int> getDailyAIUsage() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final doc = await _db.collection('usage')
        .doc(userId)
        .collection('daily')
        .doc(today)
        .get();
    
    return doc.data()?['aiUsage'] ?? 0;
  }
  
  // 기능 사용량 증가
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
} 