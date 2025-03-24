import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService extends ChangeNotifier {
  final FirebaseAnalytics _analytics;
  bool _isInitialized = false;

  AnalyticsService(this._analytics);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _analytics.setAnalyticsCollectionEnabled(true);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.setUserId(id: userId);
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logSearch({
    required String searchTerm,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.logSearch(
      searchTerm: searchTerm,
      parameters: parameters,
    );
  }

  Future<void> logShare({
    required String contentType,
    String? itemId,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      parameters: parameters,
    );
  }
} 