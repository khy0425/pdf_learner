import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  
  /// 안전하게 문자열 값을 반환합니다.
  static String safeStringValue(dynamic value, [String defaultValue = '']) {
    if (value == null) {
      return defaultValue;
    }
    return value.toString();
  }
  
  /// 안전하게 정수 값을 반환합니다.
  static int safeIntValue(dynamic value, [int defaultValue = 0]) {
    if (value == null) {
      return defaultValue;
    }
    
    if (value is int) {
      return value;
    }
    
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }
  
  /// 안전하게 실수 값을 반환합니다.
  static double safeDoubleValue(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) {
      return defaultValue;
    }
    
    if (value is double) {
      return value;
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }
  
  /// 안전하게 불리언 값을 반환합니다.
  static bool safeBoolValue(dynamic value, [bool defaultValue = false]) {
    if (value == null) {
      return defaultValue;
    }
    
    if (value is bool) {
      return value;
    }
    
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    
    if (value is num) {
      return value != 0;
    }
    
    return defaultValue;
  }
  
  /// 안전하게 DateTime 값을 반환합니다.
  static DateTime? safeDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // 기본 파싱 실패 시 다양한 형식 시도
        final formats = [
          "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
          "yyyy-MM-dd'T'HH:mm:ss'Z'",
          "yyyy-MM-dd HH:mm:ss",
          "yyyy-MM-dd",
          "MM/dd/yyyy HH:mm:ss",
          "MM/dd/yyyy"
        ];
        
        for (final format in formats) {
          try {
            final dateFormat = DateFormat(format);
            return dateFormat.parse(value);
          } catch (_) {
            // 다음 형식 시도
            continue;
          }
        }
      }
    }
    
    if (value is int) {
      // 타임스탬프로 가정
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    return null;
  }
  
  /// 안전한 Timestamp 값 반환 (null이면 현재 시간 기준 Timestamp 반환)
  static DateTime safeTimestampValue(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        if (kDebugMode) {
          print('safeTimestampValue int 변환 오류: $e');
        }
        return DateTime.now();
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('safeTimestampValue String 변환 오류: $e');
        }
        return DateTime.now();
      }
    }
    if (value is Map && value.containsKey('_seconds')) {
      try {
        final seconds = value['_seconds'] as int;
        final nanoseconds = value['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      } catch (e) {
        if (kDebugMode) {
          print('safeTimestampValue Map 변환 오류: $e');
        }
        return DateTime.now();
      }
    }
    return DateTime.now();
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
} 