import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/di/dependency_injection.dart';
import '../core/localization/app_localizations.dart';
import '../domain/repositories/pdf_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/pdf_viewmodel.dart';
import 'viewmodels/locale_viewmodel.dart';
import 'viewmodels/pdf_file_viewmodel.dart';
import '../services/pdf/pdf_service.dart';
import '../data/datasources/pdf_local_datasource.dart';
import '../routes.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/signup_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/splash_screen.dart';
import 'screens/pdf_viewer_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => GetIt.I<AuthViewModel>(),
        ),
        ChangeNotifierProvider<PDFViewModel>(
          create: (context) {
            final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
            final pdfViewModel = GetIt.I<PDFViewModel>();
            
            pdfViewModel.setGuestUser(!authViewModel.isLoggedIn);
            
            return pdfViewModel;
          },
        ),
        ChangeNotifierProvider<LocaleViewModel>(
          create: (_) => GetIt.I<LocaleViewModel>(),
        ),
        Provider<PDFRepository>(
          create: (_) => GetIt.I<PDFRepository>(),
        ),
        ChangeNotifierProvider<PdfFileViewModel>(
          create: (_) => GetIt.I<PdfFileViewModel>(),
        ),
        Provider<PDFService>(
          create: (_) => GetIt.I<PDFService>(),
        ),
        Provider<PDFLocalDataSource>(
          create: (_) => GetIt.I<PDFLocalDataSource>(),
        ),
      ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeViewModel, _) {
          return MaterialApp(
            title: 'PDF 학습 도우미',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeViewModel.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            home: const SplashScreen(),
            routes: Routes.getRoutes(),
          );
        },
      ),
    );
  }
} 