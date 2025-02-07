import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise
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

  // 구독 상태 확인
  Future<SubscriptionTier> getCurrentTier(String userId) async {
    final doc = await _db.collection('subscriptions')
        .doc(userId)
        .get();
    
    if (!doc.exists) return SubscriptionTier.free;
    return SubscriptionTier.values.byName(doc.data()!['tier']);
  }
  
  // 구독 상태 변경 감지
  Stream<SubscriptionTier> get subscriptionChanges;
  
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
  });
} 