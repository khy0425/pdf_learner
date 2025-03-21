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
import '../utils/non_web_stub.dart' if (dart.library.html) 'package:universal_html/html.dart';

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
      if (!_hasJsContext()) {
        debugPrint('JavaScript 컨텍스트가 존재하지 않습니다.');
        return false;
      }
      
      if (kIsWeb) {
        // 웹 환경에서만 실행
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
      }
    } catch (e) {
      debugPrint('WebFirebaseInitializer: JavaScript 함수 호출 오류 - $e');
    }
    
    return false;
  }

  // JavaScript 컨텍스트 확인 헬퍼 메서드
  bool _hasJsContext() {
    if (!kIsWeb) return false;
    
    try {
      return js.context != null;
    } catch (e) {
      return false;
    }
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
      if (!_hasJsContext()) {
        debugPrint('JavaScript 콜백 등록: JavaScript 컨텍스트가 존재하지 않습니다.');
        return;
      }
      
      // 웹 환경에서만 실행
      if (kIsWeb) {
        // 자바스크립트 허용 (다트:js 사용)
        dynamic allowInteropFn(Function fn) {
          return js.allowInterop(fn);
        }
        
        // JavaScript에서 호출할 함수 등록
        js.context['flutterFirebaseAuthChanged'] = allowInteropFn((dynamic isLoggedIn, dynamic userId) {
          // Convert JS boolean to Dart boolean
          final bool loggedIn = isLoggedIn == true;
          
          debugPrint('WebFirebaseInitializer: JS 콜백 - 로그인=$loggedIn, 사용자ID=$userId');
          
          // 상태 업데이트
          _updateState(true, loggedIn, userId?.toString());
        });
        
        // 개별 서비스 초기화 콜백 등록
        js.context['ff_trigger_firebase_firestore'] = allowInteropFn(() {
          debugPrint('WebFirebaseInitializer: Firestore 초기화 완료 (JS에서 알림)');
          _serviceInitialized['firestore'] = true;
        });
        
        js.context['ff_trigger_firebase_storage'] = allowInteropFn(() {
          debugPrint('WebFirebaseInitializer: Storage 초기화 완료 (JS에서 알림)');
          _serviceInitialized['storage'] = true;
        });
        
        js.context['ff_trigger_firebase_analytics'] = allowInteropFn(() {
          debugPrint('WebFirebaseInitializer: Analytics 초기화 완료 (JS에서 알림)');
          _serviceInitialized['analytics'] = true;
        });
      }
      
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

  /// Google 로그인 (웹 전용)
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    if (!kIsWeb) return null;
    
    try {
      final result = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      final user = result.user;
      
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'createdAt': DateTime.now().toIso8601String(),
        'subscriptionTier': 'free',
      };
    } catch (e) {
      debugPrint('WebFirebaseInitializer: Google 로그인 오류 - $e');
      return null;
    }
  }
  
  /// 이메일/비밀번호 로그인 (웹 전용)
  Future<Map<String, dynamic>?> signInWithEmailPassword(String email, String password) async {
    if (!kIsWeb) return null;
    
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = result.user;
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'createdAt': DateTime.now().toIso8601String(),
        'subscriptionTier': 'free',
      };
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 이메일 로그인 오류 - $e');
      return null;
    }
  }
  
  /// 이메일/비밀번호 회원가입 (웹 전용)
  Future<Map<String, dynamic>?> signUpWithEmailPassword(String email, String password) async {
    if (!kIsWeb) return null;
    
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = result.user;
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'createdAt': DateTime.now().toIso8601String(),
        'subscriptionTier': 'free',
      };
    } catch (e) {
      debugPrint('WebFirebaseInitializer: 회원가입 오류 - $e');
      return null;
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
        
        // JavaScript에 상태 변경 알림 (웹 환경에서만)
        if (kIsWeb && _hasJsContext() && js.context.hasProperty('flutterFirebaseAuthChanged')) {
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
      final hasJsContext = WebFirebaseInitializer()._hasJsContext();
      if (kIsWeb && hasJsContext && js.context.hasProperty('firebase') && 
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
    if (!_isInitialized || !kIsWeb) {
      debugPrint('Firebase가 초기화되지 않았거나 웹 환경이 아닙니다.');
      return null;
    }

    try {
      debugPrint('현재 사용자 정보 가져오기 시작');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('현재 로그인된 사용자가 없습니다.');
        return null;
      }
      
      final userId = currentUser.uid;
      debugPrint('사용자 ID 가져오기 성공: $userId');
      
      // Firestore에서 사용자 정보 가져오기
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        
        if (!userDoc.exists) {
          debugPrint('사용자 문서가 존재하지 않습니다.');
          
          // 기본 사용자 정보 생성 및 저장
          final basicUserData = {
            'uid': userId,
            'email': currentUser.email ?? '',
            'displayName': currentUser.displayName ?? '사용자',
            'photoURL': currentUser.photoURL ?? '',
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
            'maxPdfTextLengthPerPdf': 50000,
          };
          
          await FirebaseFirestore.instance.collection('users').doc(userId).set(basicUserData);
          
          return UserModel.fromMap(basicUserData);
        }
        
        debugPrint('사용자 정보를 Firestore에서 가져왔습니다.');
        
        // 사용자 정보 반환
        final userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userId; // ID 추가 확인
        
        return UserModel.fromMap(userData);
      } catch (e) {
        debugPrint('Firestore에서 사용자 정보 가져오기 오류: $e');
        
        // 기본 사용자 정보 생성
        return UserModel(
          uid: userId,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? '사용자',
          photoURL: currentUser.photoURL,
          emailVerified: currentUser.emailVerified,
          createdAt: DateTime.now(),
          subscriptionTier: 'free',
          maxPdfTextLength: 50000,
          maxPdfTextLengthPerPage: 1000,
          maxPdfTextLengthPerDay: 100000,
          maxPdfTextLengthPerMonth: 1000000,
          maxPdfTextLengthPerYear: 10000000,
          maxPdfTextLengthPerLifetime: 100000000,
        );
      }
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
} 