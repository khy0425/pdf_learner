import 'package:flutter/material.dart';
import 'mobile_home_screen.dart';
import 'desktop_home_screen.dart';

/// 반응형 홈 스크린
/// 
/// 화면 크기에 따라 모바일/데스크톱 버전을 선택하여 표시합니다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 너비에 따라 모바일/데스크톱 버전 선택
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const MobileHomeScreen();
        } else {
          return const DesktopHomeScreen();
        }
      },
    );
  }
} 