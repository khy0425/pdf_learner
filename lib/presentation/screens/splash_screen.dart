import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 초기화 후 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _checkAuthState(authViewModel);
    });
  }

  void _checkAuthState(AuthViewModel authViewModel) {
    // 인증 상태에 따라 페이지 이동
    if (authViewModel.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (authViewModel.isUnauthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (authViewModel.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.error ?? '인증 오류가 발생했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // 상태가 변경되면 다시 확인
        if (authViewModel.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
        } else if (authViewModel.isUnauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        } else if (authViewModel.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? '인증 오류가 발생했습니다')),
            );
          });
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
} 