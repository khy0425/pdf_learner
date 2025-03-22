import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

// 아직 다국어 지원 파일이 생성되지 않았으므로 주석 처리
// import 'l10n/app_localizations.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/theme_view_model.dart';
import 'view_models/settings_view_model.dart';
import 'views/screens/loading_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/desktop_home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다국어 지원과 테마 설정을 적용한 MultiProvider 패턴
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: Consumer2<ThemeViewModel, SettingsViewModel>(
        builder: (context, themeVM, settingsVM, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PDF Learner',
            
            // 다국어 지원 설정 (아직 생성되지 않았으므로 주석 처리)
            localizationsDelegates: const [
              // AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // 영어
              Locale('ko'), // 한국어
            ],
            locale: settingsVM.locale,
            
            // 테마 설정
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            
            // 반응형 UI 설정
            builder: (context, child) {
              return ResponsiveWrapper.builder(
                child!,
                maxWidth: 1200,
                minWidth: 480,
                defaultScale: true,
                breakpoints: [
                  ResponsiveBreakpoint.autoScale(480, name: MOBILE),
                  ResponsiveBreakpoint.autoScale(800, name: TABLET),
                  ResponsiveBreakpoint.autoScale(1000, name: DESKTOP),
                ],
              );
            },
            
            // 인증 상태에 따른 화면 전환 로직
            home: const LoadingScreen(),
          );
        },
      ),
    );
  }
} 