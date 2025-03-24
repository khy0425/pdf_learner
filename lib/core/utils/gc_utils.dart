import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// GC 관련 유틸리티 클래스
class GCUtils {
  static const _tag = 'GCUtils';
  
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
  static void startMemoryMonitoring({Duration interval = const Duration(minutes: 1)}) {
    if (!kDebugMode) return;
    
    Timer.periodic(interval, (timer) {
      final usage = _getMemoryUsage();
      developer.log('메모리 모니터링: ${usage}MB', name: _tag);
      
      if (usage > 1000) { // 1GB 이상 사용 시 경고
        developer.log('메모리 사용량이 높습니다!', name: _tag);
      }
    });
  }
} 