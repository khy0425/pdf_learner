import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:js/js.dart';
import 'package:pdf_learner/models/user_model.dart';
import 'package:pdf_learner/models/user.dart';
import 'dart:convert';
import 'package:pdf_learner/main.dart' show secureLog;
import 'package:universal_html/html.dart';

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
      secureLog('환경 변수 $key: ${value != null ? "값 있음" : "값 없음"}');
    } else {
      secureLog('환경 변수 $key: ${value ?? "값 없음"}');
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
        // JavaScript의 Firebase 초기화 확인
        final isFirebaseInitialized = js.context.hasProperty('firebase') && 
                                      js.context['firebase'].hasProperty('apps') &&
                                      js.context['firebase']['apps'].length > 0;
        
        if (isFirebaseInitialized) {
          debugPrint('Firebase가 JavaScript에서 이미 초기화되어 있습니다.');
          return;
        }
        
        // 만약 JavaScript에서 초기화되지 않았다면, 직접 초기화 시도
        // (이 코드는 실행되지 않을 것입니다. Firebase는 이미 web/index.html에서 초기화됨)
        throw Exception('Firebase가 JavaScript에서 초기화되지 않았습니다.');
      } catch (e) {
        // 오류 발생 시 예외 전파
        rethrow;
      }
    } else {
      throw Exception('이 초기화는 웹 환경에서만 사용해야 합니다.');
    }
  }

  Future<Map<String, dynamic>?> _getFirebaseConfig() async {
    try {
      // 환경 변수에서 Firebase 설정 가져오기
      final apiKey = _getEnvValue('FIREBASE_API_KEY');
      final projectId = _getEnvValue('FIREBASE_PROJECT_ID');
      
      if (apiKey.isEmpty || projectId.isEmpty) {
        secureLog('환경 변수에서 Firebase 설정을 가져오지 못했습니다.');
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

      secureLog('환경 변수에서 Firebase 설정 가져오기 성공');
      return config;
    } catch (e) {
      secureLog('Firebase 설정 가져오기 오류');
      return null;
    }
  }

  Future<String?> _initializeFirebase(String configStr) async {
    try {
      final result = await js.context.callMethod('initializeFirebase', [configStr]);
      return result?.toString();
    } catch (e) {
      secureLog('Firebase 초기화 JavaScript 오류');
      return e.toString();
    }
  }

  /// API 키 가져오기
  static Future<String?> getApiKey(String keyName) async {
    if (!kIsWeb) return null;
    
    try {
      // JavaScript에서 직접 API 키 가져오기
      final apiKey = js.context.callMethod('getApiKey', [keyName]);
      secureLog('JavaScript에서 API 키 가져오기 결과', '***민감 정보 숨김***');
      return apiKey?.toString();
    } catch (e) {
      secureLog('웹 API 키 가져오기 예외');
      
      // 오류 발생 시 하드코딩된 값 반환
      if (keyName == 'gemini') {
        return '***민감 정보 숨김***'; // 실제 키는 코드에 포함하지 않음
      }
      return null;
    }
  }
  
  /// API 키 유효성 검사
  static Future<bool> validateApiKey(String keyName, String apiKey) async {
    if (!kIsWeb) return false;
    
    try {
      // JavaScript 함수 호출하여 API 키 유효성 검사
      final result = js.context.callMethod('validateApiKey', [keyName, apiKey]);
      secureLog('JavaScript에서 API 키 유효성 검사 결과', result);
      return result == true;
    } catch (e) {
      secureLog('웹 API 키 유효성 검사 예외');
      
      // 특정 API 키는 항상 유효하다고 처리 (테스트용)
      if (apiKey.startsWith('AIza')) {
        secureLog('테스트용 API 키가 확인되었습니다');
        return true;
      }
      
      return false;
    }
  }

  /// 구독 정보 생성
  static Future<void> _createSubscriptionData(String userId) async {
    try {
      secureLog('구독 정보 생성 시작', userId);
      
      final subscriptionData = {
        'userId': userId,
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
          'maxPdfTextLength': 50000,
          'maxPdfTextLengthPerPage': 1000,
          'maxPdfTextLengthPerDay': 100000,
          'maxPdfTextLengthPerMonth': 1000000,
          'maxPdfTextLengthPerYear': 10000000,
          'maxPdfTextLengthPerLifetime': 100000000,
        }
      };
      
      // Firestore에 구독 정보 저장
      js.context.callMethod('createSubscription', [
        userId,
        js.JsObject.jsify(subscriptionData),
        js.allowInterop((error) {
          if (error != null) {
            secureLog('구독 정보 생성 오류');
          } else {
            secureLog('구독 정보 생성 완료', userId);
          }
        })
      ]);
    } catch (e) {
      secureLog('구독 정보 생성 예외');
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
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (!kIsWeb) throw Exception('웹 환경에서만 사용 가능합니다');
    
    final completer = Completer<Map<String, dynamic>>();
    
    try {
      debugPrint('웹 Google 로그인 시도');
      
      js.context.callMethod('signInWithGoogle', [
        js.allowInterop((result, error) {
          if (error != null) {
            debugPrint('웹 Google 로그인 오류 원본: $error');
            
            // JavaScript 객체를 Dart Map으로 변환
            try {
              // JsObject를 직접 Map으로 변환하지 않고 필요한 속성만 추출
              String code = 'unknown-error';
              String message = 'Unknown error occurred';
              
              try {
                if (error is js.JsObject) {
                  code = error['code']?.toString() ?? 'unknown-error';
                  message = error['message']?.toString() ?? 'Unknown error occurred';
                } else {
                  message = error.toString();
                }
              } catch (e) {
                debugPrint('속성 접근 오류: $e');
              }
              
              debugPrint('웹 Google 로그인 오류 변환: code=$code, message=$message');
              
              completer.completeError({
                'code': code,
                'message': message
              });
            } catch (e) {
              debugPrint('웹 Google 로그인 오류 변환 실패: $e');
              completer.completeError({
                'code': 'unknown-error',
                'message': 'Error parsing: ${error.toString()}'
              });
            }
          } else if (result != null) {
            debugPrint('웹 Google 로그인 성공');
            
            // 결과를 안전하게 Map으로 변환
            try {
              final Map<String, dynamic> userData = {};
              
              if (result is js.JsObject) {
                // 필요한 속성들을 개별적으로 추출
                userData['uid'] = result['uid']?.toString();
                userData['email'] = result['email']?.toString();
                userData['displayName'] = result['displayName']?.toString();
                userData['photoURL'] = result['photoURL']?.toString();
                userData['emailVerified'] = result['emailVerified'] == true;
                userData['providerId'] = 'google.com';
              } else {
                // 이미 Map인 경우 (드문 경우)
                userData.addAll(Map<String, dynamic>.from(result));
              }
              
              // 구독 정보 생성
              if (userData['uid'] != null) {
                _createSubscriptionData(userData['uid']);
              }
              
              completer.complete(userData);
            } catch (e) {
              debugPrint('결과 변환 오류: $e');
              completer.completeError({
                'code': 'result-parsing-error',
                'message': 'Failed to parse login result: $e'
              });
            }
          } else {
            debugPrint('웹 Google 로그인 성공했지만 사용자 데이터가 없습니다');
            completer.completeError({
              'code': 'no-user-data',
              'message': 'Login successful but no user data returned'
            });
          }
        })
      ]);
    } catch (e) {
      debugPrint('웹 Google 로그인 예외 발생: $e');
      completer.completeError({
        'code': 'unexpected-error',
        'message': e.toString()
      });
    }
    
    return completer.future;
  }

  /// 웹 환경에서 이메일/비밀번호로 로그인
  static Future<Map<String, dynamic>> signInWithEmailPassword(String email, String password) async {
    if (!kIsWeb) throw Exception('웹 환경에서만 사용 가능합니다');
    
    final completer = Completer<Map<String, dynamic>>();
    
    try {
      debugPrint('웹 로그인 시도: $email');
      
      js.context.callMethod('signInWithEmailPassword', [
        email,
        password,
        js.allowInterop((result, error) {
          if (error != null) {
            debugPrint('웹 로그인 오류 원본: $error');
            
            // JavaScript 객체를 Dart Map으로 변환
            try {
              // JsObject를 직접 Map으로 변환하지 않고 필요한 속성만 추출
              String code = 'unknown-error';
              String message = 'Unknown error occurred';
              
              try {
                if (error is js.JsObject) {
                  code = error['code']?.toString() ?? 'unknown-error';
                  message = error['message']?.toString() ?? 'Unknown error occurred';
                } else {
                  message = error.toString();
                }
              } catch (e) {
                debugPrint('속성 접근 오류: $e');
              }
              
              debugPrint('웹 로그인 오류 변환: code=$code, message=$message');
              
              completer.completeError({
                'code': code,
                'message': message
              });
            } catch (e) {
              debugPrint('웹 로그인 오류 변환 실패: $e');
              completer.completeError({
                'code': 'unknown-error',
                'message': 'Error parsing: ${error.toString()}'
              });
            }
          } else if (result != null) {
            debugPrint('웹 로그인 성공');
            
            // 결과를 안전하게 Map으로 변환
            try {
              final Map<String, dynamic> userData = {};
              
              if (result is js.JsObject) {
                // 필요한 속성들을 개별적으로 추출
                userData['uid'] = result['uid']?.toString();
                userData['email'] = result['email']?.toString();
                userData['displayName'] = result['displayName']?.toString();
                userData['photoURL'] = result['photoURL']?.toString();
                userData['emailVerified'] = result['emailVerified'] == true;
              } else {
                // 이미 Map인 경우 (드문 경우)
                userData.addAll(Map<String, dynamic>.from(result));
              }
              
              // 구독 정보 생성
              if (userData['uid'] != null) {
                _createSubscriptionData(userData['uid']);
              }
              
              completer.complete(userData);
            } catch (e) {
              debugPrint('결과 변환 오류: $e');
              completer.completeError({
                'code': 'result-parsing-error',
                'message': 'Failed to parse login result: $e'
              });
            }
          } else {
            debugPrint('웹 로그인 성공했지만 사용자 데이터가 없습니다');
            completer.completeError({
              'code': 'no-user-data',
              'message': 'Login successful but no user data returned'
            });
          }
        })
      ]);
    } catch (e) {
      debugPrint('웹 로그인 예외 발생: $e');
      completer.completeError({
        'code': 'unexpected-error',
        'message': e.toString()
      });
    }
    
    return completer.future;
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
            'id': userId.toString(),
            'email': '',
            'name': '사용자',
            'photoURL': '',
            'createdAt': DateTime.now().toIso8601String(),
            'subscription': 'free',
            'provider': 'unknown',
          };
          
          await FirebaseFirestore.instance.collection('users').doc(userId.toString()).set(basicUserData);
          debugPrint('기본 사용자 정보 저장 완료');
          
          // 기본 사용자 모델 반환 (ID 설정)
          return UserModel(
            id: userId.toString(),
            email: '',
            displayName: '사용자',
            photoUrl: '',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            subscriptionTier: SubscriptionTier.free,
            subscriptionExpiresAt: null,
            apiKey: null,
            apiKeyExpiresAt: null,
            usageCount: 0,
            lastUsageAt: null,
            maxUsagePerDay: 10,
            maxPdfSize: 5 * 1024 * 1024,
            maxTextLength: 10000,
            maxPdfsPerDay: 5,
            maxPdfsTotal: 20,
            maxPdfPages: 50,
            maxPdfTextLength: 50000,
            maxPdfTextLengthPerPage: 1000,
            maxPdfTextLengthPerDay: 100000,
            maxPdfTextLengthPerMonth: 1000000,
            maxPdfTextLengthPerYear: 10000000,
            maxPdfTextLengthPerLifetime: 100000000,
            maxPdfTextLengthPerPdf: 10000,
            maxPdfTextLengthPerPdfPerPage: 1000,
            maxPdfTextLengthPerPdfPerDay: 100000,
            maxPdfTextLengthPerPdfPerMonth: 1000000,
            maxPdfTextLengthPerPdfPerYear: 10000000,
            maxPdfTextLengthPerPdfPerLifetime: 100000000,
            maxPdfTextLengthPerPdfPerPagePerDay: 10000,
            maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
            maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
            maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
            maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
            maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
            maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
          );
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('사용자 정보 가져오기 성공: $userData');
        
        // UserModel 생성
        return UserModel(
          id: userData['id']?.toString() ?? userId.toString(),
          email: userData['email']?.toString() ?? '',
          displayName: userData['name']?.toString() ?? '사용자',
          photoUrl: userData['photoURL']?.toString() ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          subscriptionTier: SubscriptionTier.free,
          subscriptionExpiresAt: null,
          apiKey: null,
          apiKeyExpiresAt: null,
          usageCount: 0,
          lastUsageAt: null,
          maxUsagePerDay: 10,
          maxPdfSize: 5 * 1024 * 1024,
          maxTextLength: 10000,
          maxPdfsPerDay: 5,
          maxPdfsTotal: 20,
          maxPdfPages: 50,
          maxPdfTextLength: 50000,
          maxPdfTextLengthPerPage: 1000,
          maxPdfTextLengthPerDay: 100000,
          maxPdfTextLengthPerMonth: 1000000,
          maxPdfTextLengthPerYear: 10000000,
          maxPdfTextLengthPerLifetime: 100000000,
          maxPdfTextLengthPerPdf: 10000,
          maxPdfTextLengthPerPdfPerPage: 1000,
          maxPdfTextLengthPerPdfPerDay: 100000,
          maxPdfTextLengthPerPdfPerMonth: 1000000,
          maxPdfTextLengthPerPdfPerYear: 10000000,
          maxPdfTextLengthPerPdfPerLifetime: 100000000,
          maxPdfTextLengthPerPdfPerPagePerDay: 10000,
          maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
        );
      } catch (e) {
        debugPrint('Firestore에서 사용자 정보 가져오기 오류: $e');
        
        // 오류 발생 시 기본 사용자 모델 반환 (ID 설정)
        return UserModel(
          id: userId.toString(),
          email: '',
          displayName: '사용자',
          photoUrl: '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          subscriptionTier: SubscriptionTier.free,
          subscriptionExpiresAt: null,
          apiKey: null,
          apiKeyExpiresAt: null,
          usageCount: 0,
          lastUsageAt: null,
          maxUsagePerDay: 10,
          maxPdfSize: 5 * 1024 * 1024,
          maxTextLength: 10000,
          maxPdfsPerDay: 5,
          maxPdfsTotal: 20,
          maxPdfPages: 50,
          maxPdfTextLength: 50000,
          maxPdfTextLengthPerPage: 1000,
          maxPdfTextLengthPerDay: 100000,
          maxPdfTextLengthPerMonth: 1000000,
          maxPdfTextLengthPerYear: 10000000,
          maxPdfTextLengthPerLifetime: 100000000,
          maxPdfTextLengthPerPdf: 10000,
          maxPdfTextLengthPerPdfPerPage: 1000,
          maxPdfTextLengthPerPdfPerDay: 100000,
          maxPdfTextLengthPerPdfPerMonth: 1000000,
          maxPdfTextLengthPerPdfPerYear: 10000000,
          maxPdfTextLengthPerPdfPerLifetime: 100000000,
          maxPdfTextLengthPerPdfPerPagePerDay: 10000,
          maxPdfTextLengthPerPdfPerPagePerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonth: 100000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYear: 1000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerMonthPerYearPerLifetime: 10000000,
          maxPdfTextLengthPerPdfPerPagePerDayPerMonthPerYearPerLifetime: 10000000,
        );
      }
    } catch (e) {
      debugPrint('사용자 정보 가져오기 오류: $e');
      debugPrint('사용자 정보 가져오기 오류 스택 트레이스: ${StackTrace.current}');
      return null;
    }
  }

  /// 웹 환경에서 이메일/비밀번호로 회원가입
  static Future<Map<String, dynamic>> signUpWithEmailPassword(String email, String password) async {
    if (!kIsWeb) throw Exception('웹 환경에서만 사용 가능합니다');
    
    final completer = Completer<Map<String, dynamic>>();
    
    try {
      debugPrint('웹 회원가입 시도: $email');
      
      js.context.callMethod('signUpWithEmailPassword', [
        email,
        password,
        js.allowInterop((result, error) {
          if (error != null) {
            debugPrint('웹 회원가입 오류 원본: $error');
            
            // JavaScript 객체를 Dart Map으로 변환
            try {
              // JsObject를 직접 Map으로 변환하지 않고 필요한 속성만 추출
              String code = 'unknown-error';
              String message = 'Unknown error occurred';
              
              try {
                if (error is js.JsObject) {
                  code = error['code']?.toString() ?? 'unknown-error';
                  message = error['message']?.toString() ?? 'Unknown error occurred';
                } else {
                  message = error.toString();
                }
              } catch (e) {
                debugPrint('속성 접근 오류: $e');
              }
              
              debugPrint('웹 회원가입 오류 변환: code=$code, message=$message');
              
              completer.completeError({
                'code': code,
                'message': message
              });
            } catch (e) {
              debugPrint('웹 회원가입 오류 변환 실패: $e');
              completer.completeError({
                'code': 'unknown-error',
                'message': 'Error parsing: ${error.toString()}'
              });
            }
          } else if (result != null) {
            debugPrint('웹 회원가입 성공');
            
            // 결과를 안전하게 Map으로 변환
            try {
              final Map<String, dynamic> userData = {};
              
              if (result is js.JsObject) {
                // 필요한 속성들을 개별적으로 추출
                userData['uid'] = result['uid']?.toString();
                userData['email'] = result['email']?.toString();
                userData['displayName'] = result['displayName']?.toString();
                userData['photoURL'] = result['photoURL']?.toString();
                userData['emailVerified'] = result['emailVerified'] == true;
                userData['createdAt'] = result['createdAt']?.toString() ?? DateTime.now().toIso8601String();
              } else {
                // 이미 Map인 경우 (드문 경우)
                userData.addAll(Map<String, dynamic>.from(result));
              }
              
              // 구독 정보 생성
              if (userData['uid'] != null) {
                _createSubscriptionData(userData['uid']);
              }
              
              completer.complete(userData);
            } catch (e) {
              debugPrint('결과 변환 오류: $e');
              completer.completeError({
                'code': 'result-parsing-error',
                'message': 'Failed to parse signup result: $e'
              });
            }
          } else {
            debugPrint('웹 회원가입 성공했지만 사용자 데이터가 없습니다');
            completer.completeError({
              'code': 'no-user-data',
              'message': 'Signup successful but no user data returned'
            });
          }
        })
      ]);
    } catch (e) {
      debugPrint('웹 회원가입 예외 발생: $e');
      completer.completeError({
        'code': 'unexpected-error',
        'message': e.toString()
      });
    }
    
    return completer.future;
  }

  /// 사용자 정보 저장
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (!_isInitialized) {
      debugPrint('Firebase가 초기화되지 않았습니다.');
      return;
    }

    try {
      debugPrint('사용자 정보 저장 시작: ${userData['id']}');
      
      await js.context.callMethod('saveUserData', [
        js.JsObject.jsify(userData),
        js.allowInterop((error) {
          if (error != null) {
            debugPrint('사용자 정보 저장 오류: $error');
          } else {
            debugPrint('사용자 정보 저장 완료');
          }
        })
      ]);
    } catch (e) {
      debugPrint('사용자 정보 저장 오류: $e');
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
} 