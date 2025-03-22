import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'viewmodels/document_list_viewmodel.dart';
import 'services/auth_service.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:provider/single_child_widget.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/pdf_viewer_page.dart';
import 'views/premium_subscription_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 - 옵션 설정 추가
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 초기화 성공!');
  } catch (e) {
    print('Firebase 초기화 실패: $e');
    // Firebase 초기화 실패해도 앱은 계속 실행
  }
  
  // 앱 설정 로드
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  // 문서 목록 뷰모델 인스턴스 생성
  final documentListViewModel = DocumentListViewModel();
  
  try {
    // 문서 목록 로드
    await documentListViewModel.loadDocuments();
  } catch (e) {
    print('문서 로드 중 오류 발생: $e');
    // 오류가 발생해도 앱은 계속 실행
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
      ],
      child: MyApp(isDarkMode: isDarkMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  
  const MyApp({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Learner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/viewer': (context) => const PdfViewerPage(),
        '/premium': (context) => const PremiumSubscriptionPage(),
      },
    );
  }
}