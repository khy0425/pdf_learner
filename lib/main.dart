import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// MVVM 패턴 적용을 위한 임포트
import 'view_models/auth_view_model.dart';
import 'view_models/pdf_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/pdf_viewer_view_model.dart';
import 'view_models/pdf_file_view_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/pdf_repository.dart';
import 'services/api_key_service.dart';
import 'services/web_firebase_initializer.dart';
import 'views/home_page.dart';
import 'views/auth_screen.dart';
import 'theme/app_theme.dart';

// 디버그 상수
const bool DEBUG_USE_TEST_APP = false; // 테스트 앱으로 문제를 확인했으므로 실제 앱으로 전환

/// 앱 로깅 관리 클래스
class AppLogger {
  /// 로그 표시 여부
  static bool _enableLogs = false; // 기본값을 false로 변경
  
  /// 로그 활성화 설정
  static void enableLogs(bool enable) {
    _enableLogs = enable && kDebugMode;
  }
  
  /// 일반 로그 출력
  static void log(String message) {
    if (_enableLogs) {
      debugPrint('[PDF Learner] $message');
    }
  }
  
  /// 오류 로그 출력 (릴리즈 모드에서도 중요 오류는 기록)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // 심각한 오류만 로깅
    if (error != null) {
      debugPrint('[PDF Learner ERROR] $message ${error != null ? '- $error' : ''}');
      if (stackTrace != null && _enableLogs) {
        debugPrint(stackTrace.toString());
      }
    } else if (_enableLogs) {
      debugPrint('[PDF Learner ERROR] $message');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 로그 활성화 (디버그 모드에서만)
  AppLogger.enableLogs(kDebugMode);
  
  // 전역 오류 처리
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('앱 실행 중 예외 발생', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  
  // 비동기 오류 처리
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('플랫폼 비동기 오류', error, stack);
    return true;
  };
  
  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    AppLogger.log('Firebase 초기화 완료');
    
    // 웹 환경에서 추가 초기화
    if (kIsWeb) {
      try {
        final webInitializer = WebFirebaseInitializer();
        await webInitializer.initialize();
        AppLogger.log('웹 Firebase 초기화 완료');
      } catch (e) {
        AppLogger.error('웹 Firebase 초기화 실패', e);
        // 웹 초기화 실패해도 앱은 계속 실행
      }
    }
  } catch (e, stackTrace) {
    AppLogger.error('Firebase 초기화 실패', e, stackTrace);
    // Firebase 초기화 실패해도 앱은 계속 실행
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 저장소 계층
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<UserRepository>(
          create: (_) => UserRepository(),
        ),
        Provider<PdfRepository>(
          create: (_) => PdfRepository(),
        ),
        
        // 서비스 계층
        Provider<ApiKeyService>(
          create: (_) => ApiKeyService(),
        ),
        Provider<WebFirebaseInitializer>(
          create: (_) => WebFirebaseInitializer(),
        ),
        
        // ViewModel 계층
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
            userRepository: context.read<UserRepository>(),
            apiKeyService: context.read<ApiKeyService>(),
          ),
        ),
        ChangeNotifierProvider<PdfViewModel>(
          create: (context) => PdfViewModel(
            pdfRepository: context.read<PdfRepository>(),
            userRepository: context.read<UserRepository>(),
            apiKeyService: context.read<ApiKeyService>(),
          ),
        ),
        ChangeNotifierProvider<PdfFileViewModel>(
          create: (context) => PdfFileViewModel(),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(),
        ),
        ChangeNotifierProvider<PdfViewerViewModel>(
          create: (context) => PdfViewerViewModel(
            pdfViewModel: context.read<PdfFileViewModel>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'PDF Learner',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/auth': (context) => const AuthScreen(),
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', ''), // 한국어
          Locale('en', ''), // 영어
        ],
        // 앱 전체 오류 처리
        builder: (context, child) {
          // 오류 화면 처리
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Material(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text('오류가 발생했습니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(details.exception.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        child: const Text('홈으로 돌아가기'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          
          return child!;
        },
      ),
    );
  }
} 