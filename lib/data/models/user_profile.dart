class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final SubscriptionTier subscription;
  final DateTime? subscriptionExpiresAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    this.subscription = SubscriptionTier.free,
    this.subscriptionExpiresAt,
  });

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

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
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