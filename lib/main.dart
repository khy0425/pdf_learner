import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/viewmodels/pdf_viewmodel.dart';
import 'presentation/viewmodels/auth_view_model.dart';
import 'presentation/di/service_locator.dart';
import 'presentation/pages/signup_page.dart';
import 'presentation/pages/reset_password_page.dart';
import 'presentation/screens/splash_screen.dart';
import 'package:get_it/get_it.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 환경 변수 로드
    await dotenv.load(fileName: '.env');

    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 의존성 주입 초기화
    await configureDependencies();

    runApp(const MyApp());
  } catch (e) {
    debugPrint('앱 초기화 중 오류 발생: $e');
    // 에러 처리 로직 추가
  }
}

/// PDF Learner 앱
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => GetIt.I<AuthViewModel>(),
        ),
        ChangeNotifierProvider<PDFViewModel>(
          create: (_) => GetIt.I<PDFViewModel>(),
        ),
      ],
      child: MaterialApp(
        title: 'PDF Learner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}