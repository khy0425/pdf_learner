class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<UserProfile> getUserProfile(String userId) async {
    // 사용자 프로필 조회
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    // 프로필 업데이트
  }

  Future<void> updateSubscription({
    required String userId,
    required SubscriptionTier tier,
    required DateTime expiresAt,
  }) async {
    // 구독 정보 업데이트
  }

  Stream<UserProfile> profileChanges(String userId) {
    // 프로필 변경 실시간 감지
  }
} 