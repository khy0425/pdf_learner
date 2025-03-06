import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// 웹 환경에서 Firebase를 초기화하는 서비스
class WebFirebaseInitializer {
  /// 환경 변수에서 값을 가져오는 헬퍼 메서드
  static String _getEnvValue(String key) {
    final value = dotenv.env[key];
    debugPrint('환경 변수 $key: ${value ?? "값 없음"}');
    if (value == null || value.isEmpty) return '';
    // 따옴표 제거
    final cleanValue = value.replaceAll('"', '');
    return cleanValue;
  }

  /// 웹 환경에서 JavaScript를 통해 Firebase를 초기화합니다.
  static void initializeFirebase() {
    if (!kIsWeb) return;

    try {
      // JavaScript에서 직접 Firebase 설정을 가져옵니다.
      final jsFirebaseConfig = js.context['firebaseConfig'];
      
      if (jsFirebaseConfig != null) {
        debugPrint('JavaScript에서 Firebase 설정을 가져왔습니다.');
        
        // JavaScript 객체에서 필요한 값들을 추출
        final Map<String, dynamic> firebaseConfig = {
          'apiKey': jsFirebaseConfig['apiKey']?.toString() ?? '',
          'authDomain': jsFirebaseConfig['authDomain']?.toString() ?? '',
          'projectId': jsFirebaseConfig['projectId']?.toString() ?? '',
          'storageBucket': jsFirebaseConfig['storageBucket']?.toString() ?? '',
          'messagingSenderId': jsFirebaseConfig['messagingSenderId']?.toString() ?? '',
          'appId': jsFirebaseConfig['appId']?.toString() ?? '',
          'measurementId': jsFirebaseConfig['measurementId']?.toString() ?? '',
        };
        
        debugPrint('JavaScript에서 가져온 Firebase 설정: $firebaseConfig');
        
        // 필수 값이 있는지 확인
        if (firebaseConfig['apiKey']!.isEmpty || firebaseConfig['projectId']!.isEmpty) {
          debugPrint('JavaScript에서 가져온 Firebase 설정에 필수 값이 없습니다.');
          
          // .env 파일에서 시도
          _initializeFromEnv();
          return;
        }
        
        // 이미 초기화되었는지 확인
        final firebaseApps = js.context['firebase']?['apps'];
        if (firebaseApps != null && firebaseApps.length > 0) {
          debugPrint('Firebase가 이미 초기화되어 있습니다.');
          return;
        }
        
        // JavaScript 함수 호출하여 Firebase 초기화
        final jsObject = js.JsObject.jsify(firebaseConfig);
        js.context.callMethod('initializeFirebase', [jsObject]);
        debugPrint('JavaScript를 통해 Firebase 초기화 완료');
        return;
      }
      
      // JavaScript에서 설정을 가져오지 못한 경우 .env 파일에서 시도
      _initializeFromEnv();
    } catch (e) {
      debugPrint('JavaScript를 통해 Firebase 초기화 오류: $e');
      // 오류 발생 시 .env 파일에서 시도
      _initializeFromEnv();
    }
  }
  
  /// .env 파일에서 Firebase 설정을 가져와 초기화합니다.
  static void _initializeFromEnv() {
    try {
      final firebaseConfig = {
        'apiKey': _getEnvValue('FIREBASE_API_KEY'),
        'authDomain': _getEnvValue('FIREBASE_AUTH_DOMAIN'),
        'projectId': _getEnvValue('FIREBASE_PROJECT_ID'),
        'storageBucket': _getEnvValue('FIREBASE_STORAGE_BUCKET'),
        'messagingSenderId': _getEnvValue('FIREBASE_MESSAGING_SENDER_ID'),
        'appId': _getEnvValue('FIREBASE_APP_ID'),
        'measurementId': _getEnvValue('FIREBASE_MEASUREMENT_ID'),
      };

      debugPrint('.env 파일에서 가져온 Firebase 설정: $firebaseConfig');
      
      // 필수 값이 있는지 확인
      if (firebaseConfig['apiKey']!.isEmpty || firebaseConfig['projectId']!.isEmpty) {
        debugPrint('Firebase 초기화 실패: API 키 또는 프로젝트 ID가 비어 있습니다.');
        
        // 하드코딩된 값으로 시도
        _initializeWithHardcodedValues();
        return;
      }

      // JavaScript 함수 호출하여 Firebase 초기화
      final jsObject = js.JsObject.jsify(firebaseConfig);
      js.context.callMethod('initializeFirebase', [jsObject]);
      debugPrint('JavaScript를 통해 Firebase 초기화 완료 (.env 파일 사용)');
    } catch (e) {
      debugPrint('.env 파일에서 Firebase 초기화 오류: $e');
      // 오류 발생 시 하드코딩된 값으로 시도
      _initializeWithHardcodedValues();
    }
  }
  
  /// 하드코딩된 값으로 Firebase를 초기화합니다.
  static void _initializeWithHardcodedValues() {
    try {
      final firebaseConfig = {
        'apiKey': 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM',
        'authDomain': 'pdf-learner.firebaseapp.com',
        'projectId': 'pdf-learner',
        'storageBucket': 'pdf-learner.appspot.com',
        'messagingSenderId': '189136888100',
        'appId': '1:189136888100:web:3c36f821c673adc13e93b1',
        'measurementId': 'G-3LS46XS1LS',
      };

      debugPrint('하드코딩된 값으로 Firebase 설정: $firebaseConfig');
      
      // JavaScript 함수 호출하여 Firebase 초기화
      final jsObject = js.JsObject.jsify(firebaseConfig);
      js.context.callMethod('initializeFirebase', [jsObject]);
      debugPrint('JavaScript를 통해 Firebase 초기화 완료 (하드코딩된 값 사용)');
    } catch (e) {
      debugPrint('하드코딩된 값으로 Firebase 초기화 오류: $e');
    }
  }

  /// API 키 가져오기
  static Future<String?> getApiKey(String keyName) async {
    if (!kIsWeb) return null;
    
    try {
      // JavaScript에서 직접 API 키 가져오기
      final apiKey = js.context.callMethod('getApiKey', [keyName]);
      debugPrint('JavaScript에서 API 키 가져오기 결과: $apiKey');
      return apiKey?.toString();
    } catch (e) {
      debugPrint('웹 API 키 가져오기 예외: $e');
      
      // 오류 발생 시 하드코딩된 값 반환
      if (keyName == 'gemini') {
        return 'AIzaSyBS3xinuJpr9DIGLAqTCKHCg6XqZjeoB74';
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
      debugPrint('JavaScript에서 API 키 유효성 검사 결과: $result');
      return result == true;
    } catch (e) {
      debugPrint('웹 API 키 유효성 검사 예외: $e');
      
      // 특정 API 키는 항상 유효하다고 처리 (테스트용)
      if (apiKey == 'AIzaSyBS3xinuJpr9DIGLAqTCKHCg6XqZjeoB74') {
        debugPrint('테스트용 API 키가 확인되었습니다');
        return true;
      }
      
      return false;
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

  /// 웹 환경에서 로그아웃
  static Future<void> signOut() async {
    if (!kIsWeb) return;
    
    final completer = Completer<void>();
    
    try {
      js.context.callMethod('signOut', [
        js.allowInterop((error) {
          if (error != null) {
            completer.completeError(error.toString());
          } else {
            completer.complete();
          }
        })
      ]);
    } catch (e) {
      completer.completeError('JavaScript 함수 호출 오류: $e');
    }
    
    return completer.future;
  }

  /// 웹 환경에서 현재 로그인된 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!kIsWeb) return null;
    
    final completer = Completer<Map<String, dynamic>?>();
    
    try {
      js.context.callMethod('getCurrentUser', [
        js.allowInterop((result, error) {
          if (error != null) {
            debugPrint('웹 사용자 정보 가져오기 오류 원본: $error');
            
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
              
              completer.completeError({
                'code': code,
                'message': message
              });
            } catch (e) {
              completer.completeError('JavaScript 함수 호출 오류: $e');
            }
          } else if (result == null) {
            completer.complete(null);
          } else {
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
              
              completer.complete(userData);
            } catch (e) {
              debugPrint('결과 변환 오류: $e');
              completer.completeError({
                'code': 'result-parsing-error',
                'message': 'Failed to parse user data: $e'
              });
            }
          }
        })
      ]);
    } catch (e) {
      completer.completeError('JavaScript 함수 호출 오류: $e');
    }
    
    return completer.future;
  }
} 