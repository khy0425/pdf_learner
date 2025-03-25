import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
        }
        
        if (authViewModel.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? '오류가 발생했습니다')),
            );
            // 에러 메시지를 표시한 후 상태 초기화
            authViewModel.clearError();
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('로그인'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: authViewModel.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        
                        if (email.isNotEmpty && password.isNotEmpty) {
                          authViewModel.signInWithEmailAndPassword(email, password);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')),
                          );
                        }
                      },
                      child: const Text('로그인'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                      child: const Text('계정이 없으신가요? 회원가입'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/reset-password');
                      },
                      child: const Text('비밀번호를 잊으셨나요?'),
                    ),
                    const Divider(height: 32),
                    // TODO: Google 로그인 버튼
                    /*
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Google로 로그인'),
                      onPressed: () {
                        // Google 로그인 기능 구현 예정
                      },
                    ),
                    */
                  ],
                ),
          ),
        );
      },
    );
  }
} 