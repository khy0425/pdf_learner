import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../firebase/firebase_service.dart';
import 'analytics_service.dart';

/// 분석 서비스 구현체
@Injectable(as: AnalyticsService)
class AnalyticsServiceImpl implements AnalyticsService {
  final FirebaseService _firebaseService;
  
  // 생성자
  AnalyticsServiceImpl({required FirebaseService firebaseService}) 
    : _firebaseService = firebaseService;

  @override
  Future<void> logEvent({
    required AnalyticsEventType eventType,
    Map<String, dynamic>? parameters,
  }) async {
    // 실제 구현에서는 Firebase Analytics 등으로 이벤트 전송
    debugPrint('Analytics - Event: ${eventType.name}, Parameters: $parameters');
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    debugPrint('Analytics - User Property: $name = $value');
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    debugPrint('Analytics - Screen View: $screenName, Class: $screenClass');
  }

  @override
  Future<void> setUserId(String? userId) async {
    debugPrint('Analytics - Set User ID: $userId');
  }

  @override
  Future<void> logError({
    required String message,
    Map<String, dynamic>? parameters,
  }) async {
    debugPrint('Analytics - Error: $message, Details: $parameters');
  }
} 