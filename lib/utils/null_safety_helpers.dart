import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// null 안전성을 위한 유틸리티 클래스
class NullSafetyHelpers {
  /// 안전하게 함수 실행 (오류 발생 시 null 반환)
  static T? tryCatch<T>(T Function() function, {String? errorContext}) {
    try {
      return function();
    } catch (e) {
      if (errorContext != null) {
        debugPrint('오류 발생 ($errorContext): $e');
      }
      return null;
    }
  }
  
  /// null 또는 빈 문자열 체크
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }
  
  /// 안전한 문자열 변환
  static String safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
  
  /// 안전하게 JSON 값 가져오기
  static T? safeGet<T>(Map<String, dynamic>? json, String key, {T? defaultValue}) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is T) {
        return value;
      } else if (T == int && value is num) {
        return value.toInt() as T;
      } else if (T == double && value is num) {
        return value.toDouble() as T;
      } else if (T == String) {
        return value.toString() as T;
      } else if (T == bool && value is String) {
        return (value.toLowerCase() == 'true') as T;
      } else if (T == DateTime && value is String) {
        return DateTime.tryParse(value) as T?;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('JSON 값 가져오기 오류 ($key): $e');
      return defaultValue;
    }
  }
  
  /// null 안전 배열 변환
  static List<T> safeList<T>(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      try {
        return List<T>.from(value.where((item) => item is T));
      } catch (e) {
        debugPrint('리스트 변환 오류: $e');
      }
    }
    return [];
  }
  
  /// 객체가 처리할 수 있는지 안전하게 확인
  static bool safelyProceed(dynamic object) {
    return object != null;
  }
  
  /// nullable map에서 안전하게 값 가져오기
  static V? safeMapGet<K, V>(Map<K, V>? map, K key) {
    if (map == null) return null;
    return map[key];
  }
  
  /// 문자열 값을 안전하게 가져오기
  static String safeStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      return value.toString();
    } catch (e) {
      debugPrint('문자열 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// nullable 문자열 값을 안전하게 가져오기
  static String? safeStringValueNullable(dynamic value) {
    if (value == null) return null;
    
    try {
      return value.toString();
    } catch (e) {
      debugPrint('문자열 변환 오류: $e');
      return null;
    }
  }
  
  /// 정수 값을 안전하게 가져오기
  static int safeIntValue(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('정수 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// 실수 값을 안전하게 가져오기
  static double safeDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('실수 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// 불리언 값을 안전하게 가져오기
  static bool safeBoolValue(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is num) return value != 0;
      return defaultValue;
    } catch (e) {
      debugPrint('불리언 변환 오류: $e');
      return defaultValue;
    }
  }
  
  /// Firestore 타임스탬프를 안전하게 가져오기
  static DateTime safeTimestampValue(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    } catch (e) {
      debugPrint('타임스탬프 변환 오류: $e');
      return DateTime.now();
    }
  }
  
  /// DateTime을 안전하게 가져오기
  static DateTime safeDateTimeValue(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    } catch (e) {
      debugPrint('날짜 변환 오류: $e');
      return DateTime.now();
    }
  }
} 