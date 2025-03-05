import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자의 구독 정보를 가져옵니다.
  Future<SubscriptionTier> getUserSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('subscription')) {
        final subscriptionName = doc.data()!['subscription'];
        return SubscriptionTier.values.firstWhere(
          (e) => e.name == subscriptionName,
          orElse: () => SubscriptionTier.free,
        );
      }
      return SubscriptionTier.free;
    } catch (e) {
      debugPrint('구독 정보 가져오기 오류: $e');
      return SubscriptionTier.free;
    }
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
}