import 'package:flutter/material.dart';
import 'presentation/screens/login_page.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/signup_page.dart';
import 'presentation/screens/reset_password_page.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/pdf_viewer_page.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String resetPassword = '/reset-password';
  static const String pdfViewer = '/pdf_viewer';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginPage(),
      signup: (context) => const SignUpPage(),
      home: (context) => const HomePage(),
      resetPassword: (context) => const ResetPasswordPage(),
      pdfViewer: (context) => PDFViewerPage.fromArguments(context),
    };
  }
} 