import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import '../utils/secrets_manager.dart';
import '../services/env_loader.dart';

/// 동적으로 Firebase 설정을 관리하는 클래스
class FirebaseConfig {
  static final FirebaseConfig _instance = FirebaseConfig._internal();
  
  factory FirebaseConfig() => _instance;
  
  FirebaseConfig._internal();
  
  final SecretsManager _secretsManager = SecretsManager();
  final EnvLoader _envLoader = EnvLoader();
  
  /// 플랫폼에 맞는 Firebase 옵션을 동적으로 생성
  Future<FirebaseOptions> get currentPlatformOptions async {
    // 환경 변수 로더 초기화 확인
    await _envLoader.initialize();
    
    if (kIsWeb) {
      return await _getWebOptions();
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _getAndroidOptions();
      case TargetPlatform.iOS:
        return await _getIOSOptions();
      case TargetPlatform.macOS:
        return await _getMacOSOptions();
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.');
    }
  }
  
  /// 웹 플랫폼용 Firebase 옵션 가져오기
  Future<FirebaseOptions> _getWebOptions() async {
    // 먼저 시크릿 매니저에서 값을 확인하고, 없으면 환경 변수에서 가져옴
    final apiKey = await _secretsManager.getFirebaseApiKey() ?? 
                    await _envLoader.firebaseApiKey ?? 'AIzaSyCpTt_AlV22_oeH9A2azgGfHAa19AoTjx0';
    final appId = await _secretsManager.getFirebaseAppId() ?? 
                    await _envLoader.firebaseAppId ?? '1:189136888100:web:3c36f821c673adc13e93b1';
    final messagingSenderId = await _secretsManager.getFirebaseMessagingSenderId() ?? 
                              await _envLoader.firebaseMessagingSenderId ?? '189136888100';
    final projectId = await _secretsManager.getFirebaseProjectId() ?? 
                      await _envLoader.firebaseProjectId ?? 'pdf-learner';
    final storageBucket = await _secretsManager.getFirebaseStorageBucket() ?? 
                          await _envLoader.firebaseStorageBucket ?? 'pdf-learner.firebasestorage.app';
    
    return FirebaseOptions(
      apiKey: apiKey.toString(),
      appId: appId.toString(),
      messagingSenderId: messagingSenderId.toString(),
      projectId: projectId.toString(),
      storageBucket: storageBucket.toString(),
      authDomain: await _envLoader.firebaseAuthDomain ?? 'pdf-learner.firebaseapp.com',
      measurementId: await _envLoader.firebaseMeasurementId ?? 'G-3LS46XS1LS',
    );
  }
  
  /// 안드로이드용 Firebase 옵션 가져오기
  Future<FirebaseOptions> _getAndroidOptions() async {
    final apiKey = await _secretsManager.getFirebaseApiKey() ?? 
                    _envLoader.firebaseWebApiKey ?? 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM';
    final appId = await _envLoader.firebaseAndroidAppId ?? '1:189136888100:android:2abd7262d4d575e03e93b1';
    final messagingSenderId = await _secretsManager.getFirebaseMessagingSenderId() ?? 
                              await _envLoader.firebaseMessagingSenderId ?? '189136888100';
    final projectId = await _secretsManager.getFirebaseProjectId() ?? 
                      await _envLoader.firebaseProjectId ?? 'pdf-learner';
    final storageBucket = await _secretsManager.getFirebaseStorageBucket() ?? 
                          await _envLoader.firebaseStorageBucket ?? 'pdf-learner.firebasestorage.app';
    
    return FirebaseOptions(
      apiKey: apiKey.toString(),
      appId: appId.toString(),
      messagingSenderId: messagingSenderId.toString(),
      projectId: projectId.toString(),
      storageBucket: storageBucket.toString(),
      // androidPackageName은 지원되지 않으므로 제거
    );
  }
  
  /// iOS용 Firebase 옵션 가져오기
  Future<FirebaseOptions> _getIOSOptions() async {
    final apiKey = await _secretsManager.getFirebaseApiKey() ?? 
                   _envLoader.firebaseWebApiKey ?? 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM';
    final appId = await _secretsManager.getFirebaseAppId() ?? 
                  await _envLoader.firebaseAppId ?? '1:189136888100:ios:YOUR_IOS_APP_ID';
    final messagingSenderId = await _secretsManager.getFirebaseMessagingSenderId() ?? 
                              await _envLoader.firebaseMessagingSenderId ?? '189136888100';
    final projectId = await _secretsManager.getFirebaseProjectId() ?? 
                      await _envLoader.firebaseProjectId ?? 'pdf-learner';
    final storageBucket = await _secretsManager.getFirebaseStorageBucket() ?? 
                          await _envLoader.firebaseStorageBucket ?? 'pdf-learner.firebasestorage.app';
    final iosBundleId = 'com.reaf.pdf_learner';
    
    return FirebaseOptions(
      apiKey: apiKey.toString(),
      appId: appId.toString(),
      messagingSenderId: messagingSenderId.toString(),
      projectId: projectId.toString(),
      storageBucket: storageBucket.toString(),
      iosClientId: _envLoader.firebaseIosClientId ?? 'YOUR_IOS_CLIENT_ID',
      iosBundleId: iosBundleId,
    );
  }
  
  /// macOS용 Firebase 옵션 가져오기
  Future<FirebaseOptions> _getMacOSOptions() async {
    final apiKey = await _secretsManager.getFirebaseApiKey() ?? 
                   _envLoader.firebaseWebApiKey ?? 'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM';
    final appId = await _secretsManager.getFirebaseAppId() ?? 
                  _envLoader.firebaseAppId ?? '1:189136888100:ios:YOUR_MACOS_APP_ID';
    final messagingSenderId = await _secretsManager.getFirebaseMessagingSenderId() ?? 
                              _envLoader.firebaseMessagingSenderId ?? '189136888100';
    final projectId = await _secretsManager.getFirebaseProjectId() ?? 
                      _envLoader.firebaseProjectId ?? 'pdf-learner';
    final storageBucket = await _secretsManager.getFirebaseStorageBucket() ?? 
                          _envLoader.firebaseStorageBucket ?? 'pdf-learner.firebasestorage.app';
    final macOsBundleId = 'com.reaf.pdf_learner';
    
    return FirebaseOptions(
      apiKey: apiKey.toString(),
      appId: appId.toString(),
      messagingSenderId: messagingSenderId.toString(),
      projectId: projectId.toString(),
      storageBucket: storageBucket.toString(),
      iosClientId: _envLoader.firebaseIosClientId ?? 'YOUR_MACOS_CLIENT_ID',
      iosBundleId: macOsBundleId,
    );
  }
  
  /// Firebase 설정을 저장
  Future<void> saveFirebaseConfig({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
    required String storageBucket,
  }) async {
    await _secretsManager.saveFirebaseApiKey(apiKey);
    await _secretsManager.saveFirebaseAppId(appId);
    await _secretsManager.saveFirebaseMessagingSenderId(messagingSenderId);
    await _secretsManager.saveFirebaseProjectId(projectId);
    await _secretsManager.saveFirebaseStorageBucket(storageBucket);
  }
} 