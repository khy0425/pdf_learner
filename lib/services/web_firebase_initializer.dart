import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // JavaScript 함수 호출
      final result = js.context.callMethod('checkFirebaseStatus', []);
      
      if (result != null) {
        final initialized = result['initialized'] == true;
        final userLoggedIn = result['userLoggedIn'] == true;
        final userId = result['userId'];
        
        // 상태 업데이트
        _updateState(initialized, userLoggedIn, userId?.toString());
        
        return initialized;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebFirebaseInitializer: JavaScript 함수 호출 오류 - $e');
      }
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
      // JavaScript에서 호출할 함수 등록
      js.context['flutterFirebaseAuthChanged'] = (isLoggedIn, userId) {
        // Convert JS boolean to Dart boolean
        final bool loggedIn = isLoggedIn == true;
        
        if (kDebugMode) {
          print('WebFirebaseInitializer: JS 콜백 - 로그인=$loggedIn, 사용자ID=$userId');
        }
        
        // 상태 업데이트
        _updateState(true, loggedIn, userId?.toString());
      };
      
      if (kDebugMode) {
        print('WebFirebaseInitializer: JavaScript 콜백 등록 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebFirebaseInitializer: JavaScript 콜백 등록 오류 - $e');
      }
    }
  }

  /// 웹 환경에서 Firebase를 초기화합니다.
  Future<void> initialize() async {
    if (kIsWeb) {
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
        
        // JavaScript 콜백 등록
        _registerJsCallback();
        
        // JavaScript의 Firebase 초기화 확인
        final isFirebaseInitialized = js.context.hasProperty('firebase') && 
                                      js.context['firebase'].hasProperty('apps') &&
                                      js.context['firebase']['apps'].length > 0;
        
        if (!isFirebaseInitialized) {
          debugPrint('WebFirebaseInitializer: Firebase 초기화 필요');
          
          // Firebase 초기화
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
        }
        
        // 현재 로그인 상태 확인
        await _checkCurrentUser();
        
        // Firebase Auth 상태 변경 리스너 등록
        _setupAuthStateListener();
        
        _isInitialized = true;
        _isInitializing = false;
        
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
        
        debugPrint('WebFirebaseInitializer: 초기화 완료');
      } catch (e) {
        debugPrint('WebFirebaseInitializer: 초기화 오류 - $e');
        _isInitializing = false;
        
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.completeError(e);
        }
        
        rethrow;
      }
    }
  }

  Future<void> _checkCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('WebFirebaseInitializer: 현재 로그인된 사용자 - ${currentUser.uid}');
        _updateState(true, true, currentUser.uid);
        
        // 사용자 로그인 시간 저장
        await js.context.callMethod('saveUserLoginTime', [currentUser.uid]);
      } else {
        debugPrint('WebFirebaseInitializer: 로그인된 사용자 없음');
        _updateState(true, false, null);
      }
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 사용자 확인 중 오류 - $e');
      _updateState(true, false, null);
    }
  }

  /// Firebase 인증 상태 변경 리스너 설정
  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((auth.User? user) {
      if (user != null) {
        debugPrint('WebFirebaseInitializer: 인증 상태 변경 - 로그인됨 ${user.uid}');
        _updateState(true, true, user.uid);
        
        // 사용자 로그인 시간 저장
        js.context.callMethod('saveUserLoginTime', [user.uid]);
      } else {
        debugPrint('WebFirebaseInitializer: 인증 상태 변경 - 로그아웃됨');
        _updateState(true, false, null);
      }
    });
  }

  Future<Map<String, dynamic>?> _getFirebaseConfig() async {
    try {
      // 환경 변수에서 Firebase 설정 가져오기
      final apiKey = _getEnvValue('FIREBASE_API_KEY');
      final projectId = _getEnvValue('FIREBASE_PROJECT_ID');
      
      if (apiKey.isEmpty || projectId.isEmpty) {
        debugPrint('환경 변수에서 Firebase 설정을 가져오지 못했습니다.');
        return null;
      }

      final config = {
        'apiKey': apiKey,
        'projectId': projectId,
        'authDomain': _getEnvValue('FIREBASE_AUTH_DOMAIN'),
        'storageBucket': _getEnvValue('FIREBASE_STORAGE_BUCKET'),
        'messagingSenderId': _getEnvValue('FIREBASE_MESSAGING_SENDER_ID'),
        'appId': _getEnvValue('FIREBASE_APP_ID'),
        'measurementId': _getEnvValue('FIREBASE_MEASUREMENT_ID'),
      };

      debugPrint('환경 변수에서 Firebase 설정 가져오기 성공');
      return config;
    } catch (e) {
      debugPrint('Firebase 설정 가져오기 오류');
      return null;
    }
  }

  Future<String?> _initializeFirebase(String configStr) async {
    try {
      final result = await js.context.callMethod('initializeFirebase', [configStr]);
      return result?.toString();
    } catch (e) {
      debugPrint('Firebase 초기화 JavaScript 오류');
      return e.toString();
    }
  }

  /// API 키 가져오기
  static Future<String?> getApiKey(String keyName) async {
    if (!kIsWeb) return null;
    
    try {
      final result = await js.context.callMethod('getApiKey', [keyName]);
      return result?.toString();
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  /// API 키 유효성 검사
  static Future<bool> validateApiKey(String keyType, String apiKey) async {
    if (!kIsWeb) return false;
    
    try {
      final result = await js.context.callMethod('validateApiKey', [keyType, apiKey]);
      return result == true;
    } catch (e) {
      debugPrint('API 키 검증 오류: $e');
      return false;
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

  /// 웹 환경에서 Google로 로그인
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('웹 Google 로그인 시도');
      
      // 로그인 전 Firebase 초기화 확인
      final instance = WebFirebaseInitializer();
      if (!instance.isInitialized) {
        debugPrint('Firebase가 초기화되지 않았습니다. 초기화 시도...');
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
      }
      
      dynamic result;
      try {
        result = await js.context.callMethod('signInWithGoogle');
      } catch (e) {
        debugPrint('Google 로그인 JavaScript 호출 오류: $e');
        // 기본 사용자 정보 반환
        return {
          'uid': 'guest_user',
          'email': '',
          'displayName': '게스트 사용자',
          'photoURL': '',
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
        };
      }
      
      if (result == null) {
        debugPrint('Google 로그인 실패: 결과가 null입니다.');
        // 기본 사용자 정보 반환
        return {
          'uid': 'guest_user',
          'email': '',
          'displayName': '게스트 사용자',
          'photoURL': '',
          'createdAt': DateTime.now().toIso8601String(),
          'subscription': 'free',
        };
      }
      
      final userData = _convertJsObjectToMap(result);
      debugPrint('Google 로그인 성공: $userData');
      
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
        
        // 로그인 상태 확인
        try {
          final isLoggedIn = await js.context.callMethod('isUserLoggedIn');
          debugPrint('로그인 상태 확인: $isLoggedIn');
        } catch (e) {
          debugPrint('로그인 상태 확인 실패: $e');
        }
      }
      
      return userData;
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      // 기본 사용자 정보 반환
      return {
        'uid': 'guest_user',
        'email': '',
        'displayName': '게스트 사용자',
        'photoURL': '',
        'createdAt': DateTime.now().toIso8601String(),
        'subscription': 'free',
      };
    }
  }

  /// 웹 환경에서 이메일/비밀번호로 로그인
  static Future<Map<String, dynamic>?> signInWithEmailPassword(String email, String password) async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('웹 이메일/비밀번호 로그인 시도');
      
      // 로그인 전 Firebase 초기화 확인
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
        result = await js.context.callMethod('signInWithEmailPassword', [email, password]);
      } catch (e) {
        debugPrint('이메일/비밀번호 로그인 JavaScript 호출 오류: $e');
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
        debugPrint('이메일/비밀번호 로그인 실패: 결과가 null입니다.');
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
      debugPrint('이메일/비밀번호 로그인 성공: $userData');
      
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
      debugPrint('이메일/비밀번호 로그인 오류: $e');
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

  /// 웹 환경에서 로그아웃
  static Future<void> signOut() async {
    if (!kIsWeb) return;
    
    final completer = Completer<void>();
    
    try {
      debugPrint('웹 로그아웃 시도');
      
      js.context.callMethod('signOut', [
        js.allowInterop((error) {
          if (error != null) {
            debugPrint('웹 로그아웃 오류: $error');
            completer.completeError(error.toString());
          } else {
            debugPrint('웹 로그아웃 성공');
            // 초기화 상태는 유지
            completer.complete();
          }
        })
      ]);
    } catch (e) {
      debugPrint('웹 로그아웃 예외 발생: $e');
      completer.completeError('JavaScript 함수 호출 오류: $e');
    }
    
    return completer.future;
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
} 