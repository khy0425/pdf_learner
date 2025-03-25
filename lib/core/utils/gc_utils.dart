import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// GC 관련 유틸리티 클래스
class GCUtils {
  static const _tag = 'GCUtils';
  
  static Timer? _memoryMonitorTimer;
  static const _monitoringInterval = Duration(minutes: 1);
  static const _gcThreshold = 100 * 1024 * 1024; // 100MB

  /// 메모리 사용량을 로그로 출력
  static void logMemoryUsage() {
    if (kDebugMode) {
      developer.log('현재 메모리 사용량: ${_getMemoryUsage()}MB', name: _tag);
    }
  }

  /// 메모리 사용량을 MB 단위로 반환
  static double _getMemoryUsage() {
    final usage = ProcessInfo.currentRss;
    return usage / (1024 * 1024);
  }

  /// 메모리 사용량이 임계값을 초과하는지 확인
  static bool isMemoryUsageHigh({double thresholdMB = 500}) {
    return _getMemoryUsage() > thresholdMB;
  }

  /// 강제로 GC 실행
  static Future<void> forceGC() async {
    if (kDebugMode) {
      developer.log('GC 실행 전 메모리: ${_getMemoryUsage()}MB', name: _tag);
    }
    
    // 메모리 해제를 위한 임시 객체 생성
    final temp = List.generate(1000000, (index) => 'temp$index');
    temp.clear();
    
    // GC 실행 유도
    await Future.delayed(Duration.zero);
    
    if (kDebugMode) {
      developer.log('GC 실행 후 메모리: ${_getMemoryUsage()}MB', name: _tag);
    }
  }

  /// 대용량 객체의 메모리 해제를 위한 dispose 메서드
  static void disposeLargeObject(Object? object) {
    if (object == null) return;
    
    if (object is List) {
      object.clear();
    } else if (object is Map) {
      object.clear();
    } else if (object is Set) {
      object.clear();
    }
    
    object = null;
  }

  /// 메모리 누수 방지를 위한 WeakReference 래퍼
  static WeakReference<T> createWeakReference<T>(T value) {
    return WeakReference(value);
  }

  /// 메모리 사용량 모니터링 시작
  static void startMemoryMonitoring() {
    if (!kDebugMode) return;

    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(_monitoringInterval, (timer) {
      _checkMemoryUsage();
    });
  }

  static void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  static void _checkMemoryUsage() {
    final info = PlatformDispatcher.instance.views.first.platformDispatcher;
    if (info.currentSystemFrameTimeStamp == null) return;

    debugPrint('메모리 사용량 확인 중...');
    // 실제 메모리 사용량 확인은 플랫폼별로 다르게 구현해야 함
  }
} 