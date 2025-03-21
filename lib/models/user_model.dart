import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'package:flutter/foundation.dart';
import '../utils/null_safety_helpers.dart';

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
  static UserModel fromFirestore(DocumentSnapshot? doc) {
    try {
      // null check 강화
      if (doc == null) {
        debugPrint('UserModel.fromFirestore: 문서가 null입니다');
        return createDefaultUser();
      }
      
      if (!doc.exists) {
        debugPrint('UserModel.fromFirestore: 문서가 존재하지 않습니다');
        return createDefaultUser();
      }
      
      final data = doc.data();
      
      // data가 Map<String, dynamic>이 아닌 경우 체크
      if (data == null) {
        debugPrint('UserModel.fromFirestore: 문서 데이터가 null입니다');
        return createDefaultUser();
      }
      
      // data를 Map<String, dynamic>으로 타입 캐스팅 시도
      Map<String, dynamic> userData;
      try {
        userData = data as Map<String, dynamic>;
      } catch (e) {
        debugPrint('UserModel.fromFirestore: 데이터 형식 변환 오류: $e');
        return createDefaultUser();
      }
      
      // 필수 필드 확인
      final uid = NullSafetyHelpers.safeStringValue(userData['uid'], '');
      if (uid.isEmpty) {
        debugPrint('UserModel.fromFirestore: uid가 비어있습니다');
        // uid가 없는 경우에도 기본 사용자 모델 반환
        return createDefaultUser();
      }
      
      return UserModel(
        uid: uid,
        email: NullSafetyHelpers.safeStringValue(userData['email'], ''),
        displayName: NullSafetyHelpers.safeStringValue(userData['displayName'], '사용자'),
        photoURL: NullSafetyHelpers.safeStringValueNullable(userData['photoURL']),
        emailVerified: NullSafetyHelpers.safeBoolValue(userData['emailVerified'], false),
        createdAt: NullSafetyHelpers.safeTimestampValue(userData['createdAt']),
        lastLoginAt: userData['lastLoginAt'] != null ? NullSafetyHelpers.safeTimestampValue(userData['lastLoginAt']) : null,
        subscriptionTier: NullSafetyHelpers.safeStringValue(userData['subscriptionTier'], 'free'),
        subscriptionExpiresAt: userData['subscriptionExpiresAt'] != null ? NullSafetyHelpers.safeTimestampValue(userData['subscriptionExpiresAt']) : null,
        maxPdfTextLength: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLength'], 50000),
        maxPdfTextLengthPerPage: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLengthPerPage'], 1000),
        maxPdfTextLengthPerDay: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLengthPerDay'], 100000),
        maxPdfTextLengthPerMonth: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLengthPerMonth'], 1000000),
        maxPdfTextLengthPerYear: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLengthPerYear'], 10000000),
        maxPdfTextLengthPerLifetime: NullSafetyHelpers.safeIntValue(userData['maxPdfTextLengthPerLifetime'], 100000000),
        maxPdfsPerDay: NullSafetyHelpers.safeIntValue(userData['maxPdfsPerDay'], 5),
        maxPdfsPerMonth: NullSafetyHelpers.safeIntValue(userData['maxPdfsPerMonth'], 100),
        maxPdfsPerYear: NullSafetyHelpers.safeIntValue(userData['maxPdfsPerYear'], 1000),
        maxPdfsPerLifetime: NullSafetyHelpers.safeIntValue(userData['maxPdfsPerLifetime'], 10000),
        maxPdfsTotal: NullSafetyHelpers.safeIntValue(userData['maxPdfsTotal'], 20),
        maxPdfSize: NullSafetyHelpers.safeIntValue(userData['maxPdfSize'], 5 * 1024 * 1024),
        maxPdfPages: NullSafetyHelpers.safeIntValue(userData['maxPdfPages'], 50),
        maxUsagePerDay: NullSafetyHelpers.safeIntValue(userData['maxUsagePerDay'], 10),
        maxTextLength: NullSafetyHelpers.safeIntValue(userData['maxTextLength'], 10000),
        usageCount: NullSafetyHelpers.safeIntValue(userData['usageCount'], 0),
        lastUsageAt: userData['lastUsageAt'] != null ? NullSafetyHelpers.safeTimestampValue(userData['lastUsageAt']) : null,
        apiKey: NullSafetyHelpers.safeStringValueNullable(userData['apiKey']),
      );
    } catch (e) {
      debugPrint('UserModel.fromFirestore 예외 발생: $e');
      return createDefaultUser();
    }
  }
  
  /// 기본 사용자 모델 생성
  static UserModel createDefaultUser() {
    return UserModel(
      uid: '',
      email: '',
      displayName: '게스트',
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
      lastUsageAt: DateTime.now(),
    );
  }

  /// Map에서 UserModel 생성
  factory UserModel.fromMap(Map<String, dynamic>? map) {
    try {
      if (map == null) {
        debugPrint('UserModel.fromMap: map이 null입니다');
        return createDefaultUser();
      }
      
      return UserModel(
        uid: NullSafetyHelpers.safeStringValue(map['uid'], ''),
        email: NullSafetyHelpers.safeStringValue(map['email'], ''),
        displayName: NullSafetyHelpers.safeStringValue(map['displayName'], '사용자'),
        photoURL: NullSafetyHelpers.safeStringValueNullable(map['photoURL']),
        emailVerified: NullSafetyHelpers.safeBoolValue(map['emailVerified'], false),
        apiKey: NullSafetyHelpers.safeStringValueNullable(map['apiKey']),
        createdAt: NullSafetyHelpers.safeDateTimeValue(map['createdAt']),
        lastLoginAt: map['lastLoginAt'] != null ? NullSafetyHelpers.safeDateTimeValue(map['lastLoginAt']) : null,
        subscriptionTier: NullSafetyHelpers.safeStringValue(map['subscriptionTier'], 'free'),
        subscriptionExpiresAt: map['subscriptionExpiresAt'] != null ? NullSafetyHelpers.safeDateTimeValue(map['subscriptionExpiresAt']) : null,
        usageCount: NullSafetyHelpers.safeIntValue(map['usageCount'], 0),
        lastUsageAt: map['lastUsageAt'] != null ? NullSafetyHelpers.safeDateTimeValue(map['lastUsageAt']) : null,
        maxUsagePerDay: NullSafetyHelpers.safeIntValue(map['maxUsagePerDay'], 10),
        maxPdfSize: NullSafetyHelpers.safeIntValue(map['maxPdfSize'], 5 * 1024 * 1024),
        maxTextLength: NullSafetyHelpers.safeIntValue(map['maxTextLength'], 10000),
        maxPdfsPerDay: NullSafetyHelpers.safeIntValue(map['maxPdfsPerDay'], 5),
        maxPdfsTotal: NullSafetyHelpers.safeIntValue(map['maxPdfsTotal'], 20),
        maxPdfPages: NullSafetyHelpers.safeIntValue(map['maxPdfPages'], 50),
        maxPdfsPerMonth: NullSafetyHelpers.safeIntValue(map['maxPdfsPerMonth'], 100),
        maxPdfsPerYear: NullSafetyHelpers.safeIntValue(map['maxPdfsPerYear'], 1000),
        maxPdfsPerLifetime: NullSafetyHelpers.safeIntValue(map['maxPdfsPerLifetime'], 10000),
        maxPdfTextLength: NullSafetyHelpers.safeIntValue(map['maxPdfTextLength'], 50000),
        maxPdfTextLengthPerPage: NullSafetyHelpers.safeIntValue(map['maxPdfTextLengthPerPage'], 1000),
        maxPdfTextLengthPerDay: NullSafetyHelpers.safeIntValue(map['maxPdfTextLengthPerDay'], 100000),
        maxPdfTextLengthPerMonth: NullSafetyHelpers.safeIntValue(map['maxPdfTextLengthPerMonth'], 1000000),
        maxPdfTextLengthPerYear: NullSafetyHelpers.safeIntValue(map['maxPdfTextLengthPerYear'], 10000000),
        maxPdfTextLengthPerLifetime: NullSafetyHelpers.safeIntValue(map['maxPdfTextLengthPerLifetime'], 100000000),
      );
    } catch (e) {
      debugPrint('UserModel.fromMap 오류: $e');
      return createDefaultUser();
    }
  }

  /// JSON에서 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic>? json) {
    try {
      if (json == null) {
        debugPrint('UserModel.fromJson: json이 null입니다');
        return createDefaultUser();
      }
      
      return UserModel(
        uid: NullSafetyHelpers.safeStringValue(json['uid'], ''),
        email: NullSafetyHelpers.safeStringValue(json['email'], ''),
        displayName: NullSafetyHelpers.safeStringValue(json['displayName'], '사용자'),
        photoURL: NullSafetyHelpers.safeStringValueNullable(json['photoURL']),
        emailVerified: NullSafetyHelpers.safeBoolValue(json['emailVerified'], false),
        apiKey: NullSafetyHelpers.safeStringValueNullable(json['apiKey']),
        createdAt: NullSafetyHelpers.safeDateTimeValue(json['createdAt']),
        lastLoginAt: json['lastLoginAt'] != null ? NullSafetyHelpers.safeDateTimeValue(json['lastLoginAt']) : null,
        subscriptionTier: NullSafetyHelpers.safeStringValue(json['subscriptionTier'], 'free'),
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null ? NullSafetyHelpers.safeDateTimeValue(json['subscriptionExpiresAt']) : null,
        maxPdfTextLength: NullSafetyHelpers.safeIntValue(json['maxPdfTextLength'], 50000),
        maxPdfTextLengthPerPage: NullSafetyHelpers.safeIntValue(json['maxPdfTextLengthPerPage'], 1000),
        maxPdfTextLengthPerDay: NullSafetyHelpers.safeIntValue(json['maxPdfTextLengthPerDay'], 100000),
        maxPdfTextLengthPerMonth: NullSafetyHelpers.safeIntValue(json['maxPdfTextLengthPerMonth'], 1000000),
        maxPdfTextLengthPerYear: NullSafetyHelpers.safeIntValue(json['maxPdfTextLengthPerYear'], 10000000),
        maxPdfTextLengthPerLifetime: NullSafetyHelpers.safeIntValue(json['maxPdfTextLengthPerLifetime'], 100000000),
        maxPdfsPerDay: NullSafetyHelpers.safeIntValue(json['maxPdfsPerDay'], 5),
        maxPdfsPerMonth: NullSafetyHelpers.safeIntValue(json['maxPdfsPerMonth'], 100),
        maxPdfsPerYear: NullSafetyHelpers.safeIntValue(json['maxPdfsPerYear'], 1000),
        maxPdfsPerLifetime: NullSafetyHelpers.safeIntValue(json['maxPdfsPerLifetime'], 10000),
        maxPdfsTotal: NullSafetyHelpers.safeIntValue(json['maxPdfsTotal'], 20),
        maxPdfSize: NullSafetyHelpers.safeIntValue(json['maxPdfSize'], 5 * 1024 * 1024),
        maxPdfPages: NullSafetyHelpers.safeIntValue(json['maxPdfPages'], 50),
        maxUsagePerDay: NullSafetyHelpers.safeIntValue(json['maxUsagePerDay'], 10),
        maxTextLength: NullSafetyHelpers.safeIntValue(json['maxTextLength'], 10000),
        usageCount: NullSafetyHelpers.safeIntValue(json['usageCount'], 0),
        lastUsageAt: json['lastUsageAt'] != null ? NullSafetyHelpers.safeDateTimeValue(json['lastUsageAt']) : null,
      );
    } catch (e) {
      debugPrint('UserModel.fromJson 오류: $e');
      return createDefaultUser();
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

  /// UserModel을 JSON 형식으로 변환
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
    String? apiKey,
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

  /// 안전한 문자열 변환 (null 허용)
  static String? _safeStringNullable(dynamic value, String? defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    try {
      return value.toString();
    } catch (e) {
      debugPrint('_safeStringNullable 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// 안전한 문자열 변환 (항상 문자열 반환)
  static String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    try {
      return value.toString();
    } catch (e) {
      debugPrint('_safeString 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// 안전한 불리언 변환
  static bool _safeBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return defaultValue;
  }
  
  /// 안전한 정수 변환
  static int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }
    return defaultValue;
  }
  
  /// 안전한 DateTime 변환
  static DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
  
  /// 안전한 Timestamp 변환
  static DateTime _safeTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
} 