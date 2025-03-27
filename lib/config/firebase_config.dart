import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 단순화된 Firebase 설정 클래스
class FirebaseConfig {
  static final FirebaseConfig _instance = FirebaseConfig._internal();
  
  factory FirebaseConfig() => _instance;
  
  FirebaseConfig._internal();
  
  /// 플랫폼에 맞는 Firebase 옵션 반환
  FirebaseOptions get currentPlatformOptions {
    if (kIsWeb) {
      return _getWebOptions();
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _getAndroidOptions();
      case TargetPlatform.iOS:
        return _getIOSOptions();
      case TargetPlatform.macOS:
        return _getMacOSOptions();
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.');
    }
  }
  
  /// 웹 플랫폼용 Firebase 옵션
  FirebaseOptions _getWebOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']!,
    );
  }
  
  /// Android용 Firebase 옵션
  FirebaseOptions _getAndroidOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    );
  }
  
  /// iOS용 Firebase 옵션
  FirebaseOptions _getIOSOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    );
  }
  
  /// macOS용 Firebase 옵션
  FirebaseOptions _getMacOSOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    );
  }
} 