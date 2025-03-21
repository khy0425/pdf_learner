import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/auth_view_model_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late MockAuthViewModel authViewModel;
  
  setUp(() {
    authViewModel = MockAuthViewModel();
  });
  
  group('AuthViewModel 초기화 테스트', () {
    test('초기 상태 확인', () {
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.isLoggedIn, isFalse);
      expect(authViewModel.user, isNotNull);
      expect(authViewModel.user.uid, isEmpty);
      expect(authViewModel.error, isNull);
    });
    
    test('오류 설정 및 초기화', () {
      // 오류 설정
      authViewModel.setTestError('테스트 오류');
      expect(authViewModel.error, equals('테스트 오류'));
      
      // 오류 초기화
      authViewModel.clearError();
      expect(authViewModel.error, isNull);
    });
  });
  
  group('인증 동작 테스트', () {
    test('로그인 성공 시나리오', () async {
      // 로그인 전 상태 확인
      expect(authViewModel.isLoggedIn, isFalse);
      expect(authViewModel.user.uid, isEmpty);
      
      // 로그인 실행
      await authViewModel.mockSignIn(
        uid: 'test-user-123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      // 로그인 후 상태 확인
      expect(authViewModel.isLoggedIn, isTrue);
      expect(authViewModel.user.uid, equals('test-user-123'));
      expect(authViewModel.user.email, equals('test@example.com'));
      expect(authViewModel.user.displayName, equals('Test User'));
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.error, isNull);
    });
    
    test('로그아웃 시나리오', () async {
      // 먼저 로그인
      await authViewModel.mockSignIn(
        uid: 'test-user-123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      // 로그인 상태 확인
      expect(authViewModel.isLoggedIn, isTrue);
      
      // 로그아웃 실행
      await authViewModel.mockSignOut();
      
      // 로그아웃 후 상태 확인
      expect(authViewModel.isLoggedIn, isFalse);
      expect(authViewModel.user.uid, isEmpty);
      expect(authViewModel.isLoading, isFalse);
    });
  });
  
  group('API 키 관리 테스트', () {
    test('API 키 설정 및 가져오기', () async {
      // 먼저 로그인
      await authViewModel.mockSignIn(
        uid: 'test-user-123',
        email: 'test@example.com',
      );
      
      // API 키 설정
      await authViewModel.mockSetApiKey('test-api-key-123');
      
      // API 키 가져오기
      final apiKey = await authViewModel.getApiKey();
      
      // 결과 확인
      expect(apiKey, equals('test-api-key-123'));
      expect(authViewModel.isLoading, isFalse);
    });
  });
} 