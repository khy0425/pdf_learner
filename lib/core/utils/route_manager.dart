import 'package:flutter/material.dart';
import '../views/screens/loading_screen.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/desktop_home_screen.dart';
import '../views/screens/mobile_home_screen.dart';
import '../views/screens/pdf_viewer_screen.dart';
import '../models/pdf_document.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

/// 라우트 이름 상수
class Routes {
  static const String loading = '/loading';
  static const String login = '/login';
  static const String home = '/home';
  static const String pdfViewer = '/pdf_viewer';
}

/// 라우트 관리자 클래스
class RouteManager {
  // 라우트 생성 함수
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.loading:
        return MaterialPageRoute(
          builder: (_) => const LoadingScreen(),
          settings: settings,
        );
        
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
        
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => _getPlatformSpecificHomeScreen(),
          settings: settings,
        );
        
      case Routes.pdfViewer:
        final args = settings.arguments as Map<String, dynamic>;
        final document = args['document'] as PdfDocument;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(document: document),
          settings: settings,
        );
        
      default:
        // 정의되지 않은 라우트인 경우 오류 화면 표시
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('정의되지 않은 라우트: ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }

  // 플랫폼별 홈 화면 반환
  static Widget _getPlatformSpecificHomeScreen() {
    // 웹 환경인 경우
    if (kIsWeb) {
      // 화면 크기에 따라 데스크톱/모바일 화면 선택
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return const DesktopHomeScreen();
          } else {
            return const MobileHomeScreen();
          }
        },
      );
    }
    // 모바일 환경인 경우
    else if (Platform.isAndroid || Platform.isIOS) {
      return const MobileHomeScreen();
    }
    // 데스크톱 환경인 경우
    else {
      return const DesktopHomeScreen();
    }
  }
  
  // 로딩 화면으로 이동
  static void navigateToLoading(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.loading,
      (route) => false,
    );
  }
  
  // 로그인 화면으로 이동
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.login,
      (route) => false,
    );
  }
  
  // 홈 화면으로 이동
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.home,
      (route) => false,
    );
  }
  
  // PDF 뷰어 화면으로 이동
  static void navigateToPdfViewer(BuildContext context, PdfDocument document) {
    Navigator.pushNamed(
      context,
      Routes.pdfViewer,
      arguments: {'document': document},
    );
  }
} 