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
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/pdf_viewer_page.dart';
import 'presentation/screens/subscription_screen.dart';
import 'core/utils/web_storage_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드 - 다른 초기화보다 먼저 실행
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('환경 변수 로드 성공');
    _logEnvironmentVariables(); // 환경 변수 로깅
  } catch (e) {
    debugPrint('환경 변수 로드 실패: $e');
    // 기본 환경 변수 설정
    await _setupDefaultEnvVariables();
  }
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 의존성 주입 설정
  await DependencyInjection.init();
  
  // 웹 스토리지에서 만료된 데이터 정리
  await _cleanupExpiredData();
  
  runApp(const App());
}

/// 환경 변수 로깅 (디버그 모드에서만)
void _logEnvironmentVariables() {
  if (kDebugMode) {
    debugPrint('PayPal 기본 플랜 ID: ${dotenv.env['PAYPAL_BASIC_PLAN_ID']}');
    debugPrint('PayPal 프리미엄 플랜 ID: ${dotenv.env['PAYPAL_PREMIUM_PLAN_ID']}');
    debugPrint('PayPal 클라이언트 ID: ${dotenv.env['PAYPAL_CLIENT_ID']}');
    debugPrint('PayPal 판매자 ID: ${dotenv.env['PAYPAL_MERCHANT_ID']}');
    debugPrint('환경: ${dotenv.env['ENVIRONMENT']}');
  }
}

/// 기본 환경 변수 설정
Future<void> _setupDefaultEnvVariables() async {
  // 기본값 설정을 위한 임시 메서드
  dotenv.env['PAYPAL_CLIENT_ID'] = 'AY4xA8BL8YVstPdRZRd_6BM6vhoEGu0ei3UUjOpn0EajAI2FG2yALLnjmniYERxr7R1BpZI0aQy3Xi9w';
  dotenv.env['PAYPAL_MERCHANT_ID'] = 'RJWUGHMG9C6FQ'; 
  dotenv.env['PAYPAL_BASIC_PLAN_ID'] = 'P-0C773510SU364272XM7SPX6I';
  dotenv.env['PAYPAL_PREMIUM_PLAN_ID'] = 'P-2EM77373KV537191YM7SPYNY';
}

/// 만료된 데이터 정리
Future<void> _cleanupExpiredData() async {
  try {
    // 웹 스토리지에서 만료된 PDF 데이터 정리
    await WebStorageUtils.removeExpiredData();
  } catch (e) {
    debugPrint('만료 데이터 정리 중 오류: $e');
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // DI 컨테이너에서 필요한 뷰모델들 가져오기
    final themeViewModel = DependencyInjection.instance<ThemeViewModel>();
    final localeViewModel = DependencyInjection.instance<LocaleViewModel>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeViewModel),
        ChangeNotifierProvider.value(value: localeViewModel),
      ],
      child: Consumer2<ThemeViewModel, LocaleViewModel>(
        builder: (context, themeVM, localeVM, _) {
          return MaterialApp(
            title: 'PDF 학습 도우미',
            theme: themeVM.lightTheme,
            darkTheme: themeVM.darkTheme,
            themeMode: themeVM.themeMode,
            locale: localeVM.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/pdf_viewer': (context) => const PdfViewerPage(),
              '/subscription': (context) => const SubscriptionScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}