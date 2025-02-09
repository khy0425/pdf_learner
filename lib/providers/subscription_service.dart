import 'package:flutter/foundation.dart';

class SubscriptionService {
  // 기본 무료 사용자 설정
  static const int _freeUsageLimit = 50;
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  Future<bool> checkUsageLimit() async {
    if (_isPremium) return true;
    // 무료 사용자 제한 체크 로직
    return true; // 임시로 true 반환
  }

  Future<void> upgradeToPremium() async {
    // 프리미엄 업그레이드 로직
    _isPremium = true;
  }
}