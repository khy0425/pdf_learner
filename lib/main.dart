import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'views/home_page_new.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'repositories/pdf_repository.dart';
import 'services/thumbnail_service.dart';
import 'services/dialog_service.dart';
import 'services/file_picker_service.dart';
import 'services/theme_service.dart';
import 'services/api_keys.dart';
import 'services/api_key_service.dart';
import 'views/login_page.dart';
import 'services/file_storage_service.dart';
import 'services/subscription_service.dart';
import 'services/firebase_service.dart';
import 'core/utils/gc_utils.dart';
import 'core/di/injection_container.dart' as di;
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('.env 파일 로드 성공');
  } catch (e) {
    debugPrint('.env 파일 로드 실패: $e');
    return;
  }
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    ),
  );
  
  // 서비스 초기화
  await di.init();
  
  // 메모리 모니터링 시작
  GCUtils.startMemoryMonitoring();
  
  // 앱 설정 불러오기
  final prefs = await SharedPreferences.getInstance();
  
  // 테마 서비스 초기화
  final themeService = ThemeService(prefs);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'PDF 학습기',
            theme: AppTheme.getTheme(),
            darkTheme: AppTheme.getDarkTheme(),
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 학습기'),
      ),
      body: const Center(
        child: Text('PDF 학습기에 오신 것을 환영합니다!'),
      ),
    );
  }
}