import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// 분석 이벤트의 종류
enum AnalyticsEventType {
  viewScreen,
  openDocument,
  addBookmark,
  removeBookmark,
  searchDocument,
  shareDocument,
  sortDocuments,
  deleteDocument,
  createDocument,
  changeTheme,
  error,
}

/// 분석 서비스 인터페이스
abstract class AnalyticsService {
  /// 이벤트 로깅
  Future<void> logEvent({
    required AnalyticsEventType eventType,
    Map<String, dynamic>? parameters,
  });

  /// 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  /// 화면 보기 이벤트 로깅
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// 사용자 ID 설정
  Future<void> setUserId(String? userId);

  /// 오류 로깅
  Future<void> logError({
    required String message,
    Map<String, dynamic>? parameters,
  });
}

/// 분석 서비스 구현체
@Injectable(as: AnalyticsService)
class AnalyticsServiceImpl implements AnalyticsService {
  // Firebase Analytics 등의 실제 분석 서비스 통합 가능

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