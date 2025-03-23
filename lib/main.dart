import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart' if (dart.library.io) './views/stub_firebase.dart';
import 'viewmodels/document_list_viewmodel.dart';
import 'services/auth_service.dart';
import 'views/home_page_new.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart' if (dart.library.io) './views/stub_firebase_options.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'repositories/pdf_repository.dart';
import 'viewmodels/document_actions_viewmodel.dart';
import 'services/thumbnail_service.dart';
import 'services/dialog_service.dart';
import 'services/file_picker_service.dart';
import 'services/theme_service.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/login_page.dart';
import 'services/file_storage_service.dart';
import 'services/subscription_service.dart';
import 'services/firebase_service.dart';
import 'viewmodels/pdf_viewer_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (필요한 경우)
  if (kIsWeb) {
    try {
      debugPrint('Firebase 초기화 시도...');
      // 웹에서는 FirebaseService를 통해 초기화
      await FirebaseService().initialize();
    } catch (e) {
      debugPrint('Firebase 초기화 실패: $e');
    }
  }
  
  // 앱 설정 불러오기
  final prefs = await SharedPreferences.getInstance();
  
  // 테마 서비스 초기화
  final themeService = ThemeService(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        // Firebase 서비스 제공
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
          lazy: false,
        ),
        
        // 테마 서비스 제공
        ChangeNotifierProvider.value(value: themeService),
        
        // 인증 서비스 제공
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // 다이얼로그 서비스 제공
        Provider<DialogService>(
          create: (_) => DialogService(),
        ),
        
        // 저장소 서비스
        Provider<FileStorageService>(
          create: (_) => FileStorageService(),
          dispose: (_, service) => service,
        ),
        
        // 썸네일 서비스
        Provider<ThumbnailService>(
          create: (_) => ThumbnailService(),
          dispose: (_, service) => service,
        ),
        
        // 파일 선택 서비스 제공
        Provider<FilePickerService>(
          create: (_) => FilePickerService(),
        ),
        
        // PDF 저장소
        Provider<PdfRepository>(
          create: (context) => PdfRepository(
            storageService: context.read<FileStorageService>(),
            thumbnailService: context.read<ThumbnailService>(),
          ),
          dispose: (_, repo) => repo.dispose(),
        ),
        
        // 문서 목록 ViewModel 제공
        ChangeNotifierProxyProvider<PdfRepository, DocumentListViewModel>(
          create: (context) => DocumentListViewModel(
            repository: context.read<PdfRepository>(),
          ),
          update: (context, repository, previous) => 
              previous ?? DocumentListViewModel(repository: repository),
        ),
        
        // 문서 액션 ViewModel 제공
        ChangeNotifierProxyProvider2<PdfRepository, DocumentListViewModel, DocumentActionsViewModel>(
          create: (context) => DocumentActionsViewModel(
            repository: context.read<PdfRepository>(),
            listViewModel: context.read<DocumentListViewModel>(),
            filePickerService: context.read<FilePickerService>(),
          ),
          update: (context, repository, listViewModel, previous) => 
              previous ?? DocumentActionsViewModel(
                repository: repository, 
                listViewModel: listViewModel,
                filePickerService: context.read<FilePickerService>(),
              ),
        ),
        
        // 설정 ViewModel 제공
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(prefs),
        ),
        
        // 구독 서비스 제공
        ChangeNotifierProvider(
          create: (context) => SubscriptionService(),
        ),
        
        // PDF 뷰어 뷰모델
        ChangeNotifierProvider<PdfViewerViewModel>(
          create: (context) => PdfViewerViewModel(
            repository: context.read<PdfRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final authService = context.read<AuthService>();
    
    return MaterialApp(
      title: 'PDF 학습 도구',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      debugShowCheckedModeBanner: false,
      home: kIsWeb 
        // 웹에서는 인증 상태 확인 없이 바로 홈페이지로 이동
        ? const HomePage() 
        : StreamBuilder(
            stream: authService.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                final user = snapshot.data;
                if (user != null) {
                  return const HomePage();
                } else {
                  return const LoginPage();
                }
              }
              
              // 로딩 중 표시
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
    );
  }
}