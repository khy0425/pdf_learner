import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 기본 Firebase 프로젝트 설정
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// 환경 변수에서 값을 가져오는 헬퍼 메서드
  static String _getEnvValue(String key, String defaultValue) {
    try {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty) return defaultValue;
      // 따옴표 제거
      return value.replaceAll('"', '');
    } catch (e) {
      // 환경 변수를 로드할 수 없는 경우 기본값 반환
      return defaultValue;
    }
  }

  /// Web 플랫폼 Firebase 설정
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_API_KEY', 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM'),
        appId: _getEnvValue('FIREBASE_APP_ID', '1:189136888100:web:3c36f821c673adc13e93b1'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        authDomain: _getEnvValue('FIREBASE_AUTH_DOMAIN', 'pdf-learner.firebaseapp.com'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
        measurementId: _getEnvValue('FIREBASE_MEASUREMENT_ID', 'G-MEASUREMENT_ID'),
      );

  /// Android 플랫폼 Firebase 설정
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_ANDROID_API_KEY', 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM'),
        appId: _getEnvValue('FIREBASE_ANDROID_APP_ID', '1:189136888100:android:2abd7262d4d575e03e93b1'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
      );

  /// iOS 플랫폼 Firebase 설정
  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_IOS_API_KEY', 'YOUR_IOS_API_KEY'),
        appId: _getEnvValue('FIREBASE_IOS_APP_ID', '1:189136888100:ios:YOUR_IOS_APP_ID'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
        iosClientId: _getEnvValue('FIREBASE_IOS_CLIENT_ID', 'YOUR_IOS_CLIENT_ID'),
        iosBundleId: _getEnvValue('FIREBASE_IOS_BUNDLE_ID', 'com.example.iosApp'),
      );

  /// macOS 플랫폼 Firebase 설정
  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_MACOS_API_KEY', 'YOUR_MACOS_API_KEY'),
        appId: _getEnvValue('FIREBASE_MACOS_APP_ID', '1:189136888100:macos:YOUR_MACOS_APP_ID'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
        iosBundleId: _getEnvValue('FIREBASE_MACOS_BUNDLE_ID', 'com.example.macosApp'),
      );

  /// Windows 플랫폼 Firebase 설정
  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_API_KEY', 'YOUR_WINDOWS_API_KEY'),
        appId: _getEnvValue('FIREBASE_APP_ID', '1:189136888100:windows:YOUR_WINDOWS_APP_ID'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
        authDomain: _getEnvValue('FIREBASE_AUTH_DOMAIN', 'pdf-learner.firebaseapp.com'),
      );

  /// Linux 플랫폼 Firebase 설정
  static FirebaseOptions get linux => FirebaseOptions(
        apiKey: _getEnvValue('FIREBASE_API_KEY', 'YOUR_LINUX_API_KEY'),
        appId: _getEnvValue('FIREBASE_APP_ID', '1:189136888100:linux:YOUR_LINUX_APP_ID'),
        messagingSenderId: _getEnvValue('FIREBASE_MESSAGING_SENDER_ID', '189136888100'),
        projectId: _getEnvValue('FIREBASE_PROJECT_ID', 'pdf-learner'),
        storageBucket: _getEnvValue('FIREBASE_STORAGE_BUCKET', 'pdf-learner.appspot.com'),
        authDomain: _getEnvValue('FIREBASE_AUTH_DOMAIN', 'pdf-learner.firebaseapp.com'),
      );
} 