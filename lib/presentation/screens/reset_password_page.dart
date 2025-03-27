import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

/// 비밀번호 재설정 페이지
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 재설정'),
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // 인증된 상태이면 이전 페이지로 이동
          if (authViewModel.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
          }
          
          // 에러 상태이면 스낵바 표시
          if (authViewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authViewModel.error ?? '오류가 발생했습니다')),
              );
              // 에러 메시지를 표시한 후 상태 초기화
              authViewModel.clearError();
            });
          }
          
          // 로딩 상태이면 로딩 인디케이터 표시
          if (authViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 비밀번호 재설정 폼
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.',
                    style: TextStyle(
                      fontSize: 16.0,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요.';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () => _onResetPasswordPressed(authViewModel),
                    child: const Text('비밀번호 재설정 링크 보내기'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onResetPasswordPressed(AuthViewModel authViewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      await authViewModel.sendPasswordResetEmail(_emailController.text);
      
      if (!authViewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호 재설정 링크가 이메일로 전송되었습니다.'),
          ),
        );
        
        // 오류가 없으면 이전 페이지로 이동
        Navigator.pop(context);
      }
    }
  }
} 