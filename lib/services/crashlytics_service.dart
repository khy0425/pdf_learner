import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService extends ChangeNotifier {
  final FirebaseCrashlytics _crashlytics;
  bool _isInitialized = false;

  CrashlyticsService(this._crashlytics);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      information: information,
    );
  }

  Future<void> setUserIdentifier(String identifier) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _crashlytics.setUserIdentifier(identifier);
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _crashlytics.setCustomKey(key, value);
  }

  Future<void> log(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _crashlytics.log(message);
  }

  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    _isInitialized = enabled;
    notifyListeners();
  }
} 