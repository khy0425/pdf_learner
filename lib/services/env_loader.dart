import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 변수를 로드하는 클래스
class EnvLoader {
  // 싱글톤 패턴
  static final EnvLoader _instance = EnvLoader._internal();
  
  // 팩토리 생성자
  factory EnvLoader() => _instance;
  
  // 내부 생성자
  EnvLoader._internal();
  
  // 초기화 완료 여부
  bool _isInitialized = false;
  
  /// 환경 변수 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
      
      if (kDebugMode) {
        print('EnvLoader: .env 파일 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnvLoader: .env 파일 로드 실패 - $e');
      }
    }
  }
  
  /// 초기화 여부 확인
  bool get isInitialized => _isInitialized;
  
  /// 기본 API 키
  Future<String?> get defaultApiKey async {
    await _ensureInitialized();
    return dotenv.env['DEFAULT_API_KEY'];
  }
  
  /// Firebase API 키
  String? get firebaseApiKey {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('EnvLoader: 초기화되지 않았습니다. null 반환');
      }
      return null;
    }
    return dotenv.env['FIREBASE_API_KEY'];
  }
  
  /// Firebase 앱 ID
  String? get firebaseAppId {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_APP_ID'];
  }
  
  /// Firebase 안드로이드 앱 ID
  Future<String?> get firebaseAndroidAppId async {
    await _ensureInitialized();
    return dotenv.env['FIREBASE_ANDROID_APP_ID'];
  }
  
  /// Firebase 안드로이드 패키지 이름
  Future<String?> get firebaseAndroidPackageName async {
    await _ensureInitialized();
    return dotenv.env['FIREBASE_ANDROID_PACKAGE_NAME'];
  }
  
  /// Firebase iOS 앱 ID
  Future<String?> get firebaseIosAppId async {
    await _ensureInitialized();
    return dotenv.env['FIREBASE_IOS_APP_ID'];
  }
  
  /// Firebase iOS 번들 ID
  Future<String?> get firebaseIosBundleId async {
    await _ensureInitialized();
    return dotenv.env['FIREBASE_IOS_BUNDLE_ID'];
  }
  
  /// Firebase 프로젝트 ID
  String? get firebaseProjectId {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_PROJECT_ID'];
  }
  
  /// Firebase 프로젝트 번호
  Future<String?> get firebaseProjectNumber async {
    await _ensureInitialized();
    return dotenv.env['FIREBASE_PROJECT_NUMBER'];
  }
  
  /// Firebase 메시징 발신자 ID
  String? get firebaseMessagingSenderId {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
  }
  
  /// Firebase 스토리지 버킷
  String? get firebaseStorageBucket {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_STORAGE_BUCKET'];
  }
  
  /// Firebase 인증 도메인
  String? get firebaseAuthDomain {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_AUTH_DOMAIN'];
  }
  
  /// Firebase 측정 ID
  String? get firebaseMeasurementId {
    if (!_isInitialized) return null;
    return dotenv.env['FIREBASE_MEASUREMENT_ID'];
  }
  
  /// Firebase 웹 API 키
  String? get firebaseWebApiKey {
    return dotenv.env['FIREBASE_WEB_API_KEY'];
  }
  
  /// Firebase iOS 클라이언트 ID
  String? get firebaseIosClientId {
    return dotenv.env['FIREBASE_IOS_CLIENT_ID'];
  }
  
  /// OpenAI API 키
  Future<String?> get openAiApiKey async {
    await _ensureInitialized();
    return dotenv.env['OPENAI_API_KEY'];
  }
  
  /// Google API 키
  Future<String?> get googleApiKey async {
    await _ensureInitialized();
    return dotenv.env['GOOGLE_API_KEY'];
  }
  
  /// 요약 생성 API 키
  Future<String?> get pdfSummarizeApiKey async {
    await _ensureInitialized();
    return dotenv.env['PDF_SUMMARIZE_API_KEY'];
  }
  
  /// 퀴즈 생성 API 키
  Future<String?> get quizGeneratorApiKey async {
    await _ensureInitialized();
    return dotenv.env['QUIZ_GENERATOR_API_KEY'];
  }
  
  /// 환경 변수 값 가져오기
  Future<String?> get(String key) async {
    await _ensureInitialized();
    return dotenv.env[key];
  }
  
  /// 초기화 확인 및 필요시 초기화
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
} 