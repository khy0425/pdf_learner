import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/pdf_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_page.dart';
import 'screens/desktop_home_page.dart';
import 'theme/app_theme.dart';
import 'providers/bookmark_provider.dart';
import 'providers/tutorial_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");
  
  // 윈도우 크기 설정 (데스크톱인 경우)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('AI PDF 학습 도우미');
    setWindowMinSize(const Size(800, 600));
    setWindowMaxSize(Size.infinite);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PDFProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => TutorialProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAuthService()),
      ],
      child: const MyApp(),
    ),
  );
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
          home: Platform.isWindows || Platform.isLinux || Platform.isMacOS
              ? const DesktopHomePage()
              : const HomePage(),
        );
      },
    );
  }
} 