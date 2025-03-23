// Firebase 스텁 파일
// 웹이 아닌 환경에서 Firebase 없이 테스트할 수 있도록 함

class Firebase {
  static Future<void> initializeApp({dynamic options}) async {
    // Firebase 초기화가 필요 없는 더미 메소드
    print('Firebase 초기화 스킵 (스텁 사용)');
    return;
  }
}

class FirebaseApp {
  final String name;
  
  FirebaseApp(this.name);
} 