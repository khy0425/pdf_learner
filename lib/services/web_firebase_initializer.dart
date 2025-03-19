import '../utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:js/js.dart';
import 'package:pdf_learner/models/user_model.dart';
import 'package:pdf_learner/models/user.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';

/// 민감한 정보를 안전하게 로깅하는 함수
void secureLog(String message, {bool isSensitive = false}) {
  if (kDebugMode) {
    if (isSensitive) {
      // 민감한 정보는 마스킹 처리
      debugPrint('🔒 [보안] 민감한 정보 로깅 (마스킹됨)');
    } else {
      debugPrint('📝 $message');
    }
  }
}

/// 웹 환경에서 Firebase를 초기화하는 서비스
class WebFirebaseInitializer {
  static final WebFirebaseInitializer _instance = WebFirebaseInitializer._internal();
  factory WebFirebaseInitializer() => _instance;
  WebFirebaseInitializer._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool _isInitializing = false; // 초기화 진행 중 여부
  
  // 로그인 상태 관련 변수
  bool _isUserLoggedIn = false;
  String? _userId;
  
  bool get isUserLoggedIn => _isUserLoggedIn;
  String? get userId => _userId;
  
  // 초기화 완료를 기다리는 Completer
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationComplete => _initializationCompleter.future;

  // 상태 업데이트를 위한 리스너
  final List<Function(bool, bool, String?)> _listeners = [];
  
  // 서비스별 초기화 상태 추적
  final Map<String, bool> _serviceInitialized = {
    'core': false,
    'auth': false,
    'firestore': false,
    'storage': false,
    'analytics': false,
  };

  /// 환경 변수에서 값을 가져오는 헬퍼 메서드
  static String _getEnvValue(String key) {
    final value = dotenv.env[key];
    // 민감한 정보는 로그에 출력하지 않음
    if (key.contains('KEY') || key.contains('ID') || key.contains('SECRET')) {
      debugPrint('환경 변수 $key: ${value != null ? "값 있음" : "값 없음"}');
    } else {
      debugPrint('환경 변수 $key: ${value ?? "값 없음"}');
    }
    if (value == null || value.isEmpty) return '';
    // 따옴표 제거
    final cleanValue = value.replaceAll('"', '');
    return cleanValue;
  }

  /// JavaScript에서 Firebase 상태 확인
  bool checkFirebaseStatusFromJS() {
    if (!kIsWeb) return false;
    
    try {
      // JavaScript 환경 확인
      if (js.context == null) {
        debugPrint('JavaScript 컨텍스트가 존재하지 않습니다.');
        return false;
      }
      
      // JavaScript 함수 존재 확인
      final hasFunction = js.context.hasProperty('pdfl') && 
                         js.context['pdfl'].hasProperty('checkFirebaseStatus');
      if (!hasFunction) {
        debugPrint('pdfl.checkFirebaseStatus 함수가 JavaScript에 존재하지 않습니다.');
        return false;
      }
      
      // JavaScript 함수 호출
      final dynamic result = js.context['pdfl'].callMethod('checkFirebaseStatus', []);
      
      if (result != null) {
        // result가 Map인지 확인하고 안전하게 값을 추출
        final bool initialized = result is Map && result['initialized'] == true;
        final bool userLoggedIn = result is Map && result['userLoggedIn'] == true;
        final dynamic userId = result is Map ? result['userId'] : null;
        
        // 상태 업데이트
        _updateState(initialized, userLoggedIn, userId?.toString());
        
        return initialized;
      }
    } catch (e) {
      debugPrint('WebFirebaseInitializer: JavaScript 함수 호출 오류 - $e');
    }
    
    return false;
  }

  /// 상태 리스너 등록
  void addStateListener(Function(bool, bool, String?) listener) {
    _listeners.add(listener);
  }
  
  /// 상태 리스너 제거
  void removeStateListener(Function(bool, bool, String?) listener) {
    _listeners.remove(listener);
  }
  
  /// 상태 업데이트 및 리스너 호출
  void _updateState(bool isInitialized, bool isUserLoggedIn, String? userId) {
    _isInitialized = isInitialized;
    _isUserLoggedIn = isUserLoggedIn;
    _userId = userId;
    
    // 모든 리스너에게 상태 변경 알림
    for (final listener in _listeners) {
      listener(_isInitialized, _isUserLoggedIn, _userId);
    }
  }

  /// JavaScript 콜백 등록
  void _registerJsCallback() {
    if (!kIsWeb) return;
    
    try {
      // JavaScript 환경 확인
      if (js.context == null) {
        debugPrint('JavaScript 콜백 등록: JavaScript 컨텍스트가 존재하지 않습니다.');
        return;
      }
      
      // JavaScript에서 호출할 함수 등록
      js.context['flutterFirebaseAuthChanged'] = allowInterop((dynamic isLoggedIn, dynamic userId) {
        // Convert JS boolean to Dart boolean
        final bool loggedIn = isLoggedIn == true;
        
        debugPrint('WebFirebaseInitializer: JS 콜백 - 로그인=$loggedIn, 사용자ID=$userId');
        
        // 상태 업데이트
        _updateState(true, loggedIn, userId?.toString());
      });
      
      // 개별 서비스 초기화 콜백 등록
      js.context['ff_trigger_firebase_firestore'] = allowInterop(() {
        debugPrint('WebFirebaseInitializer: Firestore 초기화 완료 (JS에서 알림)');
        _serviceInitialized['firestore'] = true;
      });
      
      js.context['ff_trigger_firebase_storage'] = allowInterop(() {
        debugPrint('WebFirebaseInitializer: Storage 초기화 완료 (JS에서 알림)');
        _serviceInitialized['storage'] = true;
      });
      
      js.context['ff_trigger_firebase_analytics'] = allowInterop(() {
        debugPrint('WebFirebaseInitializer: Analytics 초기화 완료 (JS에서 알림)');
        _serviceInitialized['analytics'] = true;
      });
      
      debugPrint('WebFirebaseInitializer: JavaScript 콜백 등록 완료');
    } catch (e) {
      debugPrint('WebFirebaseInitializer: JavaScript 콜백 등록 오류 - $e');
    }
  }

  /// 웹 환경에서 Firebase를 초기화합니다.
  Future<void> initialize() async {
    if (!kIsWeb) {
      _initializationCompleter.complete();
      return;
    }
    
    try {
      if (_isInitializing) {
        debugPrint('WebFirebaseInitializer: 이미 초기화 중입니다.');
        return await initializationComplete;
      }
      
      if (_isInitialized) {
        debugPrint('WebFirebaseInitializer: 이미 초기화되었습니다.');
        return;
      }
      
      _isInitializing = true;
      debugPrint('WebFirebaseInitializer: 초기화 시작');
      
      // JavaScript에서 Firebase 상태 확인 (이미 초기화되어 있을 수 있음)
      final jsFirebaseInitialized = checkFirebaseStatusFromJS();
      if (jsFirebaseInitialized) {
        debugPrint('WebFirebaseInitializer: JavaScript에서 이미 Firebase가 초기화됨을 감지');
        _isInitialized = true;
        _isInitializing = false;
        _serviceInitialized['core'] = true;
        _serviceInitialized['auth'] = true;
        
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
        
        // 나머지 서비스는 지연 초기화
        _initializeRemainingServicesAsync();
        return;
      }
      
      // Firebase 코어 초기화 (최소한만 초기화)
      try {
        await Firebase.initializeApp();
        _serviceInitialized['core'] = true;
        
        // 인증 상태만 확인하고 다른 서비스는 나중에 초기화
        await _setupAuthStateListener();
        _serviceInitialized['auth'] = true;
        
        _isInitialized = true;
        _isInitializing = false;
        
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
        
        // 나머지 서비스는 지연 초기화
        _initializeRemainingServicesAsync();
        
        debugPrint('WebFirebaseInitializer: 필수 서비스 초기화 완료');
      } catch (e) {
        debugPrint('WebFirebaseInitializer: 초기화 오류 - $e');
        _isInitializing = false;
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.completeError(e);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 전체 초기화 오류 - $e');
      _isInitializing = false;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// 현재 인증된 사용자 확인
  Future<void> _checkCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('WebFirebaseInitializer: 로그인된 사용자 - ${user.uid}');
        _updateState(_isInitialized, true, user.uid);
      } else {
        debugPrint('WebFirebaseInitializer: 로그인된 사용자 없음');
        _updateState(_isInitialized, false, null);
      }
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 사용자 확인 오류 - $e');
      _updateState(_isInitialized, false, null);
    }
  }

  /// 인증 상태 변경 리스너 설정
  Future<void> _setupAuthStateListener() async {
    try {
      await _checkCurrentUser();
      
      FirebaseAuth.instance.authStateChanges().listen((user) {
        final bool isLoggedIn = user != null;
        final String? uid = user?.uid;
        
        debugPrint('WebFirebaseInitializer: 인증 상태 변경 - ${isLoggedIn ? '로그인됨' : '로그아웃됨'}');
        
        // 상태 업데이트
        _updateState(_isInitialized, isLoggedIn, uid);
        
        // JavaScript에 상태 변경 알림
        if (kIsWeb && js.context != null && js.context.hasProperty('flutterFirebaseAuthChanged')) {
          js.context.callMethod('flutterFirebaseAuthChanged', [isLoggedIn, uid]);
        }
      });
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 인증 리스너 설정 오류 - $e');
    }
  }

  /// 부가 서비스 초기화 (백그라운드에서 비동기 수행)
  Future<void> _initializeRemainingServicesAsync() async {
    try {
      debugPrint('WebFirebaseInitializer: 나머지 서비스 초기화 시작');
      
      // Firestore 초기화 (필요할 때)
      if (_serviceInitialized['firestore'] != true) {
        debugPrint('WebFirebaseInitializer: Firestore 초기화 중...');
        try {
          // Firestore 인스턴스 가져오기 - 이 호출로 초기화가 시작됨
          final firestore = FirebaseFirestore.instance;
          debugPrint('WebFirebaseInitializer: Firestore 초기화 완료');
          _serviceInitialized['firestore'] = true;
        } catch (e) {
          debugPrint('WebFirebaseInitializer: Firestore 초기화 오류 - $e');
        }
      }
      
      // Storage 초기화 (필요할 때)
      if (_serviceInitialized['storage'] != true) {
        debugPrint('WebFirebaseInitializer: Storage 초기화 중...');
        try {
          // Storage 인스턴스 가져오기 - 이 호출로 초기화가 시작됨
          final storage = FirebaseStorage.instance;
          debugPrint('WebFirebaseInitializer: Storage 초기화 완료');
          _serviceInitialized['storage'] = true;
        } catch (e) {
          debugPrint('WebFirebaseInitializer: Storage 초기화 오류 - $e');
        }
      }
      
      debugPrint('WebFirebaseInitializer: 모든 서비스 초기화 완료');
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 전체 서비스 초기화 오류 - $e');
    }
  }

  /// 웹 환경에서 로그아웃 처리
  static Future<void> signOut() async {
    if (!kIsWeb) return;
    
    try {
      // Firebase 인증 로그아웃
      await FirebaseAuth.instance.signOut();
      
      // JavaScript를 통한 로그아웃 처리
      if (js.context != null && js.context.hasProperty('firebase') && 
          js.context['firebase'].hasProperty('auth')) {
        debugPrint('WebFirebaseInitializer: JavaScript로 로그아웃 시도');
        js.context['firebase'].callMethod('auth().signOut', []);
      }
      
      // 인스턴스의 상태 업데이트
      WebFirebaseInitializer()._updateState(true, false, null);
      
      debugPrint('WebFirebaseInitializer: 웹 로그아웃 완료');
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 웹 로그아웃 오류 - $e');
      // 오류가 발생해도 상태 업데이트
      WebFirebaseInitializer()._updateState(true, false, null);
    }
  }

  /// 웹 환경에서 현재 로그인된 사용자 정보 가져오기
  Future<UserModel?> getCurrentUser() async {
    if (!_isInitialized) {
      debugPrint('Firebase가 초기화되지 않았습니다.');
      return null;
    }

    try {
      debugPrint('현재 사용자 정보 가져오기 시작');
      
      // 직접 JavaScript 함수 호출하여 사용자 ID 가져오기
      final userId = js.context.callMethod('getCurrentUserId', []);
      if (userId == null || userId == '') {
        debugPrint('사용자 ID가 null이거나 빈 문자열입니다.');
        return null;
      }
      
      debugPrint('사용자 ID 가져오기 성공: $userId');
      
      // Firestore에서 사용자 정보 가져오기
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId.toString()).get();
        
        if (!userDoc.exists) {
          debugPrint('사용자 문서가 존재하지 않습니다.');
          
          // 기본 사용자 정보 생성 및 저장
          final basicUserData = {
            'uid': userId.toString(),
            'email': '',
            'displayName': '사용자',
            'photoURL': '',
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
          };
          
          await FirebaseFirestore.instance.collection('users').doc(userId.toString()).set(basicUserData);
          debugPrint('기본 사용자 정보 저장 완료');
          
          // 기본 사용자 모델 반환
          return UserModel.fromMap(basicUserData);
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('사용자 정보 가져오기 성공: $userData');
        
        return UserModel.fromMap(userData);
      } catch (e) {
        debugPrint('Firestore에서 사용자 정보 가져오기 오류: $e');
        return null;
      }
    } catch (e) {
      debugPrint('사용자 정보 가져오기 오류: $e');
      return null;
    }
  }

  /// 웹 환경에서 이메일/비밀번호로 회원가입
  static Future<Map<String, dynamic>?> signUpWithEmailPassword(String email, String password) async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('웹 이메일/비밀번호 회원가입 시도');
      
      // Firebase 초기화 확인
      final instance = WebFirebaseInitializer();
      if (!instance.isInitialized) {
        debugPrint('Firebase가 초기화되지 않았습니다. 초기화 시도...');
        try {
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: _getEnvValue('FIREBASE_API_KEY'),
              appId: _getEnvValue('FIREBASE_APP_ID'),
              messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID'),
              projectId: _getEnvValue('FIREBASE_PROJECT_ID'),
              authDomain: _getEnvValue('FIREBASE_AUTH_DOMAIN'),
              storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET'),
              measurementId: _getEnvValue('FIREBASE_MEASUREMENT_ID'),
            ),
          );
          instance._isInitialized = true;
          debugPrint('Firebase 초기화 완료');
        } catch (e) {
          debugPrint('Firebase 초기화 실패: $e');
          // 초기화 실패해도 계속 진행
        }
      }
      
      dynamic result;
      try {
        result = await js.context.callMethod('signUpWithEmailPassword', [email, password]);
      } catch (e) {
        debugPrint('회원가입 JavaScript 호출 오류: $e');
        // 기본 사용자 정보 반환
        return {
          'uid': 'guest_user',
          'email': email,
          'displayName': '게스트 사용자',
          'photoURL': '',
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
        };
      }
      
      if (result == null) {
        debugPrint('회원가입 실패: 결과가 null입니다.');
        // 기본 사용자 정보 반환
        return {
          'uid': 'guest_user',
          'email': email,
          'displayName': '게스트 사용자',
          'photoURL': '',
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
        };
      }
      
      final userData = _convertJsObjectToMap(result);
      debugPrint('회원가입 성공: $userData');
      
      if (userData != null && userData['uid'] != null) {
        // 구독 정보 생성
        try {
          await _createSubscriptionData(userData['uid']);
        } catch (e) {
          debugPrint('구독 정보 생성 실패: $e');
        }
        
        // 사용자 정보 저장
        try {
          await js.context.callMethod('saveUserLoginTime', [userData['uid']]);
          debugPrint('사용자 로그인 시간 저장 완료: ${userData['uid']}');
        } catch (e) {
          debugPrint('사용자 로그인 시간 저장 실패: $e');
        }
      }
      
      return userData;
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      // 기본 사용자 정보 반환
      return {
        'uid': 'guest_user',
        'email': email,
        'displayName': '게스트 사용자',
        'photoURL': '',
        'createdAt': DateTime.now().toIso8601String(),
        'subscription': 'free',
      };
    }
  }

  /// 사용자 정보 저장
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (!kIsWeb) return;
    
    try {
      js.context.callMethod('saveUserData', [js.JsObject.jsify(userData)]);
    } catch (e) {
      debugPrint('사용자 데이터 저장 오류: $e');
    }
  }

  /// 사용자 정보 가져오기
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (!_isInitialized) {
      debugPrint('Firebase가 초기화되지 않았습니다.');
      return null;
    }

    try {
      debugPrint('사용자 정보 가져오기 시작: $userId');
      
      final result = await js.context.callMethod('getUserData', [
        userId,
        js.allowInterop((userData, error) {
          if (error != null) {
            debugPrint('사용자 정보 가져오기 오류: $error');
          } else if (userData != null) {
            debugPrint('사용자 정보 가져오기 성공: $userData');
          } else {
            debugPrint('사용자 정보 없음');
          }
        })
      ]);

      if (result == null) {
        return null;
      }

      return js.JsObject.fromBrowserObject(result) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('사용자 정보 가져오기 오류: $e');
      return null;
    }
  }

  /// 초기화 상태를 리셋합니다.
  void resetInitialization() {
    _isInitialized = false;
    debugPrint('Firebase 초기화 상태가 리셋되었습니다.');
  }

  /// JavaScript 객체를 Dart Map으로 변환
  static Map<String, dynamic>? _convertJsObjectToMap(dynamic jsObject) {
    // 기본 반환값 정의
    final defaultMap = {
      'uid': 'guest_user',
      'email': '',
      'displayName': '게스트 사용자',
      'photoURL': '',
      'createdAt': DateTime.now().toIso8601String(),
      'subscription': 'free',
    };
    
    if (jsObject == null) {
      debugPrint('JavaScript 객체가 null입니다.');
      return defaultMap;
    }
    
    try {
      // 이미 Map인 경우 바로 반환
      if (jsObject is Map) {
        debugPrint('JavaScript 객체가 이미 Map입니다.');
        return Map<String, dynamic>.from(jsObject);
      }
      
      // 기본 빈 Map 생성
      final map = <String, dynamic>{};
      
      // 안전하게 Object.keys 호출
      dynamic keys;
      try {
        if (js.context.hasProperty('Object')) {
          keys = js.context['Object'].callMethod('keys', [jsObject]);
        }
      } catch (e) {
        debugPrint('Object.keys 호출 오류: $e');
        return defaultMap;
      }
      
      // keys가 null이거나 오류 발생 시 기본 Map 반환
      if (keys == null) {
        debugPrint('JavaScript 객체의 키를 가져올 수 없습니다. 기본 값 사용');
        return defaultMap;
      }
      
      debugPrint('JavaScript 객체 키 목록: $keys');
      
      // 각 키에 대해 안전하게 값 추출
      for (var i = 0; i < keys.length; i++) {
        final key = keys[i];
        dynamic value;
        
        try {
          value = jsObject[key];
        } catch (e) {
          debugPrint('키 $key의 값을 가져오는 중 오류 발생: $e');
          continue;
        }
        
        debugPrint('키: $key, 값 타입: ${value?.runtimeType}');
        
        if (value == null) {
          map[key] = null;
        } else if (value is js.JsObject) {
          map[key] = _convertJsObjectToMap(value);
        } else {
          map[key] = value;
        }
      }
      
      // uid가 null인 경우 기본값 설정
      if (map['uid'] == null) {
        map['uid'] = 'guest_user';
      }
      
      debugPrint('JavaScript 객체 변환 결과: $map');
      return map;
    } catch (e) {
      debugPrint('JavaScript 객체 변환 오류: $e');
      // 오류 발생 시 기본 Map 반환
      return defaultMap;
    }
  }

  /// 구독 정보 생성
  static Future<void> _createSubscriptionData(String? userId) async {
    try {
      // userId가 null이면 기본값 사용
      final safeUserId = userId ?? 'guest_user';
      
      debugPrint('구독 정보 생성 시작: $safeUserId');
      
      final subscriptionData = {
        'userId': safeUserId,
        'tier': 'free',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'expiresAt': null,
        'paymentMethod': null,
        'paymentStatus': null,
        'lastPaymentDate': null,
        'nextPaymentDate': null,
        'canceledAt': null,
        'features': {
          'maxPdfSize': 5 * 1024 * 1024,
          'maxTextLength': 10000,
          'maxPdfsPerDay': 5,
          'maxPdfsTotal': 20,
          'maxPdfPages': 50,
          'maxPdfsPerYear': 1000,
          'maxPdfsPerLifetime': 10000,
          'maxPdfTextLength': 50000,
          'maxPdfTextLengthPerPage': 1000,
          'maxPdfTextLengthPerDay': 100000,
          'maxPdfTextLengthPerMonth': 1000000,
          'maxPdfTextLengthPerYear': 10000000,
          'maxPdfTextLengthPerLifetime': 100000000
        }
      };
      
      // Firestore에 구독 정보 저장 (안전하게 처리)
      try {
        if (js.context.hasProperty('createSubscription')) {
          js.context.callMethod('createSubscription', [
            safeUserId,
            js.JsObject.jsify(subscriptionData),
            js.allowInterop((error) {
              if (error != null) {
                debugPrint('구독 정보 생성 오류');
              } else {
                debugPrint('구독 정보 생성 완료: $safeUserId');
              }
            })
          ]);
        } else {
          debugPrint('createSubscription 함수가 정의되지 않았습니다. 구독 정보 생성을 건너뜁니다.');
        }
      } catch (jsError) {
        debugPrint('구독 정보 생성 JavaScript 오류: $jsError');
        // JavaScript 오류 무시하고 계속 진행
      }
    } catch (e) {
      debugPrint('구독 정보 생성 예외: $e');
      // 오류 무시하고 계속 진행
    }
  }

  /// 구독 정보 가져오기
  static Future<Map<String, dynamic>?> getSubscriptionData(String userId) async {
    if (!kIsWeb) return null;
    
    final completer = Completer<Map<String, dynamic>?>();
    
    try {
      debugPrint('구독 정보 가져오기 시작: $userId');
      
      js.context.callMethod('getSubscription', [
        userId,
        js.allowInterop((result, error) {
          if (error != null) {
            debugPrint('구독 정보 가져오기 오류: $error');
            completer.complete(null);
          } else if (result != null) {
            try {
              final Map<String, dynamic> subscriptionData = {};
              
              if (result is js.JsObject) {
                subscriptionData['tier'] = result['tier']?.toString() ?? 'free';
                subscriptionData['status'] = result['status']?.toString() ?? 'active';
                subscriptionData['expiresAt'] = result['expiresAt']?.toString();
                subscriptionData['features'] = result['features'] != null 
                    ? Map<String, dynamic>.from(result['features'])
                    : null;
              } else {
                subscriptionData.addAll(Map<String, dynamic>.from(result));
              }
              
              debugPrint('구독 정보 가져오기 성공: $subscriptionData');
              completer.complete(subscriptionData);
            } catch (e) {
              debugPrint('구독 정보 변환 오류: $e');
              completer.complete(null);
            }
          } else {
            debugPrint('구독 정보 없음');
            completer.complete(null);
          }
        })
      ]);
    } catch (e) {
      debugPrint('구독 정보 가져오기 예외: $e');
      completer.complete(null);
    }
    
    return completer.future;
  }
} 