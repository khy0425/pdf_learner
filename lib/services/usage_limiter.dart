import '../services/subscription_service.dart';
import '../models/subscription_tier.dart';
import '../models/feature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsageLimiter {
  final SubscriptionService _subscriptionService;
  
  UsageLimiter(this._subscriptionService);

  Future<bool> canUseFeature(Feature feature) async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      
      // 해당 기능이 구독 티어에서 사용 가능한지 확인
      if (!subscription.tier.availableFeatures.contains(feature)) {
        return false;
      }
      
      final limits = subscription.tier.dailyAILimits;
      if (!limits.containsKey(feature)) {
        return true;  // 제한이 없는 기능은 사용 가능
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      final usage = await _getFeatureUsage(feature, today);
      
      return usage < limits[feature]!;
    } catch (e) {
      print('기능 사용 가능 여부 확인 중 오류: $e');
      return false;
    }
  }

  Future<bool> canUseAIFeature() async {
    try {
      final tier = await _subscriptionService.getCurrentTier();
      final currentUsage = await _subscriptionService.getDailyAIUsage();
      
      return currentUsage < tier.dailyAILimit;
    } catch (e) {
      print('AI 사용량 체크 오류: $e');
      return false;
    }
  }

  Future<void> incrementAIUsage() async {
    try {
      // AI 관련 기능 사용량 증가
      await _subscriptionService.incrementUsage(Feature.basicAISummary);
      await _subscriptionService.incrementUsage(Feature.aiQuiz);
    } catch (e) {
      print('AI 사용량 증가 중 오류: $e');
    }
  }

  Future<Map<String, dynamic>> getUsageStatus() async {
    final tier = await _subscriptionService.getCurrentTier();
    final currentUsage = await _subscriptionService.getDailyAIUsage();
    
    return {
      'currentUsage': currentUsage,
      'limit': tier.dailyAILimit,
      'remainingUsage': tier.dailyAILimit - currentUsage,
      'features': tier.availableFeatures.map((f) => f.name).toList(),
    };
  }

  Future<void> incrementUsage(Feature feature) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageRef = FirebaseFirestore.instance
        .collection('usage')
        .doc(_subscriptionService.userId)
        .collection('daily')
        .doc(today);

    await usageRef.set({
      feature.name: FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> _getFeatureUsage(Feature feature, String date) async {
    final doc = await FirebaseFirestore.instance
        .collection('usage')
        .doc(_subscriptionService.userId)
        .collection('daily')
        .doc(date)
        .get();
    
    return doc.data()?[feature.name] ?? 0;
  }
} 