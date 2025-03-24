import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/null_safety_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  guest, // 비로그인 사용자
  free,  // 무료 회원
  basic, // 베이직 구독 ($1/월)
  premium // 프리미엄 구독 ($3/월)
}

/// 사용자 정보 모델
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isAnonymous;
  final String subscriptionTier; // 'free', 'premium', 'pro'
  final DateTime? subscriptionExpiryDate;
  final int points;
  final List<String> favorites;
  final List<String> recentDocuments;
  final DateTime? createdAt;
  final DateTime? lastUsageAt;
  final int usageCount;
  final int maxPdfsTotal;
  final int maxUsagePerDay;
  
  // uid getter 추가
  String get uid => id;
  
  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.isAnonymous,
    this.subscriptionTier = 'free',
    this.subscriptionExpiryDate,
    this.points = 0,
    List<String>? favorites,
    List<String>? recentDocuments,
    this.createdAt,
    this.lastUsageAt,
    this.usageCount = 0,
    this.maxPdfsTotal = 5,
    this.maxUsagePerDay = 3,
  }) : 
    this.favorites = favorites ?? [],
    this.recentDocuments = recentDocuments ?? [];
  
  /// 기본 사용자 정보 객체 생성
  static UserModel createDefaultUser() {
    return UserModel(
      id: '',
      email: '',
      displayName: '게스트',
      isAnonymous: true,
      subscriptionTier: 'free',
      createdAt: DateTime.now(),
      lastUsageAt: DateTime.now(),
    );
  }
  
  /// Firebase User 객체로부터 생성
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser, {Map<String, dynamic>? data}) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? '사용자',
      photoURL: firebaseUser.photoURL,
      isAnonymous: firebaseUser.isAnonymous,
      subscriptionTier: data?['subscriptionTier'] ?? 'free',
      subscriptionExpiryDate: data?['subscriptionExpiryDate'] != null 
          ? (data!['subscriptionExpiryDate'] as Timestamp).toDate() 
          : null,
      points: data?['points'] ?? 0,
      favorites: data?['favorites'] != null 
          ? List<String>.from(data!['favorites']) 
          : [],
      recentDocuments: data?['recentDocuments'] != null 
          ? List<String>.from(data!['recentDocuments']) 
          : [],
      createdAt: data?['createdAt'] != null 
          ? (data!['createdAt'] as Timestamp).toDate() 
          : null,
      lastUsageAt: data?['lastUsageAt'] != null 
          ? (data!['lastUsageAt'] as Timestamp).toDate() 
          : null,
      usageCount: data?['usageCount'] ?? 0,
      maxPdfsTotal: data?['maxPdfsTotal'] ?? 5,
      maxUsagePerDay: data?['maxUsagePerDay'] ?? 3,
    );
  }
  
  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAnonymous': isAnonymous,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiryDate': subscriptionExpiryDate,
      'points': points,
      'favorites': favorites,
      'recentDocuments': recentDocuments,
      'createdAt': createdAt,
      'lastUsageAt': lastUsageAt,
      'usageCount': usageCount,
      'maxPdfsTotal': maxPdfsTotal,
      'maxUsagePerDay': maxUsagePerDay,
    };
  }
  
  /// 특정 필드만 업데이트된 복사본 생성
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? subscriptionTier,
    DateTime? subscriptionExpiryDate,
    int? points,
    List<String>? favorites,
    List<String>? recentDocuments,
    DateTime? createdAt,
    DateTime? lastUsageAt,
    int? usageCount,
    int? maxPdfsTotal,
    int? maxUsagePerDay,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAnonymous: this.isAnonymous,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      points: points ?? this.points,
      favorites: favorites ?? this.favorites,
      recentDocuments: recentDocuments ?? this.recentDocuments,
      createdAt: createdAt ?? this.createdAt,
      lastUsageAt: lastUsageAt ?? this.lastUsageAt,
      usageCount: usageCount ?? this.usageCount,
      maxPdfsTotal: maxPdfsTotal ?? this.maxPdfsTotal,
      maxUsagePerDay: maxUsagePerDay ?? this.maxUsagePerDay,
    );
  }
  
  /// 새 문서를 최근 문서 목록에 추가
  UserModel addRecentDocument(String documentId) {
    final newRecentDocs = List<String>.from(recentDocuments);
    
    // 이미 있으면 먼저 제거
    newRecentDocs.remove(documentId);
    
    // 맨 앞에 추가
    newRecentDocs.insert(0, documentId);
    
    // 최대 10개까지만 유지
    if (newRecentDocs.length > 10) {
      newRecentDocs.removeLast();
    }
    
    return copyWith(recentDocuments: newRecentDocs);
  }
  
  /// 즐겨찾기 토글
  UserModel toggleFavorite(String documentId) {
    final newFavorites = List<String>.from(favorites);
    
    if (newFavorites.contains(documentId)) {
      newFavorites.remove(documentId);
    } else {
      newFavorites.add(documentId);
    }
    
    return copyWith(favorites: newFavorites);
  }
  
  /// 구독이 활성화되어 있는지 확인
  bool get isSubscriptionActive {
    if (subscriptionTier == 'free') return false;
    
    // 유효기간 만료 확인
    if (subscriptionExpiryDate != null) {
      return subscriptionExpiryDate!.isAfter(DateTime.now());
    }
    
    return false;
  }
  
  /// 프리미엄 이상 구독인지 확인
  bool get isPremiumOrHigher {
    return isSubscriptionActive && 
        (subscriptionTier == 'premium' || subscriptionTier == 'pro');
  }
  
  /// 프로 구독인지 확인
  bool get isProTier {
    return isSubscriptionActive && subscriptionTier == 'pro';
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'UserModel(id: $id, name: $displayName, email: $email, tier: $subscriptionTier)';
  }
  
  /// 동일성 비교
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.subscriptionTier == subscriptionTier;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ subscriptionTier.hashCode;
  }
} 