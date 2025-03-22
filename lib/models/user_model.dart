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
  final String? id;
  final String? email;
  final String? name;
  final UserRole role;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? planType; // 'basic' 또는 'premium'

  const UserModel({
    this.id,
    this.email,
    this.name,
    this.role = UserRole.free,
    this.subscriptionEndDate,
    required this.createdAt,
    this.lastLoginAt,
    this.planType,
  });

  bool get isGuest => role == UserRole.guest;
  bool get isFree => role == UserRole.free;
  bool get isPremium => role == UserRole.premium && isSubscriptionActive;
  bool get isBasic => role == UserRole.basic && isSubscriptionActive;
  
  bool get isSubscriptionActive {
    if (role != UserRole.premium && role != UserRole.basic) {
      return false;
    }
    return subscriptionEndDate?.isAfter(DateTime.now()) ?? false;
  }

  /// Firebase 사용자 객체로부터 UserModel 생성
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '사용자',
      role: UserRole.free,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  /// Map 객체로부터 UserModel 생성
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: NullSafetyHelpers.safeStringValue(data['id']),
      email: NullSafetyHelpers.safeStringValue(data['email']),
      name: NullSafetyHelpers.safeStringValue(data['name'], '사용자'),
      role: _roleFromString(NullSafetyHelpers.safeStringValue(data['role'], 'UserRole.guest')),
      subscriptionEndDate: data['subscriptionEndDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['subscriptionEndDate']) 
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['lastLoginAt']) 
          : null,
      planType: NullSafetyHelpers.safeStringValue(data['planType']),
    );
  }

  /// Map 형식으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString(),
      'subscriptionEndDate': subscriptionEndDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'planType': planType,
    };
  }

  /// UserModel 복사본 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? subscriptionEndDate,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? planType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      planType: planType ?? this.planType,
    );
  }
  
  /// JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() => toMap();
  
  /// JSON에서 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
  
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
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
      id: null,
      email: null,
      name: '게스트',
      role: UserRole.guest,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  String get uid => id ?? '';

  int get remainingDays {
    if (subscriptionEndDate == null) return 0;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }
} 