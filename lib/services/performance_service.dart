import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService extends ChangeNotifier {
  final FirebasePerformance _performance;
  bool _isInitialized = false;
  final Map<String, Trace> _activeTraces = {};

  PerformanceService(this._performance);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _performance.setPerformanceCollectionEnabled(true);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startTrace(String traceName) async {
    if (!_isInitialized) {
      await initialize();
    }

    final trace = _performance.newTrace(traceName);
    await trace.start();
    _activeTraces[traceName] = trace;
  }

  Future<void> stopTrace(String traceName) async {
    final trace = _activeTraces.remove(traceName);
    if (trace != null) {
      await trace.stop();
    }
  }

  Future<void> addMetric(String traceName, String metricName, int value) async {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.setMetric(metricName, value);
    }
  }

  Future<void> addAttribute(String traceName, String attributeName, String value) async {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.setAttribute(attributeName, value);
    }
  }

  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
    _isInitialized = enabled;
    notifyListeners();
  }

  HttpMetric startHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  Future<void> stopHttpMetric(HttpMetric metric) async {
    await metric.stop();
  }
} 