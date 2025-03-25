import 'package:injectable/injectable.dart';

@singleton
class RateLimiter {
  final Map<String, DateTime> _lastRequestTime = {};
  final Duration _minInterval;

  RateLimiter({Duration? minInterval}) : _minInterval = minInterval ?? const Duration(seconds: 1);

  bool canMakeRequest(String key) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[key];
    
    if (lastRequest == null) {
      _lastRequestTime[key] = now;
      return true;
    }

    if (now.difference(lastRequest) >= _minInterval) {
      _lastRequestTime[key] = now;
      return true;
    }

    return false;
  }

  bool checkRequest(String key) {
    return canMakeRequest(key);
  }

  void reset(String key) {
    _lastRequestTime.remove(key);
  }

  void resetAll() {
    _lastRequestTime.clear();
  }
} 