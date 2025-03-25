import 'package:injectable/injectable.dart';

@injectable
class RateLimiter {
  final Map<String, DateTime> _lastAttempts = {};
  final Duration _cooldownPeriod;

  RateLimiter({Duration cooldownPeriod = const Duration(seconds: 1)})
      : _cooldownPeriod = cooldownPeriod;

  bool checkRequest(String key) {
    final lastAttempt = _lastAttempts[key];
    if (lastAttempt == null) return true;

    final now = DateTime.now();
    if (now.difference(lastAttempt) >= _cooldownPeriod) {
      _lastAttempts[key] = now;
      return true;
    }

    return false;
  }

  void recordAttempt(String key) {
    _lastAttempts[key] = DateTime.now();
  }

  void reset(String key) {
    _lastAttempts.remove(key);
  }

  void resetAll() {
    _lastAttempts.clear();
  }
} 