import 'package:firebase_auth/firebase_auth.dart';

/// Firebase User 클래스 확장
extension UserExtension on User {
  /// 유저가 프리미엄 회원인지 확인
  bool get isPremium {
    // 실제 구현에서는 Firestore에서 사용자의 프리미엄 상태를 확인하거나
    // 다른 방법으로 프리미엄 상태를 가져와야 합니다.
    // 현재는 예시로 항상 false를 반환합니다.
    return false;
  }
} 