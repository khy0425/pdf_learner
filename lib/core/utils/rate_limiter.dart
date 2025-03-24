import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/security_logger.dart';
import 'dart:convert';

/// API 요청 속도 제한을 관리하는 클래스
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();
  
  // 각 기능별 제한 설정
  static const Map<String, ApiLimit> _defaultLimits = {
    'api_key_validation': ApiLimit(maxRequests: 5, windowSeconds: 60), // 1분에 5회
    'gemini_api': ApiLimit(maxRequests: 10, windowSeconds: 60), // 1분에 10회
    'document_upload': ApiLimit(maxRequests: 15, windowSeconds: 60), // 1분에 15회
    'login_attempt': ApiLimit(maxRequests: 5, windowSeconds: 300), // 5분에 5회
    'reset_password': ApiLimit(maxRequests: 3, windowSeconds: 300), // 5분에 3회
  };
  
  // 클라이언트별 요청 기록
  final Map<String, List<DateTime>> _requestTimestamps = {};
  
  // IP 주소별 상태 (차단된 IP 등)
  final Map<String, BlockStatus> _blockStatus = {};
  
  // 초기화 상태
  bool _isInitialized = false;
  
  // Firestore 인스턴스 (영구 저장용)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 보안 로거
  final SecurityLogger _securityLogger = SecurityLogger();
  
  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _securityLogger.initialize(
      logLevel: SecurityLogLevel.info,
      useFirestore: false,
    );
    
    // 차단 상태 로드
    await _loadBlockStatus();
    
    // 정기적인 정리 스케줄러 시작
    Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupOldRequests();
    });
    
    _isInitialized = true;
    
    debugPrint('RateLimiter 초기화 완료');
  }
  
  /// 요청이 속도 제한을 초과하는지 확인
  Future<bool> isRateLimited(String clientId, String actionType) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // 차단된 클라이언트 확인
    if (_blockStatus.containsKey(clientId)) {
      final status = _blockStatus[clientId]!;
      if (DateTime.now().isBefore(status.blockUntil)) {
        // 차단 상태 기록
        await _securityLogger.log(
          SecurityEvent.rateLimit,
          '차단된 클라이언트의 요청',
          level: SecurityLogLevel.warn,
          data: {
            'clientId': clientId, 
            'actionType': actionType,
            'remainingBlockTime': status.blockUntil.difference(DateTime.now()).inSeconds,
          },
        );
        return true; // 요청 제한됨
      } else {
        // 차단 해제
        _blockStatus.remove(clientId);
        await _saveBlockStatus();
      }
    }
    
    // 해당 액션 타입의 제한 설정 가져오기
    final limit = _defaultLimits[actionType] ?? 
        ApiLimit(maxRequests: 30, windowSeconds: 60); // 기본값: 1분에 30회
    
    // 클라이언트 ID에 대한 요청 기록 가져오기
    if (!_requestTimestamps.containsKey(clientId)) {
      _requestTimestamps[clientId] = [];
    }
    
    // 시간 창 내의 요청만 필터링
    final windowStart = DateTime.now().subtract(Duration(seconds: limit.windowSeconds));
    _requestTimestamps[clientId] = _requestTimestamps[clientId]!
        .where((timestamp) => timestamp.isAfter(windowStart))
        .toList();
    
    // 요청 수 확인
    final requestCount = _requestTimestamps[clientId]!.length;
    
    if (requestCount >= limit.maxRequests) {
      // 한도 초과, 과도한 요청 여부 확인
      if (requestCount >= limit.maxRequests * 2) {
        // 과도한 요청으로 일시적으로 차단
        await _blockClient(clientId, actionType, requestCount);
      }
      
      // 속도 제한 초과 로깅
      await _securityLogger.log(
        SecurityEvent.rateLimit,
        '속도 제한 초과',
        level: SecurityLogLevel.warn,
        data: {
          'clientId': clientId, 
          'actionType': actionType,
          'requestCount': requestCount,
          'limit': limit.maxRequests,
          'windowSeconds': limit.windowSeconds,
        },
      );
      
      return true; // 요청 제한됨
    }
    
    // 새 요청 기록
    _requestTimestamps[clientId]!.add(DateTime.now());
    
    return false; // 요청 허용됨
  }
  
  /// 클라이언트 일시 차단
  Future<void> _blockClient(String clientId, String actionType, int requestCount) async {
    // 차단 기간 계산 (요청 횟수에 따라 증가)
    int blockMinutes = requestCount ~/ 10; // 10회마다 1분씩 증가
    if (blockMinutes < 5) blockMinutes = 5; // 최소 5분
    if (blockMinutes > 60) blockMinutes = 60; // 최대 60분
    
    final blockUntil = DateTime.now().add(Duration(minutes: blockMinutes));
    
    _blockStatus[clientId] = BlockStatus(
      blockUntil: blockUntil,
      reason: '속도 제한 초과: $actionType',
      violationCount: (_blockStatus[clientId]?.violationCount ?? 0) + 1,
    );
    
    await _saveBlockStatus();
    
    // 심각한 위반 기록
    await _securityLogger.log(
      SecurityEvent.suspiciousActivity,
      '클라이언트 일시 차단됨',
      level: SecurityLogLevel.error,
      data: {
        'clientId': clientId, 
        'actionType': actionType,
        'blockMinutes': blockMinutes,
        'violationCount': _blockStatus[clientId]!.violationCount,
      },
      reportToAnalytics: true,
    );
  }
  
  /// 차단 상태 저장
  Future<void> _saveBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockData = _blockStatus.map((key, value) => MapEntry(
        key, {
          'blockUntil': value.blockUntil.millisecondsSinceEpoch,
          'reason': value.reason,
          'violationCount': value.violationCount,
        }
      ));
      
      await prefs.setString('rate_limiter_blocks', json.encode(blockData));
      
      // 심각한 위반은 Firestore에도 백업
      for (final entry in _blockStatus.entries) {
        if (entry.value.violationCount >= 3) {
          await _firestore.collection('security_blocks').doc(entry.key).set({
            'blockUntil': entry.value.blockUntil,
            'reason': entry.value.reason,
            'violationCount': entry.value.violationCount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('차단 상태 저장 오류: $e');
    }
  }
  
  /// 차단 상태 로드
  Future<void> _loadBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockDataJson = prefs.getString('rate_limiter_blocks');
      
      if (blockDataJson != null) {
        final blockData = json.decode(blockDataJson) as Map<String, dynamic>;
        
        _blockStatus.clear();
        blockData.forEach((key, value) {
          _blockStatus[key] = BlockStatus(
            blockUntil: DateTime.fromMillisecondsSinceEpoch(value['blockUntil']),
            reason: value['reason'],
            violationCount: value['violationCount'],
          );
        });
        
        // 만료된 차단 정리
        _cleanupExpiredBlocks();
      }
    } catch (e) {
      debugPrint('차단 상태 로드 오류: $e');
    }
  }
  
  /// 만료된 차단 정리
  void _cleanupExpiredBlocks() {
    final now = DateTime.now();
    _blockStatus.removeWhere((_, status) => now.isAfter(status.blockUntil));
  }
  
  /// 오래된 요청 기록 정리
  void _cleanupOldRequests() {
    final oldestToKeep = DateTime.now().subtract(const Duration(hours: 1));
    
    _requestTimestamps.forEach((clientId, timestamps) {
      _requestTimestamps[clientId] = timestamps
          .where((timestamp) => timestamp.isAfter(oldestToKeep))
          .toList();
    });
    
    // 빈 목록 제거
    _requestTimestamps.removeWhere((_, timestamps) => timestamps.isEmpty);
    
    // 만료된 차단 정리
    _cleanupExpiredBlocks();
  }
  
  /// 클라이언트 ID 생성 (디바이스 ID 또는 IP 주소 해싱)
  static String generateClientId(String identifier) {
    // 간단한 해싱 (실제 구현에서는 더 안전한 방법 사용)
    var hash = 0;
    for (var i = 0; i < identifier.length; i++) {
      hash = (hash + identifier.codeUnitAt(i)) % 0x7FFFFFFF;
    }
    return hash.toString();
  }
  
  /// 특정 클라이언트 차단 (관리자 기능)
  Future<void> blockClient(String clientId, String reason, int blockMinutes) async {
    final blockUntil = DateTime.now().add(Duration(minutes: blockMinutes));
    
    _blockStatus[clientId] = BlockStatus(
      blockUntil: blockUntil,
      reason: reason,
      violationCount: (_blockStatus[clientId]?.violationCount ?? 0) + 1,
      manualBlock: true,
    );
    
    await _saveBlockStatus();
    
    await _securityLogger.log(
      SecurityEvent.suspiciousActivity,
      '클라이언트 수동 차단됨',
      level: SecurityLogLevel.warn,
      data: {
        'clientId': clientId, 
        'reason': reason,
        'blockMinutes': blockMinutes,
      },
    );
  }
  
  /// 클라이언트 차단 해제 (관리자 기능)
  Future<void> unblockClient(String clientId) async {
    if (_blockStatus.containsKey(clientId)) {
      _blockStatus.remove(clientId);
      await _saveBlockStatus();
      
      await _securityLogger.log(
        SecurityEvent.userPreferenceChanged,
        '클라이언트 차단 해제됨',
        level: SecurityLogLevel.info,
        data: {'clientId': clientId},
      );
    }
  }
  
  /// 요청이 허용되는지 확인 (ViewModel에서 사용)
  Future<bool> checkRequest(String actionType) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // 클라이언트 ID는 'app_client'로 고정 (단일 클라이언트 환경)
    const clientId = 'app_client';
    
    // 제한 확인
    final isLimited = await isRateLimited(clientId, actionType);
    
    // 제한 결과 반환 (true = 허용, false = 제한)
    return !isLimited;
  }
}

/// API 제한 설정
class ApiLimit {
  final int maxRequests;  // 시간 창 내 최대 요청 수
  final int windowSeconds; // 시간 창 (초)
  
  const ApiLimit({
    required this.maxRequests, 
    required this.windowSeconds
  });
}

/// 차단 상태 클래스
class BlockStatus {
  final DateTime blockUntil;  // 차단 해제 시간
  final String reason;       // 차단 이유
  final int violationCount;  // 위반 횟수
  final bool manualBlock;    // 수동 차단 여부
  
  BlockStatus({
    required this.blockUntil, 
    required this.reason, 
    this.violationCount = 1,
    this.manualBlock = false,
  });
}

/// 요청 제한 유틸리티
class RateLimiter {
  final SharedPreferences _prefs;
  final Map<String, List<DateTime>> _requestHistory = {};
  final Map<String, int> _limits = {
    'ai_summary': 10, // 10회/시간
    'pdf_upload': 5,  // 5회/시간
    'pdf_delete': 20, // 20회/시간
  };
  final Map<String, Duration> _windows = {
    'ai_summary': const Duration(hours: 1),
    'pdf_upload': const Duration(hours: 1),
    'pdf_delete': const Duration(hours: 1),
  };
  
  /// 생성자
  RateLimiter(this._prefs);
  
  /// 요청 제한 확인
  Future<bool> checkRequest(String actionType) async {
    if (!_limits.containsKey(actionType)) {
      return true; // 제한이 없는 액션 타입
    }
    
    final now = DateTime.now();
    final limit = _limits[actionType]!;
    final window = _windows[actionType]!;
    
    // 요청 기록 가져오기
    final history = _getRequestHistory(actionType);
    
    // 윈도우 기간 이전의 기록 제거
    history.removeWhere((time) => now.difference(time) > window);
    
    // 제한 확인
    if (history.length >= limit) {
      return false;
    }
    
    // 요청 기록 추가
    history.add(now);
    _saveRequestHistory(actionType, history);
    
    return true;
  }
  
  /// 요청 기록 가져오기
  List<DateTime> _getRequestHistory(String actionType) {
    if (!_requestHistory.containsKey(actionType)) {
      final historyJson = _prefs.getStringList('rate_limit_$actionType') ?? [];
      _requestHistory[actionType] = historyJson
          .map((timeStr) => DateTime.parse(timeStr))
          .toList();
    }
    return _requestHistory[actionType]!;
  }
  
  /// 요청 기록 저장
  Future<void> _saveRequestHistory(String actionType, List<DateTime> history) async {
    final historyJson = history
        .map((time) => time.toIso8601String())
        .toList();
    await _prefs.setStringList('rate_limit_$actionType', historyJson);
    _requestHistory[actionType] = history;
  }
  
  /// 남은 요청 횟수 확인
  int getRemainingRequests(String actionType) {
    if (!_limits.containsKey(actionType)) {
      return -1; // 제한이 없는 액션 타입
    }
    
    final now = DateTime.now();
    final limit = _limits[actionType]!;
    final window = _windows[actionType]!;
    final history = _getRequestHistory(actionType);
    
    // 윈도우 기간 이전의 기록 제거
    history.removeWhere((time) => now.difference(time) > window);
    
    return limit - history.length;
  }
  
  /// 제한 초기화
  Future<void> resetLimits(String actionType) async {
    if (_requestHistory.containsKey(actionType)) {
      _requestHistory.remove(actionType);
    }
    await _prefs.remove('rate_limit_$actionType');
  }
  
  /// 모든 제한 초기화
  Future<void> resetAllLimits() async {
    _requestHistory.clear();
    for (final actionType in _limits.keys) {
      await _prefs.remove('rate_limit_$actionType');
    }
  }
} 