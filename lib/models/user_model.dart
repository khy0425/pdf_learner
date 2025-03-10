import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final String? apiKey;
  final DateTime? apiKeyExpiresAt;
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
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.subscriptionTier,
    this.subscriptionExpiresAt,
    this.apiKey,
    this.apiKeyExpiresAt,
    required this.usageCount,
    this.lastUsageAt,
    required this.maxUsagePerDay,
    required this.maxPdfSize,
    required this.maxTextLength,
    required this.maxPdfsPerDay,
    required this.maxPdfsTotal,
    required this.maxPdfPages,
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('UserModel.fromJson 시작: $json');
      
      // 필수 필드 검증
      if (json['id'] == null) {
        debugPrint('UserModel.fromJson 오류: id가 null입니다');
        throw Exception('사용자 ID가 없습니다');
      }
      
      // 기본값 설정
      final now = DateTime.now();
      
      // 구독 정보 안전하게 처리
      final subscriptionValue = json['subscriptionTier'] ?? json['subscription'] ?? 'free';
      debugPrint('구독 정보 원본 값: $subscriptionValue');
      
      // 사용자 정보 매핑
      final user = UserModel(
        id: json['id'].toString(),
        email: json['email']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '사용자',
        photoUrl: json['photoUrl']?.toString() ?? json['photoURL']?.toString() ?? '',
        createdAt: now,
        lastLoginAt: now,
        subscriptionTier: SubscriptionTier.free, // 기본값으로 설정
        subscriptionExpiresAt: null,
        apiKey: null,
        apiKeyExpiresAt: null,
        usageCount: 0,
        lastUsageAt: null,
        maxUsagePerDay: 10,
        maxPdfSize: 5 * 1024 * 1024,
        maxTextLength: 10000,
        maxPdfsPerDay: 5,
        maxPdfsTotal: 20,
        maxPdfPages: 50,
        maxPdfTextLength: 50000,
        maxPdfTextLengthPerPage: 1000,
        maxPdfTextLengthPerDay: 100000,
        maxPdfTextLengthPerMonth: 1000000,
        maxPdfTextLengthPerYear: 10000000,
        maxPdfTextLengthPerLifetime: 100000000,
        maxPdfTextLengthPerPdf: 10000,
        maxPdfTextLengthPerPdfPerPage: 1000,
        maxPdfTextLengthPerPdfPerDay: 100000,
        maxPdfTextLengthPerPdfPerMonth: 1000000,
        maxPdfTextLengthPerPdfPerYear: 10000000,
        maxPdfTextLengthPerPdfPerLifetime: 100000000,
        maxPdfTextLengthPerPdfPerPagePerDay: 10000,
        maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
        maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
        maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
        maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
      );
      
      debugPrint('UserModel.fromJson 완료: ${user.id}');
      return user;
    } catch (e, stackTrace) {
      debugPrint('UserModel.fromJson 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'subscriptionTier': subscriptionTier.toString(),
      'subscriptionExpiresAt': subscriptionExpiresAt != null 
          ? Timestamp.fromDate(subscriptionExpiresAt!)
          : null,
      'apiKey': apiKey,
      'apiKeyExpiresAt': apiKeyExpiresAt != null 
          ? Timestamp.fromDate(apiKeyExpiresAt!)
          : null,
      'usageCount': usageCount,
      'lastUsageAt': lastUsageAt != null 
          ? Timestamp.fromDate(lastUsageAt!)
          : null,
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
} 