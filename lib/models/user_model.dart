import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'package:flutter/foundation.dart';

/// 사용자 정보 모델 클래스
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool emailVerified;
  final String? apiKey;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final int usageCount;
  final DateTime? lastUsageAt;
  
  // 사용량 제한 관련 필드
  final int maxUsagePerDay;
  final int maxPdfSize;
  final int maxTextLength;
  final int maxPdfsPerDay;
  final int maxPdfsTotal;
  final int maxPdfPages;
  final int maxPdfsPerMonth;
  final int maxPdfsPerYear;
  final int maxPdfsPerLifetime;
  
  // PDF 텍스트 길이 제한 (기본 필드만 유지)
  final int maxPdfTextLength;
  final int maxPdfTextLengthPerPage;
  final int maxPdfTextLengthPerDay;
  final int maxPdfTextLengthPerMonth;
  final int maxPdfTextLengthPerYear;
  final int maxPdfTextLengthPerLifetime;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.apiKey,
    required this.createdAt,
    this.lastLoginAt,
    required this.subscriptionTier,
    this.subscriptionExpiresAt,
    this.usageCount = 0,
    this.lastUsageAt,
    this.maxUsagePerDay = 10,
    this.maxPdfSize = 5 * 1024 * 1024, // 5MB
    this.maxTextLength = 10000,
    this.maxPdfsPerDay = 5,
    this.maxPdfsTotal = 20,
    this.maxPdfPages = 50,
    this.maxPdfsPerMonth = 100,
    this.maxPdfsPerYear = 1000,
    this.maxPdfsPerLifetime = 10000,
    this.maxPdfTextLength = 50000,
    this.maxPdfTextLengthPerPage = 1000,
    this.maxPdfTextLengthPerDay = 100000,
    this.maxPdfTextLengthPerMonth = 1000000,
    this.maxPdfTextLengthPerYear = 10000000,
    this.maxPdfTextLengthPerLifetime = 100000000,
  });

  /// Firestore 문서에서 UserModel 생성
  static UserModel fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        debugPrint('UserModel.fromFirestore: 데이터가 null입니다.');
        return _createDefaultUser(doc.id);
      }
      
      // 안전한 타입 변환 함수
      String safeString(dynamic value) {
        if (value == null) return '';
        try {
          return value.toString();
        } catch (e) {
          debugPrint('safeString 변환 오류: $e');
          return '';
        }
      }
      
      bool safeBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        return value.toString().toLowerCase() == 'true';
      }
      
      int safeInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        try {
          return int.parse(value.toString());
        } catch (e) {
          return defaultValue;
        }
      }
      
      try {
        return UserModel(
          uid: doc.id,
          email: safeString(data['email']),
          displayName: safeString(data['displayName']),
          photoURL: data['photoURL'] != null ? safeString(data['photoURL']) : null,
          emailVerified: safeBool(data['emailVerified']),
          apiKey: data['apiKey'] != null ? safeString(data['apiKey']) : null,
          createdAt: _parseDateTime(data['createdAt']),
          lastLoginAt: data['lastLoginAt'] != null ? _parseDateTime(data['lastLoginAt']) : null,
          subscriptionTier: safeString(data['subscriptionTier'] ?? 'free'),
          subscriptionExpiresAt: data['subscriptionExpiresAt'] != null ? _parseDateTime(data['subscriptionExpiresAt']) : null,
          usageCount: safeInt(data['usageCount']),
          lastUsageAt: data['lastUsageAt'] != null ? _parseDateTime(data['lastUsageAt']) : null,
          maxUsagePerDay: safeInt(data['maxUsagePerDay'], defaultValue: 10),
          maxPdfSize: safeInt(data['maxPdfSize'], defaultValue: 5 * 1024 * 1024),
          maxTextLength: safeInt(data['maxTextLength'], defaultValue: 10000),
          maxPdfsPerDay: safeInt(data['maxPdfsPerDay'], defaultValue: 5),
          maxPdfsTotal: safeInt(data['maxPdfsTotal'], defaultValue: 20),
          maxPdfPages: safeInt(data['maxPdfPages'], defaultValue: 50),
          maxPdfsPerMonth: safeInt(data['maxPdfsPerMonth'], defaultValue: 100),
          maxPdfsPerYear: safeInt(data['maxPdfsPerYear'], defaultValue: 1000),
          maxPdfsPerLifetime: safeInt(data['maxPdfsPerLifetime'], defaultValue: 10000),
          maxPdfTextLength: safeInt(data['maxPdfTextLength'], defaultValue: 50000),
          maxPdfTextLengthPerPage: safeInt(data['maxPdfTextLengthPerPage'], defaultValue: 1000),
          maxPdfTextLengthPerDay: safeInt(data['maxPdfTextLengthPerDay'], defaultValue: 100000),
          maxPdfTextLengthPerMonth: safeInt(data['maxPdfTextLengthPerMonth'], defaultValue: 1000000),
          maxPdfTextLengthPerYear: safeInt(data['maxPdfTextLengthPerYear'], defaultValue: 10000000),
          maxPdfTextLengthPerLifetime: safeInt(data['maxPdfTextLengthPerLifetime'], defaultValue: 100000000),
        );
      } catch (e) {
        debugPrint('UserModel.fromFirestore 내부 오류: $e');
        return _createDefaultUser(doc.id);
      }
    } catch (e) {
      debugPrint('UserModel.fromFirestore 오류: $e');
      return _createDefaultUser(doc.id);
    }
  }
  
  /// 기본 사용자 모델 생성
  static UserModel _createDefaultUser(String uid) {
    return UserModel(
      uid: uid,
      email: '',
      displayName: '사용자',
      photoURL: null,
      emailVerified: false,
      createdAt: DateTime.now(),
      subscriptionTier: 'free',
      maxPdfTextLength: 50000,
      maxPdfTextLengthPerPage: 1000,
      maxPdfTextLengthPerDay: 100000,
      maxPdfTextLengthPerMonth: 1000000,
      maxPdfTextLengthPerYear: 10000000,
      maxPdfTextLengthPerLifetime: 100000000,
      maxPdfsPerDay: 5,
      maxPdfsPerMonth: 100,
      maxPdfsPerYear: 1000,
      maxPdfsPerLifetime: 10000,
      maxPdfsTotal: 20,
      maxPdfSize: 5 * 1024 * 1024,
      maxPdfPages: 50,
      maxUsagePerDay: 10,
      maxTextLength: 10000,
      usageCount: 0,
    );
  }

  /// Map에서 UserModel 생성
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String,
        photoURL: map['photoURL'] as String?,
        emailVerified: map['emailVerified'] as bool? ?? false,
        apiKey: map['apiKey'] as String?,
        createdAt: _parseDateTime(map['createdAt']),
        lastLoginAt: map['lastLoginAt'] != null ? _parseDateTime(map['lastLoginAt']) : null,
        subscriptionTier: map['subscriptionTier'] as String? ?? 'free',
        subscriptionExpiresAt: map['subscriptionExpiresAt'] != null ? _parseDateTime(map['subscriptionExpiresAt']) : null,
        usageCount: map['usageCount'] as int? ?? 0,
        lastUsageAt: map['lastUsageAt'] != null ? _parseDateTime(map['lastUsageAt']) : null,
        maxUsagePerDay: map['maxUsagePerDay'] as int? ?? 10,
        maxPdfSize: map['maxPdfSize'] as int? ?? 5 * 1024 * 1024,
        maxTextLength: map['maxTextLength'] as int? ?? 10000,
        maxPdfsPerDay: map['maxPdfsPerDay'] as int? ?? 5,
        maxPdfsTotal: map['maxPdfsTotal'] as int? ?? 20,
        maxPdfPages: map['maxPdfPages'] as int? ?? 50,
        maxPdfsPerMonth: map['maxPdfsPerMonth'] as int? ?? 100,
        maxPdfsPerYear: map['maxPdfsPerYear'] as int? ?? 1000,
        maxPdfsPerLifetime: map['maxPdfsPerLifetime'] as int? ?? 10000,
        maxPdfTextLength: map['maxPdfTextLength'] as int? ?? 50000,
        maxPdfTextLengthPerPage: map['maxPdfTextLengthPerPage'] as int? ?? 1000,
        maxPdfTextLengthPerDay: map['maxPdfTextLengthPerDay'] as int? ?? 100000,
        maxPdfTextLengthPerMonth: map['maxPdfTextLengthPerMonth'] as int? ?? 1000000,
        maxPdfTextLengthPerYear: map['maxPdfTextLengthPerYear'] as int? ?? 10000000,
        maxPdfTextLengthPerLifetime: map['maxPdfTextLengthPerLifetime'] as int? ?? 100000000,
      );
    } catch (e) {
      debugPrint('UserModel.fromMap 오류: $e');
      rethrow;
    }
  }

  /// JSON에서 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        uid: json['uid'] ?? '',
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? '',
        photoURL: json['photoURL'],
        emailVerified: json['emailVerified'] ?? false,
        apiKey: json['apiKey'],
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
        lastLoginAt: json['lastLoginAt'] != null 
            ? DateTime.parse(json['lastLoginAt']) 
            : null,
        subscriptionTier: json['subscriptionTier'] ?? 'free',
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null 
            ? DateTime.parse(json['subscriptionExpiresAt']) 
            : null,
        usageCount: json['usageCount'] is int ? json['usageCount'] : 0,
        lastUsageAt: json['lastUsageAt'] != null 
            ? DateTime.parse(json['lastUsageAt']) 
            : null,
        maxUsagePerDay: json['maxUsagePerDay'] is int ? json['maxUsagePerDay'] : 10,
        maxPdfSize: json['maxPdfSize'] is int ? json['maxPdfSize'] : 5 * 1024 * 1024,
        maxTextLength: json['maxTextLength'] is int ? json['maxTextLength'] : 10000,
        maxPdfsPerDay: json['maxPdfsPerDay'] is int ? json['maxPdfsPerDay'] : 5,
        maxPdfsTotal: json['maxPdfsTotal'] is int ? json['maxPdfsTotal'] : 20,
        maxPdfPages: json['maxPdfPages'] is int ? json['maxPdfPages'] : 50,
        maxPdfsPerMonth: json['maxPdfsPerMonth'] is int ? json['maxPdfsPerMonth'] : 100,
        maxPdfsPerYear: json['maxPdfsPerYear'] is int ? json['maxPdfsPerYear'] : 1000,
        maxPdfsPerLifetime: json['maxPdfsPerLifetime'] is int ? json['maxPdfsPerLifetime'] : 10000,
        maxPdfTextLength: json['maxPdfTextLength'] is int ? json['maxPdfTextLength'] : 50000,
        maxPdfTextLengthPerPage: json['maxPdfTextLengthPerPage'] is int ? json['maxPdfTextLengthPerPage'] : 1000,
        maxPdfTextLengthPerDay: json['maxPdfTextLengthPerDay'] is int ? json['maxPdfTextLengthPerDay'] : 100000,
        maxPdfTextLengthPerMonth: json['maxPdfTextLengthPerMonth'] is int ? json['maxPdfTextLengthPerMonth'] : 1000000,
        maxPdfTextLengthPerYear: json['maxPdfTextLengthPerYear'] is int ? json['maxPdfTextLengthPerYear'] : 10000000,
        maxPdfTextLengthPerLifetime: json['maxPdfTextLengthPerLifetime'] is int ? json['maxPdfTextLengthPerLifetime'] : 100000000,
      );
    } catch (e) {
      debugPrint('UserModel.fromJson 오류: $e');
      // 기본 사용자 모델 반환
      return UserModel(
        uid: json['uid'] ?? '',
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? '',
        photoURL: null,
        emailVerified: false,
        createdAt: DateTime.now(),
        subscriptionTier: 'free',
        maxPdfTextLength: 50000,
        maxPdfTextLengthPerPage: 1000,
        maxPdfTextLengthPerDay: 100000,
        maxPdfTextLengthPerMonth: 1000000,
        maxPdfTextLengthPerYear: 10000000,
        maxPdfTextLengthPerLifetime: 100000000,
        maxPdfsPerDay: 5,
        maxPdfsPerMonth: 100,
        maxPdfsPerYear: 1000,
        maxPdfsPerLifetime: 10000,
        maxPdfsTotal: 20,
        maxPdfSize: 5 * 1024 * 1024,
        maxPdfPages: 50,
        maxUsagePerDay: 10,
        maxTextLength: 10000,
        usageCount: 0,
      );
    }
  }

  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'apiKey': apiKey,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'usageCount': usageCount,
      'lastUsageAt': lastUsageAt?.toIso8601String(),
      'maxUsagePerDay': maxUsagePerDay,
      'maxPdfSize': maxPdfSize,
      'maxTextLength': maxTextLength,
      'maxPdfsPerDay': maxPdfsPerDay,
      'maxPdfsTotal': maxPdfsTotal,
      'maxPdfPages': maxPdfPages,
      'maxPdfsPerMonth': maxPdfsPerMonth,
      'maxPdfsPerYear': maxPdfsPerYear,
      'maxPdfsPerLifetime': maxPdfsPerLifetime,
      'maxPdfTextLength': maxPdfTextLength,
      'maxPdfTextLengthPerPage': maxPdfTextLengthPerPage,
      'maxPdfTextLengthPerDay': maxPdfTextLengthPerDay,
      'maxPdfTextLengthPerMonth': maxPdfTextLengthPerMonth,
      'maxPdfTextLengthPerYear': maxPdfTextLengthPerYear,
      'maxPdfTextLengthPerLifetime': maxPdfTextLengthPerLifetime,
    };
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'apiKey': apiKey,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'usageCount': usageCount,
      'lastUsageAt': lastUsageAt?.toIso8601String(),
      'maxUsagePerDay': maxUsagePerDay,
      'maxPdfSize': maxPdfSize,
      'maxTextLength': maxTextLength,
      'maxPdfsPerDay': maxPdfsPerDay,
      'maxPdfsTotal': maxPdfsTotal,
      'maxPdfPages': maxPdfPages,
      'maxPdfsPerMonth': maxPdfsPerMonth,
      'maxPdfsPerYear': maxPdfsPerYear,
      'maxPdfsPerLifetime': maxPdfsPerLifetime,
      'maxPdfTextLength': maxPdfTextLength,
      'maxPdfTextLengthPerPage': maxPdfTextLengthPerPage,
      'maxPdfTextLengthPerDay': maxPdfTextLengthPerDay,
      'maxPdfTextLengthPerMonth': maxPdfTextLengthPerMonth,
      'maxPdfTextLengthPerYear': maxPdfTextLengthPerYear,
      'maxPdfTextLengthPerLifetime': maxPdfTextLengthPerLifetime,
    };
  }

  /// 속성 업데이트된 새 인스턴스 생성
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    String? apiKey,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    int? usageCount,
    DateTime? lastUsageAt,
    int? maxUsagePerDay,
    int? maxPdfSize,
    int? maxTextLength,
    int? maxPdfsPerDay,
    int? maxPdfsTotal,
    int? maxPdfPages,
    int? maxPdfsPerMonth,
    int? maxPdfsPerYear,
    int? maxPdfsPerLifetime,
    int? maxPdfTextLength,
    int? maxPdfTextLengthPerPage,
    int? maxPdfTextLengthPerDay,
    int? maxPdfTextLengthPerMonth,
    int? maxPdfTextLengthPerYear,
    int? maxPdfTextLengthPerLifetime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      apiKey: apiKey ?? this.apiKey,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      usageCount: usageCount ?? this.usageCount,
      lastUsageAt: lastUsageAt ?? this.lastUsageAt,
      maxUsagePerDay: maxUsagePerDay ?? this.maxUsagePerDay,
      maxPdfSize: maxPdfSize ?? this.maxPdfSize,
      maxTextLength: maxTextLength ?? this.maxTextLength,
      maxPdfsPerDay: maxPdfsPerDay ?? this.maxPdfsPerDay,
      maxPdfsTotal: maxPdfsTotal ?? this.maxPdfsTotal,
      maxPdfPages: maxPdfPages ?? this.maxPdfPages,
      maxPdfsPerMonth: maxPdfsPerMonth ?? this.maxPdfsPerMonth,
      maxPdfsPerYear: maxPdfsPerYear ?? this.maxPdfsPerYear,
      maxPdfsPerLifetime: maxPdfsPerLifetime ?? this.maxPdfsPerLifetime,
      maxPdfTextLength: maxPdfTextLength ?? this.maxPdfTextLength,
      maxPdfTextLengthPerPage: maxPdfTextLengthPerPage ?? this.maxPdfTextLengthPerPage,
      maxPdfTextLengthPerDay: maxPdfTextLengthPerDay ?? this.maxPdfTextLengthPerDay,
      maxPdfTextLengthPerMonth: maxPdfTextLengthPerMonth ?? this.maxPdfTextLengthPerMonth,
      maxPdfTextLengthPerYear: maxPdfTextLengthPerYear ?? this.maxPdfTextLengthPerYear,
      maxPdfTextLengthPerLifetime: maxPdfTextLengthPerLifetime ?? this.maxPdfTextLengthPerLifetime,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, photoURL: $photoURL, emailVerified: $emailVerified, apiKey: ${apiKey != null ? "***" : "null"}, createdAt: $createdAt, lastLoginAt: $lastLoginAt, subscriptionTier: $subscriptionTier, subscriptionExpiresAt: $subscriptionExpiresAt, usageCount: $usageCount, lastUsageAt: $lastUsageAt, maxUsagePerDay: $maxUsagePerDay, maxPdfSize: $maxPdfSize, maxTextLength: $maxTextLength, maxPdfsPerDay: $maxPdfsPerDay, maxPdfsTotal: $maxPdfsTotal, maxPdfPages: $maxPdfPages)';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      debugPrint('_parseDateTime: null 값이 전달됨');
      return DateTime.now();
    }

    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      } else {
        debugPrint('_parseDateTime: 알 수 없는 타입 - ${value.runtimeType}');
        return DateTime.now();
      }
    } catch (e) {
      debugPrint('_parseDateTime 오류: $e');
      return DateTime.now();
    }
  }
} 