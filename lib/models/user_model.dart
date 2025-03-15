import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'package:flutter/foundation.dart';

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
  final int maxUsagePerDay;
  final int maxPdfSize;
  final int maxTextLength;
  final int maxPdfsPerDay;
  final int maxPdfsTotal;
  final int maxPdfPages;
  final int maxPdfTextLength;
  final int maxPdfTextLengthPerPage;
  final int maxPdfTextLengthPerDay;
  final int maxPdfTextLengthPerMonth;
  final int maxPdfTextLengthPerYear;
  final int maxPdfTextLengthPerLifetime;
  final int maxPdfTextLengthPerPdf;
  final int maxPdfTextLengthPerPdfPerPage;
  final int maxPdfTextLengthPerPdfPerDay;
  final int maxPdfTextLengthPerPdfPerMonth;
  final int maxPdfTextLengthPerPdfPerYear;
  final int maxPdfTextLengthPerPdfPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerDay;
  final int maxPdfTextLengthPerPdfPerPagePerMonth;
  final int maxPdfTextLengthPerPdfPerPagePerYear;
  final int maxPdfTextLengthPerPdfPerPagePerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerMonth;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerYear;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerMonthPerYear;
  final int maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerYearPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime;
  final int maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime;

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
    required this.maxPdfTextLength,
    required this.maxPdfTextLengthPerPage,
    required this.maxPdfTextLengthPerDay,
    required this.maxPdfTextLengthPerMonth,
    required this.maxPdfTextLengthPerYear,
    required this.maxPdfTextLengthPerLifetime,
    required this.maxPdfTextLengthPerPdf,
    required this.maxPdfTextLengthPerPdfPerPage,
    required this.maxPdfTextLengthPerPdfPerDay,
    required this.maxPdfTextLengthPerPdfPerMonth,
    required this.maxPdfTextLengthPerPdfPerYear,
    required this.maxPdfTextLengthPerPdfPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerDay,
    required this.maxPdfTextLengthPerPdfPerPagePerMonth,
    required this.maxPdfTextLengthPerPdfPerPagePerYear,
    required this.maxPdfTextLengthPerPdfPerPagePerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerMonth,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerYear,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerMonthPerYear,
    required this.maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerYearPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime,
    required this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String,
        photoURL: map['photoURL'] as String?,
        emailVerified: map['emailVerified'] as bool? ?? false,
        apiKey: map['apiKey'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt'] as String) : null,
        subscriptionTier: map['subscriptionTier'] as String? ?? 'free',
        subscriptionExpiresAt: map['subscriptionExpiresAt'] != null ? DateTime.parse(map['subscriptionExpiresAt'] as String) : null,
        usageCount: map['usageCount'] as int? ?? 0,
        lastUsageAt: map['lastUsageAt'] != null ? DateTime.parse(map['lastUsageAt'] as String) : null,
        maxUsagePerDay: map['maxUsagePerDay'] as int? ?? 10,
        maxPdfSize: map['maxPdfSize'] as int? ?? 5 * 1024 * 1024,
        maxTextLength: map['maxTextLength'] as int? ?? 10000,
        maxPdfsPerDay: map['maxPdfsPerDay'] as int? ?? 5,
        maxPdfsTotal: map['maxPdfsTotal'] as int? ?? 20,
        maxPdfPages: map['maxPdfPages'] as int? ?? 50,
        maxPdfTextLength: map['maxPdfTextLength'] as int? ?? 0,
        maxPdfTextLengthPerPage: map['maxPdfTextLengthPerPage'] as int? ?? 0,
        maxPdfTextLengthPerDay: map['maxPdfTextLengthPerDay'] as int? ?? 0,
        maxPdfTextLengthPerMonth: map['maxPdfTextLengthPerMonth'] as int? ?? 0,
        maxPdfTextLengthPerYear: map['maxPdfTextLengthPerYear'] as int? ?? 0,
        maxPdfTextLengthPerLifetime: map['maxPdfTextLengthPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdf: map['maxPdfTextLengthPerPdf'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPage: map['maxPdfTextLengthPerPdfPerPage'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerDay: map['maxPdfTextLengthPerPdfPerDay'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerMonth: map['maxPdfTextLengthPerPdfPerMonth'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerYear: map['maxPdfTextLengthPerPdfPerYear'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerLifetime: map['maxPdfTextLengthPerPdfPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDay: map['maxPdfTextLengthPerPdfPerPagePerDay'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerMonth: map['maxPdfTextLengthPerPdfPerPagePerMonth'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerYear: map['maxPdfTextLengthPerPdfPerPagePerYear'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerLifetime: map['maxPdfTextLengthPerPdfPerPagePerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonth: map['maxPdfTextLengthPerPdfPerPagePerDayPerMonth'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerYear: map['maxPdfTextLengthPerPdfPerPagePerDayPerYear'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerDayPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYear: map['maxPdfTextLengthPerPdfPerPagePerMonthPerYear'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerYearPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: map['maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime'] as int? ?? 0,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: map['maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('UserModel.fromMap 오류: $e');
      rethrow;
    }
  }

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
      'maxPdfTextLength': maxPdfTextLength,
      'maxPdfTextLengthPerPage': maxPdfTextLengthPerPage,
      'maxPdfTextLengthPerDay': maxPdfTextLengthPerDay,
      'maxPdfTextLengthPerMonth': maxPdfTextLengthPerMonth,
      'maxPdfTextLengthPerYear': maxPdfTextLengthPerYear,
      'maxPdfTextLengthPerLifetime': maxPdfTextLengthPerLifetime,
      'maxPdfTextLengthPerPdf': maxPdfTextLengthPerPdf,
      'maxPdfTextLengthPerPdfPerPage': maxPdfTextLengthPerPdfPerPage,
      'maxPdfTextLengthPerPdfPerDay': maxPdfTextLengthPerPdfPerDay,
      'maxPdfTextLengthPerPdfPerMonth': maxPdfTextLengthPerPdfPerMonth,
      'maxPdfTextLengthPerPdfPerYear': maxPdfTextLengthPerPdfPerYear,
      'maxPdfTextLengthPerPdfPerLifetime': maxPdfTextLengthPerPdfPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerDay': maxPdfTextLengthPerPdfPerPagePerDay,
      'maxPdfTextLengthPerPdfPerPagePerMonth': maxPdfTextLengthPerPdfPerPagePerMonth,
      'maxPdfTextLengthPerPdfPerPagePerYear': maxPdfTextLengthPerPdfPerPagePerYear,
      'maxPdfTextLengthPerPdfPerPagePerLifetime': maxPdfTextLengthPerPdfPerPagePerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerDayPerMonth': maxPdfTextLengthPerPdfPerPagePerDayPerMonth,
      'maxPdfTextLengthPerPdfPerPagePerDayPerYear': maxPdfTextLengthPerPdfPerPagePerDayPerYear,
      'maxPdfTextLengthPerPdfPerPagePerDayPerLifetime': maxPdfTextLengthPerPdfPerPagePerDayPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerMonthPerYear': maxPdfTextLengthPerPdfPerPagePerMonthPerYear,
      'maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime': maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerYearPerLifetime': maxPdfTextLengthPerPdfPerPagePerYearPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear': maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear,
      'maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime': maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime': maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime': maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime,
      'maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime': maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime,
    };
  }

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
    int? maxPdfTextLength,
    int? maxPdfTextLengthPerPage,
    int? maxPdfTextLengthPerDay,
    int? maxPdfTextLengthPerMonth,
    int? maxPdfTextLengthPerYear,
    int? maxPdfTextLengthPerLifetime,
    int? maxPdfTextLengthPerPdf,
    int? maxPdfTextLengthPerPdfPerPage,
    int? maxPdfTextLengthPerPdfPerDay,
    int? maxPdfTextLengthPerPdfPerMonth,
    int? maxPdfTextLengthPerPdfPerYear,
    int? maxPdfTextLengthPerPdfPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerDay,
    int? maxPdfTextLengthPerPdfPerPagePerMonth,
    int? maxPdfTextLengthPerPdfPerPagePerYear,
    int? maxPdfTextLengthPerPdfPerPagePerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerMonth,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerYear,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerMonthPerYear,
    int? maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerYearPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime,
    int? maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime,
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
      maxPdfTextLength: maxPdfTextLength ?? this.maxPdfTextLength,
      maxPdfTextLengthPerPage: maxPdfTextLengthPerPage ?? this.maxPdfTextLengthPerPage,
      maxPdfTextLengthPerDay: maxPdfTextLengthPerDay ?? this.maxPdfTextLengthPerDay,
      maxPdfTextLengthPerMonth: maxPdfTextLengthPerMonth ?? this.maxPdfTextLengthPerMonth,
      maxPdfTextLengthPerYear: maxPdfTextLengthPerYear ?? this.maxPdfTextLengthPerYear,
      maxPdfTextLengthPerLifetime: maxPdfTextLengthPerLifetime ?? this.maxPdfTextLengthPerLifetime,
      maxPdfTextLengthPerPdf: maxPdfTextLengthPerPdf ?? this.maxPdfTextLengthPerPdf,
      maxPdfTextLengthPerPdfPerPage: maxPdfTextLengthPerPdfPerPage ?? this.maxPdfTextLengthPerPdfPerPage,
      maxPdfTextLengthPerPdfPerDay: maxPdfTextLengthPerPdfPerDay ?? this.maxPdfTextLengthPerPdfPerDay,
      maxPdfTextLengthPerPdfPerMonth: maxPdfTextLengthPerPdfPerMonth ?? this.maxPdfTextLengthPerPdfPerMonth,
      maxPdfTextLengthPerPdfPerYear: maxPdfTextLengthPerPdfPerYear ?? this.maxPdfTextLengthPerPdfPerYear,
      maxPdfTextLengthPerPdfPerLifetime: maxPdfTextLengthPerPdfPerLifetime ?? this.maxPdfTextLengthPerPdfPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerDay: maxPdfTextLengthPerPdfPerPagePerDay ?? this.maxPdfTextLengthPerPdfPerPagePerDay,
      maxPdfTextLengthPerPdfPerPagePerMonth: maxPdfTextLengthPerPdfPerPagePerMonth ?? this.maxPdfTextLengthPerPdfPerPagePerMonth,
      maxPdfTextLengthPerPdfPerPagePerYear: maxPdfTextLengthPerPdfPerPagePerYear ?? this.maxPdfTextLengthPerPdfPerPagePerYear,
      maxPdfTextLengthPerPdfPerPagePerLifetime: maxPdfTextLengthPerPdfPerPagePerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerLifetime,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonth: maxPdfTextLengthPerPdfPerPagePerDayPerMonth ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerMonth,
      maxPdfTextLengthPerPdfPerPagePerDayPerYear: maxPdfTextLengthPerPdfPerPagePerDayPerYear ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerYear,
      maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: maxPdfTextLengthPerPdfPerPagePerDayPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerMonthPerYear: maxPdfTextLengthPerPdfPerPagePerMonthPerYear ?? this.maxPdfTextLengthPerPdfPerPagePerMonthPerYear,
      maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: maxPdfTextLengthPerPdfPerPagePerYearPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerYearPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime,
      maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime ?? this.maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime,
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
        debugPrint('_parseDateTime: Timestamp 타입');
        return value.toDate();
      }
      
      if (value is DateTime) {
        debugPrint('_parseDateTime: DateTime 타입');
        return value;
      }
      
      final dateStr = value.toString();
      debugPrint('_parseDateTime: 문자열 파싱 시도: $dateStr');
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('_parseDateTime 오류: $e');
      return DateTime.now();
    }
  }

  static SubscriptionTier _parseSubscriptionTier(dynamic value) {
    if (value == null) {
      debugPrint('_parseSubscriptionTier: null 값이 전달됨');
      return SubscriptionTier.free;
    }
    
    try {
      final stringValue = value.toString().toLowerCase();
      debugPrint('_parseSubscriptionTier: $stringValue');
      
      // 문자열에서 'SubscriptionTier.' 부분 제거
      final cleanValue = stringValue.replaceAll('subscriptiontier.', '');
      
      return SubscriptionTier.values.firstWhere(
        (e) => e.toString().toLowerCase().replaceAll('subscriptiontier.', '') == cleanValue,
        orElse: () {
          debugPrint('_parseSubscriptionTier: 일치하는 값 없음, 기본값 사용');
          return SubscriptionTier.free;
        },
      );
    } catch (e) {
      debugPrint('_parseSubscriptionTier 오류: $e');
      return SubscriptionTier.free;
    }
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) {
      debugPrint('_parseInt: null 값이 전달됨, 기본값 사용: $defaultValue');
      return defaultValue;
    }
    
    try {
      final result = int.parse(value.toString());
      debugPrint('_parseInt 성공: $result');
      return result;
    } catch (e) {
      debugPrint('_parseInt 오류: $e, 기본값 사용: $defaultValue');
      return defaultValue;
    }
  }
} 