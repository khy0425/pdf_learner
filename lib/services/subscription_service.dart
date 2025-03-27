import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

/// 구독 등급
enum SubscriptionTier {
  /// 무료
  free,
  /// 기본
  basic,
  /// 프리미엄
  premium,
  /// 기업
  enterprise
}

@singleton
class SubscriptionService {
  final SharedPreferences _prefs;
  static const String _subscriptionKey = 'subscription_status';
  static const String _expiryKey = 'subscription_expiry';

  SubscriptionService(@Named('sharedPreferences') this._prefs);

  /// 구독 상태 확인
  bool get isSubscribed {
    final expiry = _prefs.getInt(_expiryKey);
    if (expiry == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(expiry).isAfter(DateTime.now());
  }

  /// 구독 만료일
  DateTime? get expiryDate {
    final expiry = _prefs.getInt(_expiryKey);
    if (expiry == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiry);
  }

  /// 구독 활성화
  Future<void> activateSubscription(DateTime expiryDate) async {
    await _prefs.setBool(_subscriptionKey, true);
    await _prefs.setInt(_expiryKey, expiryDate.millisecondsSinceEpoch);
  }

  /// 구독 비활성화
  Future<void> deactivateSubscription() async {
    await _prefs.setBool(_subscriptionKey, false);
    await _prefs.remove(_expiryKey);
  }

  /// 구독 갱신
  Future<void> renewSubscription(DateTime newExpiryDate) async {
    await activateSubscription(newExpiryDate);
  }

  /// 구독 상태 초기화
  Future<void> reset() async {
    await _prefs.remove(_subscriptionKey);
    await _prefs.remove(_expiryKey);
  }

  /// 현재 구독 등급
  SubscriptionTier get currentTier {
    final String? tierName = _prefs.getString(_tierKey);
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.name == tierName,
      orElse: () => SubscriptionTier.free,
    );
  }

  /// 구독 등급 변경
  Future<void> setTier(SubscriptionTier tier) async {
    await _prefs.setString(_tierKey, tier.name);
  }

  /// 프리미엄 기능 사용 가능 여부
  bool canAccessPremiumFeature(SubscriptionTier requiredTier) {
    if (!isSubscribed) return false;
    return currentTier.index >= requiredTier.index;
  }

  /// OCR 기능 사용 가능 여부
  bool get canUseOcr {
    return canAccessPremiumFeature(SubscriptionTier.premium);
  }

  /// AI 요약 기능 사용 가능 여부
  bool get canUseAiSummary {
    return canAccessPremiumFeature(SubscriptionTier.enterprise);
  }
} 