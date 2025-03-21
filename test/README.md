# PDF Learner 테스트 가이드

이 디렉토리에는 PDF Learner 애플리케이션의 테스트 코드가 포함되어 있습니다.

## 테스트 실행 방법

### 기본 테스트 실행
```bash
flutter test
```

### 특정 테스트 실행
```bash
flutter test test/utils/input_validation_simple_test.dart
```

### 여러 테스트 파일 실행
```bash
flutter test test/utils/input_validation_simple_test.dart test/security_single_test.dart
```

## 테스트 디렉토리 구조

- `test/utils/`: 유틸리티 클래스 테스트
- `test/services/`: 서비스 클래스 테스트
- `test/models/`: 모델 클래스 테스트
- `test/view_models/`: 뷰모델 테스트
- `test/security/`: 보안 관련 테스트
- `test/widgets/`: 위젯 테스트

## Firebase 의존성이 있는 코드 테스트

Firebase 의존성이 있는 코드를 테스트하려면 다음과 같은 방법을 사용할 수 있습니다:

1. **Mock 클래스 사용**: Firebase 서비스를 Mock 객체로 대체합니다.
2. **테스트 환경 설정**: `test_helper.dart`의 `setupTestEnvironment()` 함수를 사용하여 테스트 환경을 초기화합니다.
3. **테스트 전용 생성자 사용**: 테스트 전용 생성자를 통해 의존성을 주입합니다.

### Firebase Mock 예제

```dart
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}

// 테스트에서 사용
final mockAuth = MockFirebaseAuth();
final mockFirestore = MockFirestore();

// 테스트 환경 초기화
setUp(() {
  SharedPreferences.setMockInitialValues({});
  
  // 의존성 주입을 통한 테스트
  final service = MyService.forTesting(
    auth: mockAuth,
    firestore: mockFirestore,
  );
  
  // ... 테스트 코드 ...
});
```

## 보안 테스트

보안 테스트는 다음의 영역을 포함합니다:

1. 입력 유효성 검증
2. XSS 방어
3. API 키 보안
4. 비밀번호 강도 측정
5. 요청 속도 제한 (Rate Limiting)
6. 보안 로깅

간단한 보안 테스트를 실행하려면:

```bash
flutter test test/utils/input_validation_simple_test.dart
```

## 주의사항

1. 테스트 코드에서는 가능한 실제 Firebase 서비스를 호출하지 않도록 합니다.
2. `dart:js` 라이브러리를 사용하는 코드는 웹 플랫폼에서만 작동하므로 테스트에서 제외합니다.
3. 테스트 전용 클래스와 메서드는 실제 구현과 메서드 시그니처를 일치시켜야 합니다. 