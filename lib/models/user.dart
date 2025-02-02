class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? photoUrl;
  final UserSubscription subscription;
  final DateTime? subscriptionExpiresAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.photoUrl,
    this.subscription = UserSubscription.free,
    this.subscriptionExpiresAt,
  });

  bool get isPremium => subscription == UserSubscription.premium;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
      'subscription': subscription.name,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      photoUrl: map['photoUrl'],
      subscription: UserSubscription.values.firstWhere(
        (e) => e.name == map['subscription'],
        orElse: () => UserSubscription.free,
      ),
      subscriptionExpiresAt: map['subscriptionExpiresAt'] != null 
          ? DateTime.parse(map['subscriptionExpiresAt'])
          : null,
    );
  }
}

enum UserSubscription {
  free,
  premium;

  String get displayName {
    switch (this) {
      case UserSubscription.free:
        return '무료 회원';
      case UserSubscription.premium:
        return '프리미엄 회원';
    }
  }

  List<String> get features {
    switch (this) {
      case UserSubscription.free:
        return [
          '기본 PDF 뷰어',
          '기본 AI 요약 (일일 3회)',
          '북마크 기능',
        ];
      case UserSubscription.premium:
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