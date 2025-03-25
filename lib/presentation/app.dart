import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/pdf_viewmodel.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/signup_page.dart';
import 'pages/reset_password_page.dart';
import 'screens/splash_screen.dart';

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
          create: (_) => GetIt.I<PDFViewModel>(),
        ),
      ],
      child: MaterialApp(
        title: 'PDF Learner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D5FEF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/signup': (context) => const SignUpPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
        },
      ),
    );
  }
} 