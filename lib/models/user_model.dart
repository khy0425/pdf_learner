import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/null_safety_helpers.dart';
import 'package:flutter/foundation.dart';

enum UserRole {
  guest, // 비로그인 사용자
  free,  // 무료 회원
  basic, // 베이직 구독 ($1/월)
  premium // 프리미엄 구독 ($3/월)
}

/// 사용자 정보 모델 클래스
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;
  final String subscriptionTier;
  final DateTime? subscriptionEndDate;
  final int points; // 사용자 포인트 (리워드 광고 등으로 획득)

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.role = 'user',
    this.subscriptionTier = 'free',
    this.subscriptionEndDate,
    this.points = 0, // 기본값 0
  });

  bool get isGuest => role == UserRole.guest.toString();
  bool get isFree => role == UserRole.free.toString();
  bool get isPremium => role == UserRole.premium.toString() && isSubscriptionActive;
  bool get isBasic => role == UserRole.basic.toString() && isSubscriptionActive;
  
  bool get isSubscriptionActive {
    if (role != UserRole.premium.toString() && role != UserRole.basic.toString()) {
      return false;
    }
    return subscriptionEndDate?.isAfter(DateTime.now()) ?? false;
  }

  /// Firebase 사용자 객체로부터 UserModel 생성
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  /// Map 객체로부터 UserModel 생성
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: NullSafetyHelpers.safeStringValue(data['id']) ?? '',
      email: NullSafetyHelpers.safeStringValue(data['email']) ?? '',
      displayName: NullSafetyHelpers.safeStringValue(data['displayName']),
      photoURL: NullSafetyHelpers.safeStringValue(data['photoURL']),
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
          : DateTime.now(),
      role: NullSafetyHelpers.safeStringValue(data['role'], 'user'),
      subscriptionTier: NullSafetyHelpers.safeStringValue(data['subscriptionTier'], 'free'),
      subscriptionEndDate: data['subscriptionEndDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['subscriptionEndDate']) 
          : null,
      points: data['points'] ?? 0, // 포인트 추가 (기본값 0)
    );
  }

  /// Map 형식으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'role': role,
      'subscriptionTier': subscriptionTier,
      'subscriptionEndDate': subscriptionEndDate?.millisecondsSinceEpoch,
      'points': points, // 포인트 추가
    };
  }

  /// UserModel 복사본 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    String? subscriptionTier,
    DateTime? subscriptionEndDate,
    int? points, // 포인트 추가
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      points: points ?? this.points, // 포인트 추가
    );
  }
  
  /// JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() => toMap();
  
  /// JSON에서 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
  
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, points: $points)';
  }

  static UserRole _roleFromString(String value) {
    switch (value) {
      case 'UserRole.free':
        return UserRole.free;
      case 'UserRole.premium':
        return UserRole.premium;
      case 'UserRole.basic':
        return UserRole.basic;
      default:
        return UserRole.guest;
    }
  }

  factory UserModel.guest() {
    return UserModel(
      id: '',
      email: '',
      displayName: '게스트',
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: UserRole.guest.toString(),
      subscriptionTier: 'free',
      points: 0, // 포인트 추가
    );
  }

  String get uid => id;

  int get remainingDays {
    if (subscriptionEndDate == null) return 0;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }
  
  /// 포인트 추가
  UserModel addPoints(int amount) {
    return copyWith(
      points: points + amount,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 포인트 사용
  UserModel usePoints(int amount) {
    if (points < amount) {
      throw Exception('포인트가 부족합니다');
    }
    return copyWith(
      points: points - amount,
      updatedAt: DateTime.now(),
    );
  }
} 