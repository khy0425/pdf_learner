import 'package:flutter/foundation.dart';
import 'package:shared_preferences.dart';

enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise
}

class SubscriptionService extends ChangeNotifier {
  static const String _subscriptionKey = 'subscription_tier';
  final SharedPreferences _prefs;
  SubscriptionTier _currentTier;

  SubscriptionService(this._prefs)
      : _currentTier = SubscriptionTier.values[_prefs.getInt(_subscriptionKey) ?? 0];

  SubscriptionTier get currentTier => _currentTier;

  Future<void> updateSubscription(SubscriptionTier tier) async {
    _currentTier = tier;
    await _prefs.setInt(_subscriptionKey, tier.index);
    notifyListeners();
  }

  bool get isPremium => _currentTier == SubscriptionTier.premium;
  bool get isEnterprise => _currentTier == SubscriptionTier.enterprise;
  bool get isBasic => _currentTier == SubscriptionTier.basic;
  bool get isFree => _currentTier == SubscriptionTier.free;

  int get maxDocuments {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.basic:
        return 30;
      case SubscriptionTier.premium:
        return 300;
      case SubscriptionTier.enterprise:
        return -1; // 무제한
    }
  }

  int get maxAiRequestsPerDay {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.basic:
        return 100;
      case SubscriptionTier.premium:
        return 600;
      case SubscriptionTier.enterprise:
        return -1; // 무제한
    }
  }
} 