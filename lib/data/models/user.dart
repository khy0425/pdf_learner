enum SubscriptionTier { 
  free, 
  basic, 
  premium;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return '무료 회원';
      case SubscriptionTier.basic:
        return '기본 회원';
      case SubscriptionTier.premium:
        return '프리미엄 회원';
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          '기본 PDF 뷰어',
          '기본 AI 요약 (일일 3회)',
          '북마크 기능',
        ];
      case SubscriptionTier.basic:
        return [
          '기본 PDF 뷰어',
          '기본 AI 요약 (일일 10회)',
          '북마크 기능',
          '학습 통계 분석',
        ];
      case SubscriptionTier.premium:
        return [
          '무제한 AI 요약',
          '고급 학습 노트',
          'AI 퀴즈 생성',
          '핵심 문장 하이라이트',
          '학습 통계 분석',
          '광고 제거',
        ];
    }
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final SubscriptionTier subscription;
  final DateTime? subscriptionExpiresAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    this.subscription = SubscriptionTier.free,
    this.subscriptionExpiresAt,
  });

  bool get isPremium => subscription == SubscriptionTier.premium;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'subscription': subscription.name,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      subscription: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['subscription'],
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionExpiresAt: map['subscriptionExpiresAt'] != null
          ? DateTime.parse(map['subscriptionExpiresAt'])
          : null,
    );
  }
} 