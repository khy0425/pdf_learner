// Firebase 옵션 스텁 파일
// 웹이 아닌 환경에서 Firebase 없이 테스트할 수 있도록 함

class DefaultFirebaseOptions {
  static final currentPlatform = FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-messaging-sender-id',
    projectId: 'test-project-id',
  );
}

class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  
  FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
  });
} 