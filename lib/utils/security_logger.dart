import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
import 'dart:async';

/// 보안 이벤트 로깅을 담당하는 클래스
class SecurityLogger {
  static final SecurityLogger _instance = SecurityLogger._internal();
  factory SecurityLogger() => _instance;
  SecurityLogger._internal();
  
  static const String _logPrefix = 'security_log_';
  static const int _maxLocalLogEntries = 100;
  static const int _maxRetentionDays = 30;
  
  /// 로그 수준 설정
  SecurityLogLevel _logLevel = SecurityLogLevel.info;
  
  /// Firestore 사용 설정
  bool _useFirestore = false;
  
  /// 로컬 파일 로깅 설정
  bool _useLocalFile = false;
  
  /// 초기화 상태
  bool _isInitialized = false;
  
  /// 초기화 상태를 반환하는 getter
  bool get isInitialized => _isInitialized;
  
  /// 배치 처리를 위한 로그 저장소
  final List<Map<String, dynamic>> _logBatch = [];
  
  /// 배치 처리 타이머
  Timer? _batchTimer;
  
  /// 배치 처리 설정
  bool _useBatchProcessing = true;
  int _batchSize = 10;  // 이 개수 이상이면 강제로 배치 처리
  int _batchIntervalSeconds = 30;  // 배치 처리 간격 (초)
  
  /// 메모리 캐시
  final List<Map<String, dynamic>> _memoryCache = [];
  
  /// 초기화 메서드
  Future<void> initialize({
    SecurityLogLevel logLevel = SecurityLogLevel.info,
    bool useFirestore = false,
    bool useLocalFile = !kIsWeb,
    bool anonymizeIpAddress = true,
    bool useBatchProcessing = true,
    int batchSize = 10,
    int batchIntervalSeconds = 30,
  }) async {
    _logLevel = logLevel;
    _useFirestore = useFirestore;
    _useLocalFile = useLocalFile && !kIsWeb;
    _useBatchProcessing = useBatchProcessing;
    _batchSize = batchSize;
    _batchIntervalSeconds = batchIntervalSeconds;
    
    if (_useLocalFile) {
      await _createLogFileIfNeeded();
    }
    
    // 배치 처리 타이머 시작
    if (_useBatchProcessing) {
      _startBatchTimer();
    }
    
    _isInitialized = true;
    
    // 앱 시작 로그
    log(
      SecurityEvent.appStarted,
      'Application started', 
      level: SecurityLogLevel.info,
    );
    
    // 정기적인 캐시 정리 타이머 시작
    _startCacheCleanupTimer();
    
    debugPrint('SecurityLogger 초기화 완료: 로그 레벨=$_logLevel, Firestore=$_useFirestore, 로컬 파일=$_useLocalFile, 배치 처리=$_useBatchProcessing');
  }
  
  /// 로그 기록 메서드
  Future<void> log(
    SecurityEvent event, 
    String message, {
    SecurityLogLevel level = SecurityLogLevel.info,
    Map<String, dynamic>? data,
    bool reportToAnalytics = false,
    bool reportToCrashlytics = false,
    bool forceSave = false,
  }) async {
    // 로그 레벨이 현재 설정보다 낮으면 로깅 X
    if (level.index < _logLevel.index) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    final timestamp = DateTime.now();
    final userId = _getCurrentUserId() ?? 'anonymous';
    final logEntry = {
      'timestamp': timestamp.toIso8601String(),
      'event': event.toString().split('.').last,
      'level': level.toString().split('.').last,
      'message': message,
      'userId': userId,
      'data': data ?? {},
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'sessionId': _getSessionId(),
    };
    
    // 디버그 콘솔에 출력
    _printLog(level, event, message, data);
    
    // 메모리 캐시에 추가
    _memoryCache.add(logEntry);
    if (_memoryCache.length > _maxLocalLogEntries) {
      _memoryCache.removeAt(0);  // 가장 오래된 항목 제거
    }
    
    // Firebase Analytics 전송 (설정된 경우)
    if (reportToAnalytics) {
      await _sendToAnalytics(event, message, data);
    }
    
    // Firebase Crashlytics 전송 (설정된 경우)
    if (reportToCrashlytics && level == SecurityLogLevel.error) {
      await _reportToCrashlytics(event, message, data);
    }
    
    // 배치 처리 사용 중이고 강제 저장이 아닌 경우
    if (_useBatchProcessing && !forceSave) {
      // 배치 큐에 추가
      _logBatch.add(logEntry);
      
      // 배치 크기 초과 시 즉시 처리
      if (_logBatch.length >= _batchSize) {
        await _processBatch();
      }
      
      return;
    }
    
    // 배치 처리를 사용하지 않거나 강제 저장인 경우 바로 저장
    // SharedPreferences에 저장 (간단한 보관용)
    await _storeInPrefs(logEntry);
    
    // Firestore에 저장 (설정된 경우)
    if (_useFirestore) {
      await _saveToFirestore(logEntry);
    }
    
    // 로컬 파일에 저장 (웹이 아니고 설정된 경우)
    if (_useLocalFile) {
      await _writeToLogFile(logEntry);
    }
  }
  
  /// 배치 처리 타이머 시작
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(Duration(seconds: _batchIntervalSeconds), (_) async {
      if (_logBatch.isNotEmpty) {
        await _processBatch();
      }
    });
  }
  
  /// 캐시 정리 타이머 시작
  void _startCacheCleanupTimer() {
    Timer.periodic(const Duration(hours: 12), (_) async {
      await _cleanupOldLogs();
    });
  }
  
  /// 배치 로그 처리
  Future<void> _processBatch() async {
    if (_logBatch.isEmpty) return;
    
    final batchToProcess = List<Map<String, dynamic>>.from(_logBatch);
    _logBatch.clear();
    
    try {
      // SharedPreferences에 저장 (간단한 보관용)
      await _storeInPrefsBatch(batchToProcess);
      
      // Firestore에 저장 (설정된 경우)
      if (_useFirestore) {
        await _saveToFirestoreBatch(batchToProcess);
      }
      
      // 로컬 파일에 저장 (웹이 아니고 설정된 경우)
      if (_useLocalFile) {
        await _writeToLogFileBatch(batchToProcess);
      }
    } catch (e) {
      debugPrint('배치 로그 처리 오류: $e');
    }
  }
  
  /// 콘솔에 로그 출력
  void _printLog(SecurityLogLevel level, SecurityEvent event, String message, Map<String, dynamic>? data) {
    final emoji = _getLogLevelEmoji(level);
    final timestamp = DateTime.now().toIso8601String();
    final eventName = event.toString().split('.').last;
    
    debugPrint('$emoji [$timestamp] $eventName: $message ${data != null ? '| 데이터: $data' : ''}');
  }
  
  /// 로그 레벨별 이모지 표시
  String _getLogLevelEmoji(SecurityLogLevel level) {
    switch (level) {
      case SecurityLogLevel.debug:
        return '🔍';
      case SecurityLogLevel.info:
        return '📘';
      case SecurityLogLevel.warn:
        return '⚠️';
      case SecurityLogLevel.error:
        return '❌';
      case SecurityLogLevel.critical:
        return '🚨';
    }
  }
  
  /// SharedPreferences에 로그 저장
  Future<void> _storeInPrefs(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_logPrefix}${DateTime.now().millisecondsSinceEpoch}';
      
      await prefs.setString(key, jsonEncode(logEntry));
    } catch (e) {
      debugPrint('로그 저장 오류: $e');
    }
  }
  
  /// SharedPreferences에 배치 로그 저장
  Future<void> _storeInPrefsBatch(List<Map<String, dynamic>> logEntries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 로그 항목별로 고유 키 생성하여 저장
      for (final logEntry in logEntries) {
        final key = '${_logPrefix}${DateTime.now().millisecondsSinceEpoch}_${logEntries.indexOf(logEntry)}';
        await prefs.setString(key, jsonEncode(logEntry));
      }
      
      // 오래된 로그 정리
      await _cleanupOldLogs();
    } catch (e) {
      debugPrint('배치 로그 저장 오류: $e');
    }
  }
  
  /// 오래된 로그 정리
  Future<void> _cleanupOldLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((k) => k.startsWith(_logPrefix)).toList();
      
      if (allKeys.length <= _maxLocalLogEntries) return;
      
      // 오래된 항목 삭제 (시간순 정렬)
      allKeys.sort();
      final keysToRemove = allKeys.sublist(0, allKeys.length - _maxLocalLogEntries);
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      // Firestore에서 오래된 로그 삭제 (1개월 이상)
      if (_useFirestore) {
        final cutoffDate = DateTime.now().subtract(Duration(days: _maxRetentionDays));
        await _removeOldFirestoreLogs(cutoffDate);
      }
      
      // 로컬 파일 로그도 정리
      if (_useLocalFile) {
        await _cleanupOldLogFiles();
      }
    } catch (e) {
      debugPrint('로그 정리 오류: $e');
    }
  }
  
  /// Firestore에 로그 저장
  Future<void> _saveToFirestore(Map<String, dynamic> logEntry) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('security_logs').add(logEntry);
    } catch (e) {
      debugPrint('Firestore 로그 저장 오류: $e');
    }
  }
  
  /// Firestore에 배치 로그 저장
  Future<void> _saveToFirestoreBatch(List<Map<String, dynamic>> logEntries) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      for (final logEntry in logEntries) {
        final docRef = firestore.collection('security_logs').doc();
        batch.set(docRef, logEntry);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore 배치 로그 저장 오류: $e');
    }
  }
  
  /// Firestore에서 오래된 로그 삭제
  Future<void> _removeOldFirestoreLogs(DateTime cutoffDate) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final oldLogs = await firestore.collection('security_logs')
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .limit(100)  // 한 번에 100개씩 처리
          .get();
      
      // 삭제할 문서가 있는 경우
      if (oldLogs.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in oldLogs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // 아직 더 있을 수 있으므로 재귀적으로 호출
        if (oldLogs.docs.length == 100) {
          await _removeOldFirestoreLogs(cutoffDate);
        }
      }
    } catch (e) {
      debugPrint('Firestore 오래된 로그 삭제 오류: $e');
    }
  }
  
  /// 로컬 로그 파일 생성
  Future<void> _createLogFileIfNeeded() async {
    if (kIsWeb) return;
    
    try {
      final logFile = await _getLogFile();
      if (!await logFile.exists()) {
        await logFile.create(recursive: true);
        
        // 헤더 작성
        await logFile.writeAsString(
          'timestamp,event,level,message,userId,sessionId\n'
        );
      }
    } catch (e) {
      debugPrint('로그 파일 생성 오류: $e');
    }
  }
  
  /// 로그 파일 가져오기
  Future<File> _getLogFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName = 'security_log_${now.year}${now.month.toString().padLeft(2, '0')}.csv';
    return File('${appDir.path}/logs/$fileName');
  }
  
  /// 오래된 로그 파일 정리
  Future<void> _cleanupOldLogFiles() async {
    if (kIsWeb) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');
      
      if (!await logsDir.exists()) return;
      
      final files = await logsDir.list().toList();
      
      // 보관 기간을 초과한 CSV 파일 삭제
      final now = DateTime.now();
      final cutoffDate = DateTime(now.year, now.month - _maxRetentionDays, now.day);
      
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.csv')) {
          final fileName = entity.path.split('/').last;
          if (fileName.startsWith('security_log_')) {
            try {
              // 파일명에서 년월 추출 (예: security_log_202308.csv)
              final dateStr = fileName.substring('security_log_'.length, 'security_log_'.length + 6);
              final year = int.parse(dateStr.substring(0, 4));
              final month = int.parse(dateStr.substring(4, 6));
              
              final fileDate = DateTime(year, month, 1);
              if (fileDate.isBefore(cutoffDate)) {
                await entity.delete();
                debugPrint('오래된 로그 파일 삭제: ${entity.path}');
              }
            } catch (e) {
              debugPrint('파일명 파싱 오류: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('로그 파일 정리 오류: $e');
    }
  }
  
  /// 로그 파일에 기록
  Future<void> _writeToLogFile(Map<String, dynamic> logEntry) async {
    if (kIsWeb) return;
    
    try {
      final logFile = await _getLogFile();
      final line = '${logEntry['timestamp']},${logEntry['event']},${logEntry['level']},"${_escapeCsvField(logEntry['message'])}",${logEntry['userId']},${logEntry['sessionId']}\n';
      
      await logFile.writeAsString(
        line,
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('로그 파일 기록 오류: $e');
    }
  }
  
  /// 로그 파일에 배치 기록
  Future<void> _writeToLogFileBatch(List<Map<String, dynamic>> logEntries) async {
    if (kIsWeb) return;
    
    try {
      final logFile = await _getLogFile();
      final buffer = StringBuffer();
      
      for (final logEntry in logEntries) {
        buffer.write('${logEntry['timestamp']},${logEntry['event']},${logEntry['level']},"${_escapeCsvField(logEntry['message'])}",${logEntry['userId']},${logEntry['sessionId']}\n');
      }
      
      await logFile.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('로그 파일 배치 기록 오류: $e');
    }
  }
  
  /// CSV 필드 이스케이프
  String _escapeCsvField(String field) {
    return field.replaceAll('"', '""');
  }
  
  /// Firebase Analytics 전송
  Future<void> _sendToAnalytics(SecurityEvent event, String message, Map<String, dynamic>? data) async {
    try {
      final analytics = FirebaseAnalytics.instance;
      final eventName = 'security_${event.toString().split('.').last.toLowerCase()}';
      
      // 이벤트 이름 검증 (Firebase Analytics 제한: 최대 40자, 영숫자와 밑줄만)
      final validEventName = eventName.length > 40 
        ? eventName.substring(0, 40) 
        : eventName;
      
      await analytics.logEvent(
        name: validEventName,
        parameters: {
          'message': message,
          ...(data ?? {}),
        },
      );
    } catch (e) {
      debugPrint('Analytics 전송 오류: $e');
    }
  }
  
  /// Firebase Crashlytics 보고
  Future<void> _reportToCrashlytics(SecurityEvent event, String message, Map<String, dynamic>? data) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      
      // 사용자 식별 정보 설정
      final userId = _getCurrentUserId();
      if (userId != null) {
        await crashlytics.setUserIdentifier(userId);
      }
      
      // 이벤트 정보 기록
      await crashlytics.setCustomKey('security_event', event.toString().split('.').last);
      
      // 추가 데이터 기록
      if (data != null) {
        for (final entry in data.entries) {
          if (entry.value is String || 
              entry.value is num || 
              entry.value is bool) {
            await crashlytics.setCustomKey(entry.key, entry.value.toString());
          }
        }
      }
      
      // 오류 기록
      await crashlytics.recordError(
        Exception(message), 
        StackTrace.current,
        reason: 'Security Event: ${event.toString().split('.').last}',
      );
    } catch (e) {
      debugPrint('Crashlytics 보고 오류: $e');
    }
  }
  
  /// 현재 로그인된 사용자 ID 가져오기
  String? _getCurrentUserId() {
    try {
      final auth = FirebaseAuth.instance;
      return auth.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }
  
  /// 현재 세션 ID 가져오기
  String _getSessionId() {
    try {
      if (_sessionId.isEmpty) {
        _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      return _sessionId;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
  
  // 현재 세션 ID
  static String _sessionId = '';
  
  /// 모든 로그 가져오기
  Future<List<Map<String, dynamic>>> getAllLogs() async {
    try {
      // 먼저 메모리 캐시의 로그를 가져옴
      final allLogs = List<Map<String, dynamic>>.from(_memoryCache);
      
      // SharedPreferences에서 추가 로그 가져오기
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
        .where((k) => k.startsWith(_logPrefix))
        .toList();
      
      for (final key in keys) {
        final logJson = prefs.getString(key);
        if (logJson != null) {
          try {
            final log = jsonDecode(logJson);
            // 중복 검사 (같은 timestamp와 message가 있으면 중복으로 간주)
            if (!allLogs.any((existingLog) => 
                existingLog['timestamp'] == log['timestamp'] && 
                existingLog['message'] == log['message'])) {
              allLogs.add(Map<String, dynamic>.from(log));
            }
          } catch (e) {
            debugPrint('로그 파싱 오류: $e');
          }
        }
      }
      
      // 시간순 정렬
      allLogs.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      
      return allLogs;
    } catch (e) {
      debugPrint('로그 조회 오류: $e');
      return [];
    }
  }
  
  /// 특정 이벤트에 대한 로그 가져오기
  Future<List<Map<String, dynamic>>> getLogsByEvent(SecurityEvent event) async {
    final allLogs = await getAllLogs();
    final eventName = event.toString().split('.').last;
    
    return allLogs.where((log) => log['event'] == eventName).toList();
  }
  
  /// 특정 사용자의 로그 가져오기
  Future<List<Map<String, dynamic>>> getLogsByUser(String userId) async {
    final allLogs = await getAllLogs();
    return allLogs.where((log) => log['userId'] == userId).toList();
  }
  
  /// 특정 기간의 로그 가져오기
  Future<List<Map<String, dynamic>>> getLogsByDateRange(DateTime start, DateTime end) async {
    final allLogs = await getAllLogs();
    
    return allLogs.where((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      return timestamp.isAfter(start) && timestamp.isBefore(end);
    }).toList();
  }
  
  /// 로그 내보내기 (CSV 형식)
  Future<String> exportLogsAsCsv() async {
    final allLogs = await getAllLogs();
    final StringBuffer csv = StringBuffer();
    
    // 헤더 추가
    csv.writeln('timestamp,event,level,message,userId,platform,sessionId');
    
    // 데이터 행 추가
    for (final log in allLogs) {
      csv.writeln(
        '${log['timestamp']},'
        '${log['event']},'
        '${log['level']},'
        '"${_escapeCsvField(log['message'])}",'
        '${log['userId']},'
        '${log['platform']},'
        '${log['sessionId']}'
      );
    }
    
    return csv.toString();
  }
  
  /// 로그 삭제
  Future<void> clearLogs() async {
    try {
      // 배치 처리 대기 중인 로그 강제 처리
      if (_useBatchProcessing && _logBatch.isNotEmpty) {
        await _processBatch();
      }
      
      // 메모리 캐시 비우기
      _memoryCache.clear();
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_logPrefix)).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('로컬 로그 삭제 완료');
    } catch (e) {
      debugPrint('로그 삭제 오류: $e');
    }
  }
  
  /// 애플리케이션 종료 시 호출 (배치 처리 대기 중인 로그 강제 처리)
  Future<void> flushLogs() async {
    if (_useBatchProcessing && _logBatch.isNotEmpty) {
      await _processBatch();
    }
    
    _batchTimer?.cancel();
    debugPrint('SecurityLogger: 배치 처리 타이머 취소 및 로그 저장 완료');
  }
  
  /// 배치 설정 변경
  void setBatchConfig({int? batchSize, int? batchIntervalSeconds}) {
    if (batchSize != null && batchSize > 0) {
      _batchSize = batchSize;
    }
    
    if (batchIntervalSeconds != null && batchIntervalSeconds > 0) {
      _batchIntervalSeconds = batchIntervalSeconds;
      // 타이머 재시작
      _startBatchTimer();
    }
  }
  
  /// 로그 레벨 변경
  void setLogLevel(SecurityLogLevel level) {
    _logLevel = level;
    debugPrint('SecurityLogger: 로그 레벨 변경됨 -> $level');
  }
  
  /// 로그 저장소 통계 정보 가져오기
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      final allLogs = await getAllLogs();
      
      // 레벨별 개수
      final levelCounts = <String, int>{};
      for (final log in allLogs) {
        final level = log['level'] as String;
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;
      }
      
      // 이벤트별 개수
      final eventCounts = <String, int>{};
      for (final log in allLogs) {
        final event = log['event'] as String;
        eventCounts[event] = (eventCounts[event] ?? 0) + 1;
      }
      
      // 날짜별 개수
      final dateCounts = <String, int>{};
      for (final log in allLogs) {
        final timestamp = log['timestamp'] as String;
        final date = timestamp.split('T')[0];
        dateCounts[date] = (dateCounts[date] ?? 0) + 1;
      }
      
      return {
        'totalLogs': allLogs.length,
        'batchPending': _logBatch.length,
        'memoryCacheSize': _memoryCache.length,
        'levelCounts': levelCounts,
        'eventCounts': eventCounts,
        'dateCounts': dateCounts,
        'oldestLog': allLogs.isNotEmpty ? allLogs.first['timestamp'] : null,
        'newestLog': allLogs.isNotEmpty ? allLogs.last['timestamp'] : null,
      };
    } catch (e) {
      debugPrint('로그 통계 정보 계산 오류: $e');
      return {
        'error': e.toString(),
        'totalLogs': 0,
        'batchPending': _logBatch.length,
      };
    }
  }
}

/// 보안 로그 수준 열거형
enum SecurityLogLevel {
  debug,    // 디버그용 상세 정보
  info,     // 일반 정보
  warn,     // 경고
  error,    // 오류
  critical, // 심각한 오류
}

/// 보안 이벤트 열거형
enum SecurityEvent {
  // 애플리케이션 이벤트
  appStarted,
  appPaused,
  appResumed,
  appClosed,
  
  // 인증 관련 이벤트
  loginAttempt,
  loginSuccess,
  loginFailed,
  logoutSuccess,
  passwordReset,
  passwordChanged,
  registrationAttempt,
  registrationSuccess,
  registrationFailed,
  
  // API 키 관련 이벤트
  apiKeyAdded,
  apiKeyVerified,
  apiKeyRemoved,
  apiKeyFailed,
  
  // PDF 관련 이벤트
  pdfUploaded,
  pdfOpened,
  pdfPermissionDenied,
  pdfExported,
  pdfDeleted,
  
  // AI 관련 이벤트
  aiRequestSent,
  aiResponseReceived,
  aiQuotaExceeded,
  aiServiceDown,
  
  // 결제 관련 이벤트
  subscriptionStarted,
  subscriptionRenewed,
  subscriptionCancelled,
  paymentSuccess,
  paymentFailed,
  
  // 보안 관련 이벤트
  suspiciousActivity,
  rateLimit,
  invalidInput,
  xssAttempt,
  sqlInjectionAttempt,
  forbiddenAccess,
  dataAccessDenied,
  
  // 기타 이벤트
  exportStarted,
  exportCompleted,
  importStarted,
  importCompleted,
  userPreferenceChanged,
  
  // 심각한 보안 이벤트
  userDataExfiltration,
  unauthorizedDataAccess,
  apiKeyCompromised,
} 