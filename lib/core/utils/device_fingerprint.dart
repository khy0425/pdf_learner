import 'dart:html' as html;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 디바이스를 식별하기 위한 고유 지문을 생성하는 클래스
class DeviceFingerprint {
  // 로컬 스토리지 키
  static const String _deviceIdKey = 'device_fingerprint_id';
  static const String _usageCountKey = 'device_fingerprint_usage_count';
  
  // 단일 인스턴스 유지
  static DeviceFingerprint? _instance;
  static DeviceFingerprint get instance => _instance ??= DeviceFingerprint._();
  
  // 디바이스 ID와 사용 횟수
  String? _deviceId;
  int _usageCount = 0;
  
  // 생성자
  DeviceFingerprint._();
  
  /// 디바이스 ID 불러오기
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    try {
      // 저장된 ID가 있는지 확인
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString(_deviceIdKey);
      
      if (storedId != null && storedId.isNotEmpty) {
        _deviceId = storedId;
        return storedId;
      }
      
      // 없으면 새로 생성
      final newId = await _generateDeviceFingerprint();
      await prefs.setString(_deviceIdKey, newId);
      _deviceId = newId;
      return newId;
    } catch (e) {
      debugPrint('디바이스 ID 생성 오류: $e');
      // 오류 발생 시 랜덤 ID 반환
      final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
      _deviceId = fallbackId;
      return fallbackId;
    }
  }
  
  /// 사용 횟수 증가
  Future<int> incrementUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _usageCount = (prefs.getInt(_usageCountKey) ?? 0) + 1;
      await prefs.setInt(_usageCountKey, _usageCount);
      return _usageCount;
    } catch (e) {
      debugPrint('사용 횟수 증가 오류: $e');
      return ++_usageCount;
    }
  }
  
  /// 현재 사용 횟수 반환
  Future<int> getUsageCount() async {
    try {
      if (_usageCount > 0) return _usageCount;
      
      final prefs = await SharedPreferences.getInstance();
      _usageCount = prefs.getInt(_usageCountKey) ?? 0;
      return _usageCount;
    } catch (e) {
      debugPrint('사용 횟수 조회 오류: $e');
      return _usageCount;
    }
  }
  
  /// 사용 횟수 초기화
  Future<void> resetUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_usageCountKey, 0);
      _usageCount = 0;
    } catch (e) {
      debugPrint('사용 횟수 초기화 오류: $e');
    }
  }
  
  /// 디바이스 지문 생성
  Future<String> _generateDeviceFingerprint() async {
    try {
      if (!kIsWeb) {
        // 웹이 아닌 환경에서는 다른 식별자 사용 (이 부분은 플랫폼별로 구현 필요)
        return DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // 브라우저 정보 수집
      final browserData = <String, dynamic>{
        'userAgent': html.window.navigator.userAgent,
        'platform': html.window.navigator.platform,
        'language': html.window.navigator.language,
        'cookieEnabled': html.window.navigator.cookieEnabled,
        'screenWidth': html.window.screen?.width,
        'screenHeight': html.window.screen?.height,
        'colorDepth': html.window.screen?.colorDepth,
        'pixelRatio': html.window.devicePixelRatio,
        'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
      };
      
      // localStorage에 접근 가능한지 확인
      try {
        browserData['localStorageAvailable'] = html.window.localStorage.containsKey('test');
      } catch (e) {
        browserData['localStorageAvailable'] = false;
      }
      
      // 캔버스 지문 추가 (선택적)
      try {
        final canvas = html.CanvasElement(width: 200, height: 200);
        final context = canvas.context2D;
        
        // 캔버스에 텍스트와 도형 그리기
        context.textBaseline = 'top';
        context.font = '14px Arial';
        context.fillStyle = '#FF0000';
        context.fillRect(0, 0, 100, 100);
        context.fillStyle = '#00FF00';
        context.fillText('PDF Learner Fingerprint', 5, 15);
        context.fillStyle = '#0000FF';
        context.fillRect(100, 100, 50, 50);
        
        // 캔버스 데이터 URL로 변환
        browserData['canvasFingerprint'] = canvas.toDataUrl();
      } catch (e) {
        browserData['canvasFingerprint'] = 'not available';
      }
      
      // 수집된 데이터를 JSON으로 변환 후 해시
      final jsonData = jsonEncode(browserData);
      final bytes = utf8.encode(jsonData);
      final digest = sha256.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      debugPrint('디바이스 지문 생성 오류: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
} 