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
// 웹 환경에서만 임포트되도록 수정
import 'package:pdf_learner/utils/non_web_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:pdf_learner/utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
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
import 'services/auth_service.dart';
import 'services/web_firebase_initializer.dart';
import 'providers/pdf_provider.dart';
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
  
  // 오류 위젯 커스터마이징 - 앱 시작 즉시 적용
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                '문제가 발생했습니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode 
                    ? details.exception.toString()
                    : '앱에 문제가 발생했습니다. 화면을 다시 로드해 주세요.',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (kDebugMode)
                Text(
                  details.stack.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ElevatedButton(
                onPressed: () {
                  if (kIsWeb) {
                    try {
                      // 안전한 방식으로 페이지 새로고침
                      html.window.location.reload();
                    } catch (e) {
                      // 새로고침 실패 시 로그만 출력
                      AppLogger.error('페이지 새로고침 실패', e);
                    }
                  }
                },
                child: const Text('앱 다시 로드'),
              ),
            ],
          ),
        ),
      ),
    );
  };
  
  // 전역 오류 처리
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('앱 실행 중 예외 발생', details.exception, details.stack);
    
    // 오류를 표시하기만 하고 앱은 계속 실행
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      // 릴리즈 모드에서는 단순히 로깅만 수행
    }
  };
  
  // 비동기 오류 처리
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('플랫폼 비동기 오류', error, stack);
    // true를 반환하여 Flutter가 자체적으로 오류를 처리하지 않게 함
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
  
  // 애플리케이션 실행 코드 부분
  runApp(
    // Provider 설정
    MultiProvider(
      providers: [
        // API 키 서비스
        Provider<ApiKeyService>(
          create: (_) => ApiKeyService(),
        ),
        
        // 인증 서비스
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // 인증 리포지토리
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        
        // 유저 리포지토리
        Provider<UserRepository>(
          create: (_) => UserRepository(),
        ),
        
        // PDF 리포지토리
        Provider<PdfRepository>(
          create: (_) => PdfRepository(),
        ),
        
        // PDF 프로바이더
        ChangeNotifierProvider<PDFProvider>(
          create: (_) => PDFProvider(),
        ),
        
        // 인증 뷰모델
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: Provider.of<AuthRepository>(context, listen: false),
            userRepository: Provider.of<UserRepository>(context, listen: false),
            apiKeyService: Provider.of<ApiKeyService>(context, listen: false),
          ),
        ),
        
        // PDF 뷰모델
        ChangeNotifierProvider<PdfViewModel>(
          create: (context) => PdfViewModel(
            pdfRepository: Provider.of<PdfRepository>(context, listen: false),
            userRepository: Provider.of<UserRepository>(context, listen: false),
            apiKeyService: Provider.of<ApiKeyService>(context, listen: false),
          ),
        ),
        
        // Home 뷰모델 (전역으로 제공)
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        // 앱 리빌드 시 child가 null인 경우 빈 컨테이너 반환
        if (child == null) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: Text('앱 초기화 중 오류가 발생했습니다.'),
            ),
          );
        }

        // 각 페이지를 SafeArea 내에 배치하여 시스템 UI와 겹치지 않도록 함
        return MediaQuery(
          // 시스템 폰트 크기 설정 무시
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: SafeArea(
            child: child,
          ),
        );
      },
    );
  }

  // 웹 환경에서 URL 파라미터 처리
  void _handleUrlParameters() {
    // 웹 환경에서만 실행
    if (kIsWeb) {
      try {
        // URL에서 파라미터 추출
        final uri = Uri.parse(html.window.location.href);
        final params = uri.queryParameters;
        
        // 'pdf' 파라미터가 있으면 PDF 열기
        if (params.containsKey('pdf')) {
          final pdfUrl = params['pdf']!;
          _openPdfFromUrl(pdfUrl);
        }
        
        // 'code' 파라미터가 있으면 인증 코드 처리
        if (params.containsKey('code')) {
          final authCode = params['code']!;
          _handleAuthCode(authCode);
        }
      } catch (e) {
        print('URL 파라미터 처리 오류: $e');
      }
    }
  }
  
  // PDF URL을 열기 위한 메서드
  void _openPdfFromUrl(String pdfUrl) {
    // PDF 열기 로직 구현
    debugPrint('PDF URL 오픈: $pdfUrl');
    // 실제 구현은 PDFProvider를 통해 처리해야 함
  }
  
  // 인증 코드 처리 메서드
  void _handleAuthCode(String authCode) {
    // 인증 코드 처리 로직 구현
    debugPrint('인증 코드 처리: $authCode');
    // 실제 구현은 AuthService를 통해 처리해야 함
  }
} 