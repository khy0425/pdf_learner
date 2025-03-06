import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/pdf_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_page.dart';
import 'screens/desktop_home_page.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/bookmark_provider.dart';
import 'providers/tutorial_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/firebase_auth_service.dart';
import 'providers/auth_service.dart';
import 'providers/storage_service.dart';
import 'services/subscription_service.dart';
import 'services/web_firebase_initializer.dart';
import 'services/anonymous_user_service.dart';
import 'services/api_key_service.dart';
import 'services/web_pdf_service.dart';
import 'services/pdf_service.dart';
import 'services/usage_limiter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 먼저 환경 변수 로드
    await dotenv.load(fileName: ".env");
    
    // 환경 변수 로드 확인
    print('환경 변수 로드 완료');
    print('FIREBASE_API_KEY: ${dotenv.env['FIREBASE_API_KEY']}');
    print('FIREBASE_PROJECT_ID: ${dotenv.env['FIREBASE_PROJECT_ID']}');
    
    // 윈도우 크기 설정 (웹이 아닌 경우에만)
    if (!kIsWeb) {
      try {
        if (Platform.isWindows) {
          setWindowTitle('AI PDF 학습 도우미');
          setWindowMinSize(const Size(800, 600));
          setWindowMaxSize(Size.infinite);
        }
      } catch (e) {
        print('윈도우 크기 설정 오류: $e');
      }
    }

    // Firebase 초기화
    if (kIsWeb) {
      // 웹 환경에서는 JavaScript에서 로드된 Firebase 설정을 사용
      try {
        print('웹 환경에서 Firebase 초기화 시작');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase 초기화 완료');
        
        // JavaScript를 통해 Firebase 초기화 (이중 초기화를 방지하기 위한 호출)
        WebFirebaseInitializer.initializeFirebase();
      } catch (e) {
        print('Firebase 초기화 오류: $e');
      }
    } else {
      // 네이티브 환경에서는 Firebase SDK를 통해 초기화
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PDFProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => BookmarkProvider()),
          ChangeNotifierProvider(create: (_) => TutorialProvider()),
          ChangeNotifierProvider(create: (_) => FirebaseAuthService()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          Provider(create: (_) => StorageService()),
          Provider(create: (_) => SubscriptionService()),
          Provider(create: (_) => AnonymousUserService()),
          Provider(create: (_) => ApiKeyService()),
          Provider(create: (_) => WebPdfService()),
          Provider(create: (_) => PDFService()),
          Provider(
            create: (context) => UsageLimiter(
              context.read<SubscriptionService>(),
              context.read<PDFService>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('초기화 오류: $e');
    // 오류 발생 시 기본 에러 화면 표시
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('앱 초기화 중 오류가 발생했습니다: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PDF Learner',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthService>(
            builder: (context, authService, _) {
              if (authService.isLoggedIn) {
                // 로그인된 경우 홈 화면 표시
                return const HomeScreen();
              } else {
                // 로그인되지 않은 경우 로그인 화면 표시
                return AuthScreen();
              }
            },
          ),
        );
      },
    );
  }
} 