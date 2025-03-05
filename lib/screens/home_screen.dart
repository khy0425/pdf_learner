import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_service.dart';
import '../providers/tutorial_provider.dart';
import 'auth_screen.dart';
import 'home_page.dart';
import '../widgets/tutorial_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 튜토리얼 상태는 이미 TutorialProvider 생성자에서 로드됨
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final tutorialProvider = Provider.of<TutorialProvider>(context);
    
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('PDF Learner'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                  // 로그아웃 후 로그인 화면으로 이동
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => AuthScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          body: const HomePage(),
        ),
        // 튜토리얼 오버레이
        if (tutorialProvider.isFirstTime)
          TutorialOverlay(
            onFinish: () {
              tutorialProvider.completeTutorial();
            },
          ),
      ],
    );
  }
} 