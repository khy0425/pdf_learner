/**
 * PDF Learner 로깅 유틸리티
 * 
 * 애플리케이션 로그를 관리하고 보안을 강화하는 유틸리티입니다.
 */

(function() {
  // 민감한 정보를 마스킹하는 유틸리티
  const maskSensitiveInfo = function(str) {
    if (!str || typeof str !== 'string') return str;
    
    // API 키 마스킹
    str = str.replace(/([A-Za-z0-9_-]{30,})/g, '***_API_KEY_MASKED_***');
    
    // 이메일 마스킹
    str = str.replace(/([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+)/gi, '***@***');
    
    // UID 마스킹 (Firebase UID 형식)
    str = str.replace(/([a-zA-Z0-9]{20,})/g, '***_UID_MASKED_***');
    
    return str;
  };
  
  // 로깅 설정
  const LoggingSettings = {
    enabled: false,
    maskSensitiveData: true,
    logToServer: false,
    errorLoggingEnabled: true,
    logLevel: 'info' // 'debug', 'info', 'warn', 'error'
  };
  
  // 로그 레벨 정의
  const LogLevels = {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3
  };
  
  // 전역 객체에 로거 생성
  window.AppLogger = {
    // 로깅 활성화/비활성화
    enableLogs: function(enabled) {
      LoggingSettings.enabled = !!enabled;
    },
    
    // 로그 레벨 설정
    setLogLevel: function(level) {
      if (LogLevels.hasOwnProperty(level)) {
        LoggingSettings.logLevel = level;
      }
    },
    
    // 민감 데이터 마스킹 설정
    setMaskSensitiveData: function(mask) {
      LoggingSettings.maskSensitiveData = !!mask;
    },
    
    // 기본 로그 함수
    log: function(message, ...args) {
      if (!LoggingSettings.enabled || LogLevels[LoggingSettings.logLevel] > LogLevels.debug) return;
      
      let logMessage = message;
      if (LoggingSettings.maskSensitiveData) {
        logMessage = maskSensitiveInfo(String(message));
      }
      
      console.log('[PDF Learner]', logMessage, ...args);
    },
    
    // 디버그 로그
    debug: function(message, ...args) {
      if (!LoggingSettings.enabled || LogLevels[LoggingSettings.logLevel] > LogLevels.debug) return;
      
      let logMessage = message;
      if (LoggingSettings.maskSensitiveData) {
        logMessage = maskSensitiveInfo(String(message));
      }
      
      console.debug('[PDF Learner]', logMessage, ...args);
    },
    
    // 정보 로그
    info: function(message, ...args) {
      if (!LoggingSettings.enabled || LogLevels[LoggingSettings.logLevel] > LogLevels.info) return;
      
      let logMessage = message;
      if (LoggingSettings.maskSensitiveData) {
        logMessage = maskSensitiveInfo(String(message));
      }
      
      console.info('[PDF Learner]', logMessage, ...args);
    },
    
    // 경고 로그
    warn: function(message, ...args) {
      if (!LoggingSettings.enabled || LogLevels[LoggingSettings.logLevel] > LogLevels.warn) return;
      
      let logMessage = message;
      if (LoggingSettings.maskSensitiveData) {
        logMessage = maskSensitiveInfo(String(message));
      }
      
      console.warn('[PDF Learner]', logMessage, ...args);
    },
    
    // 오류 로그
    error: function(message, error, ...args) {
      if (!LoggingSettings.enabled || !LoggingSettings.errorLoggingEnabled) return;
      
      let logMessage = message;
      if (LoggingSettings.maskSensitiveData) {
        logMessage = maskSensitiveInfo(String(message));
      }
      
      console.error('[PDF Learner]', logMessage, error, ...args);
      
      // 필요시 서버에 오류 로깅
      if (LoggingSettings.logToServer) {
        // 실제 환경에서는 서버에 오류 정보 전송
      }
    },
    
    // 서버 로깅 설정
    enableServerLogging: function(enabled) {
      LoggingSettings.logToServer = !!enabled;
    }
  };
  
  // 전역 콘솔 오버라이드 (선택 사항)
  if (false) { // 비활성화 상태로 시작
    const originalConsole = {
      log: console.log,
      debug: console.debug,
      info: console.info,
      warn: console.warn,
      error: console.error
    };
    
    // 안전한 콘솔 오버라이드
    console.log = function(...args) {
      if (LoggingSettings.maskSensitiveData) {
        const safeArgs = args.map(arg => 
          typeof arg === 'string' ? maskSensitiveInfo(arg) : arg
        );
        originalConsole.log.apply(console, safeArgs);
      } else {
        originalConsole.log.apply(console, args);
      }
    };
    
    // 다른 콘솔 메서드도 유사하게 오버라이드
  }
  
  // Firebase 로깅 제어 (Firebase 로드 후 실행)
  document.addEventListener('DOMContentLoaded', function() {
    // Firebase 로깅 설정 (Firebase가 로드된 후)
    setTimeout(function() {
      if (typeof firebase !== 'undefined') {
        try {
          // Firebase 디버그 로깅 비활성화 (실제 환경에 적합)
          if (typeof firebase.database !== 'undefined' && 
              typeof firebase.database().enableLogging === 'function') {
            firebase.database().enableLogging(false);
          }
          
          // 콘솔에 성공 메시지
          window.AppLogger.debug('Firebase 로깅 설정이 적용되었습니다.');
        } catch (e) {
          // 오류는 무시
        }
      }
    }, 1000);
  });
})(); 