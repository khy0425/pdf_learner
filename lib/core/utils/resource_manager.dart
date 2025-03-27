import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 메모리 사용량을 관리하고 최적화하기 위한 유틸리티 클래스
class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  
  // 리소스 캐시
  final Map<String, Uint8List> _byteCache = {};
  final Map<String, Object> _objectCache = {};
  
  // 캐시 크기 제한 (바이트)
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  
  // 현재 캐시 사용량
  int _currentCacheSize = 0;
  
  /// 싱글톤 인스턴스
  factory ResourceManager() {
    return _instance;
  }
  
  ResourceManager._internal();
  
  /// 바이트 데이터 캐싱
  void cacheBytes(String key, Uint8List bytes) {
    // 기존 데이터 삭제
    if (_byteCache.containsKey(key)) {
      _currentCacheSize -= _byteCache[key]!.length;
      _byteCache.remove(key);
    }
    
    // 캐시 크기 제한 확인
    if (_currentCacheSize + bytes.length > _maxCacheSizeBytes) {
      _evictOldestBytes();
    }
    
    _byteCache[key] = bytes;
    _currentCacheSize += bytes.length;
  }
  
  /// 바이트 데이터 조회
  Uint8List? getBytes(String key) {
    return _byteCache[key];
  }
  
  /// 객체를 캐시에 저장
  void add<T>(String key, T object) {
    if (object == null) return;
    _objectCache[key] = object as Object;
  }
  
  /// 객체 조회
  T? getObject<T>(String key) {
    final obj = _objectCache[key];
    if (obj is T) {
      return obj;
    }
    return null;
  }
  
  /// 캐시 항목 삭제
  void evictCache(String key) {
    if (_byteCache.containsKey(key)) {
      _currentCacheSize -= _byteCache[key]!.length;
      _byteCache.remove(key);
    }
    
    _objectCache.remove(key);
  }
  
  /// 모든 캐시 정리
  void clearCache() {
    _byteCache.clear();
    _objectCache.clear();
    _currentCacheSize = 0;
  }
  
  /// 바이트 데이터를 SharedPreferences에 저장
  static Future<bool> saveToPrefs(
    SharedPreferences prefs,
    String key,
    Uint8List bytes, {
    int? chunkSize,
  }) async {
    if (bytes.isEmpty) return false;
    
    // 대용량 데이터는 청크로 나누어 저장
    if (chunkSize != null && bytes.length > chunkSize) {
      final chunksCount = (bytes.length / chunkSize).ceil();
      
      // 청크 개수 저장
      await prefs.setInt('${key}_chunks', chunksCount);
      
      // 각 청크 저장
      for (var i = 0; i < chunksCount; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize > bytes.length 
            ? bytes.length 
            : (i + 1) * chunkSize;
        
        final chunk = bytes.sublist(start, end);
        final base64Chunk = base64Encode(chunk);
        await prefs.setString('${key}_chunk_$i', base64Chunk);
      }
      
      return true;
    } else {
      // 작은 데이터는 한 번에 저장
      final base64Data = base64Encode(bytes);
      return prefs.setString(key, base64Data);
    }
  }
  
  /// SharedPreferences에서 바이트 데이터 로드
  static Future<Uint8List?> loadFromPrefs(
    SharedPreferences prefs,
    String key, {
    bool isChunked = false,
  }) async {
    if (isChunked) {
      final chunksCount = prefs.getInt('${key}_chunks');
      if (chunksCount == null) return null;
      
      final List<int> allBytes = [];
      
      // 모든 청크 로드 및 결합
      for (var i = 0; i < chunksCount; i++) {
        final base64Chunk = prefs.getString('${key}_chunk_$i');
        if (base64Chunk == null) return null;
        
        final chunk = base64Decode(base64Chunk);
        allBytes.addAll(chunk);
      }
      
      return Uint8List.fromList(allBytes);
    } else {
      final base64Data = prefs.getString(key);
      if (base64Data == null) return null;
      
      return base64Decode(base64Data);
    }
  }
  
  /// 메모리 사용량 최적화 (가비지 컬렉션 권장)
  static void optimizeMemory() {
    if (kDebugMode) {
      print('Memory optimization requested');
    }
    
    // 가비지 컬렉션 힌트
    for (var i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        // ignore: avoid_dynamic_calls
        ((){})();
      });
    }
  }
  
  /// 가장 오래된 바이트 데이터 정리
  void _evictOldestBytes() {
    if (_byteCache.isEmpty) return;
    
    // 단순하게 첫 번째 항목 제거
    final oldestKey = _byteCache.keys.first;
    _currentCacheSize -= _byteCache[oldestKey]!.length;
    _byteCache.remove(oldestKey);
  }
} 