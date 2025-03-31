import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'core/di/dependency_injection.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/locale_viewmodel.dart';
import 'presentation/viewmodels/pdf_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_learner_v2/core/utils/web_utils.dart';
import 'core/base/result.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // WebUtils 싱글톤 등록
  WebUtils.registerSingleton();
  
  // 환경 변수 로드 - 다른 초기화보다 먼저 실행
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('환경 변수 로드 성공');
    if (kDebugMode) {
      _logSafeEnvironmentVariables(); // 민감하지 않은 환경 변수만 로깅
    }
  } catch (e) {
    debugPrint('환경 변수 로드 실패: $e');
    // 환경 변수 로드 실패 처리
    _handleEnvironmentLoadFailure();
  }
  
  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase 초기화 성공');
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
    // 사용자에게 초기화 오류 알림 표시 로직을 추가할 수 있음
  }
  
  // Dependency Injection 초기화
  await DependencyInjection.init();
  
  // 설정 로드
  final prefs = await SharedPreferences.getInstance();
  
  // 만료된 데이터 정리 (웹 환경에서만)
  if (kIsWeb) {
    try {
      final webUtils = WebUtils.instance;
      webUtils.cleanupExpiredFiles();
    } catch (e) {
      debugPrint('만료된 데이터 정리 중 오류: $e');
    }
  }
  
  runApp(const MyApp());
}

/// 민감하지 않은 환경 변수만 로깅
void _logSafeEnvironmentVariables() {
  if (kDebugMode) {
    // API 키와 같은 민감한 정보는 로깅하지 않음
    debugPrint('Firebase Project ID: ${dotenv.env['FIREBASE_PROJECT_ID']}');
    debugPrint('환경: ${dotenv.env['ENVIRONMENT']}');
    debugPrint('앱 버전: ${dotenv.env['APP_VERSION']}');
    debugPrint('최대 PDF 페이지 수: ${dotenv.env['MAX_PDF_PAGES']}');
    debugPrint('최대 PDF 파일 크기: ${dotenv.env['MAX_PDF_FILE_SIZE']}');
    // API 키 로깅 제거
  }
}

/// 환경 변수 로드 실패 처리
void _handleEnvironmentLoadFailure() {
  // 실제 API 키를 하드코딩하지 않고 더미 값 또는 빈 값으로 설정
  dotenv.env['ENVIRONMENT'] = 'development';
  dotenv.env['MAX_PDF_FILE_SIZE'] = '50'; // 제한적 기능으로 설정
  dotenv.env['MAX_PDF_PAGES'] = '100'; // 제한적 기능으로 설정
  dotenv.env['APP_VERSION'] = '1.0.0';
  dotenv.env['PREMIUM_FEATURES_ENABLED'] = 'false'; // 기본 기능만 활성화
  
  // Firebase 관련 설정은 config/firebase_options.dart에서 가져오므로 여기서 설정하지 않음
  
  // API 키 관련 필드는 빈 값으로 설정하고 앱 내에서 적절히 처리
  debugPrint('환경 변수 로드 실패: 제한된 기능으로 앱을 실행합니다.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => getIt<ThemeViewModel>(),
        ),
        ChangeNotifierProvider<LocaleViewModel>(
          create: (_) => getIt<LocaleViewModel>(),
        ),
        ChangeNotifierProvider<PDFViewModel>(
          create: (_) => getIt<PDFViewModel>(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => getIt<AuthViewModel>(),
        ),
      ],
      child: Consumer2<ThemeViewModel, LocaleViewModel>(
        builder: (context, themeViewModel, localeViewModel, child) {
          return MaterialApp(
            title: 'PDF Learner',
            debugShowCheckedModeBanner: false,
            themeMode: themeViewModel.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: localeViewModel.locale,
            supportedLocales: localeViewModel.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const InitialPage(), // 초기 페이지 또는 스플래시 화면
          );
        },
      ),
    );
  }
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      // API 키 검증 - 환경 변수가 제대로 로드되었는지 확인
      bool hasRequiredEnvVars = _checkRequiredEnvironmentVariables();
      if (!hasRequiredEnvVars) {
        setState(() {
          _errorMessage = '필수 환경 변수가 설정되지 않았습니다. 일부 기능이 제한될 수 있습니다.';
          _isLoading = false;
        });
        return;
      }
      
      // PDF 뷰모델에서 초기 데이터 로드
      final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
      await pdfViewModel.loadDocuments();
    } catch (e) {
      debugPrint('초기 데이터 로드 중 오류: $e');
      setState(() {
        _errorMessage = '데이터 로드 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 필수 환경 변수가 설정되었는지 확인
  bool _checkRequiredEnvironmentVariables() {
    // 앱의 핵심 기능에 필요한 환경 변수 확인
    // 실제 키 값을 확인하지 않고 키가 존재하는지만 확인
    final requiredKeys = [
      'ENVIRONMENT',
      'APP_VERSION',
      'MAX_PDF_FILE_SIZE',
      'MAX_PDF_PAGES'
    ];
    
    for (var key in requiredKeys) {
      if (dotenv.env[key]?.isEmpty ?? true) {
        debugPrint('필수 환경 변수 누락: $key');
        return false;
      }
    }
    
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 여기서 홈 화면 또는 로그인 화면으로 이동
    return const HomeScreen();
  }
}