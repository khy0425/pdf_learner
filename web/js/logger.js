/**
 * 로그 컨트롤러
 * Flutter 웹 앱에서 발생하는 불필요한 로그를 제어합니다.
 */

(function() {
  // 디버그 모드 (false로 설정하면 로그가 표시되지 않음)
  const isDebugMode = false;
  
  // 원본 콘솔 메서드 보존
  const originalConsole = {
    log: console.log,
    info: console.info,
    warn: console.warn,
    error: console.error,
    debug: console.debug
  };
  
  // 로그 필터링을 위한 패턴 (더 광범위하게 확장)
  const filterPatterns = [
    'Initializing Firebase',
    'TrustedTypes',
    'firebase',
    'Firebase',
    '[PDF Learner]',
    'flutter_target',
    'Flutter',
    'Created engine initializer',
    'first-frame',
    'chrome is moving',
    'Chrome is moving',
    'Violation',
    'timeout',
    'heap allocations',
    'Preloader',
    'Rendering engine',
    'rendering frame',
    'canvaskit',
    'favicon.ico',
    'font-family',
    'main.dart.js',
    'gis-dart'
  ];
  
  // Firebase 관련 로그인지 확인하는 함수 (더 엄격하게 체크)
  function shouldFilterLog(args) {
    if (!args || args.length === 0) return false;
    
    // 배열의 모든 요소 확인
    for (let i = 0; i < args.length; i++) {
      if (typeof args[i] === 'string') {
        const message = String(args[i]);
        if (filterPatterns.some(pattern => message.includes(pattern))) {
          return true;
        }
      } else if (typeof args[i] === 'object' && args[i] !== null) {
        // 객체를 문자열로 변환해서 확인
        try {
          const objStr = JSON.stringify(args[i]);
          if (filterPatterns.some(pattern => objStr.includes(pattern))) {
            return true;
          }
        } catch(e) {
          // 무시
        }
      }
    }
    
    return false;
  }
  
  // 콘솔 메서드 오버라이드
  if (!isDebugMode) {
    // 로그 숨기기
    console.log = function(...args) {
      if (!shouldFilterLog(args)) {
        originalConsole.log.apply(console, args);
      }
    };
    
    // 정보 숨기기
    console.info = function(...args) {
      if (!shouldFilterLog(args)) {
        originalConsole.info.apply(console, args);
      }
    };
    
    // 경고 - 중요할 수 있지만 불필요한 Firebase 경고는 필터링
    console.warn = function(...args) {
      if (!shouldFilterLog(args)) {
        originalConsole.warn.apply(console, args);
      }
    };
    
    // 오류 - 중요하지만 Firebase 관련 오류는 필터링
    console.error = function(...args) {
      if (!shouldFilterLog(args)) {
        originalConsole.error.apply(console, args);
      }
    };
    
    // 디버그 숨기기
    console.debug = function(...args) {
      if (!shouldFilterLog(args)) {
        originalConsole.debug.apply(console, args);
      }
    };
  }
  
  // 초기 로그 지우기
  console.clear();
  
  // 앱 로드 메시지 표시
  originalConsole.log('PDF Learner가 로드되었습니다.');
})(); 