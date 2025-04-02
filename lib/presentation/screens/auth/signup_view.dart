import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import './gemini_api_tutorial_view.dart';

/// 회원가입 화면
class SignUpView extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;
  final VoidCallback? onNavigateToLogin;
  
  const SignUpView({
    Key? key,
    this.onSignUpSuccess,
    this.onNavigateToLogin,
  }) : super(key: key);
  
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  // 타임스탬프 기반 고유 키 사용
  final _formKey = UniqueKey();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isApiKeyVisible = false;
  bool _showApiKeyField = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _geminiApiKeyController.dispose();
    super.dispose();
  }
  
  /// 회원가입 처리
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final geminiApiKey = _geminiApiKeyController.text.trim();
      
      await authViewModel.signUpWithEmailPassword(
        email, 
        password,
        geminiApiKey: geminiApiKey.isNotEmpty ? geminiApiKey : null,
      );
      
      if (authViewModel.error == null) {
        if (widget.onSignUpSuccess != null) {
          widget.onSignUpSuccess!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authViewModel.error!)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  /// Gemini API 키 튜토리얼 화면으로 이동
  void _navigateToGeminiTutorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeminiApiTutorialView(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 로고 또는 아이콘
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 이메일 입력 필드
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        hintText: 'example@email.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '유효한 이메일 주소를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 비밀번호 입력 필드
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '8자 이상 입력해주세요',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 8) {
                          return '비밀번호는 8자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 비밀번호 확인 입력 필드
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        hintText: '비밀번호를 다시 입력해주세요',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 다시 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gemini API 키 토글
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showApiKeyField = !_showApiKeyField;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showApiKeyField ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gemini API 키 설정 (선택사항)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline),
                              onPressed: _navigateToGeminiTutorial,
                              tooltip: 'API 키 발급 방법 보기',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Gemini API 키 입력 필드 (토글 시 표시)
                    if (_showApiKeyField) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _geminiApiKeyController,
                        decoration: InputDecoration(
                          labelText: 'Gemini API 키',
                          hintText: 'AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6',
                          prefixIcon: const Icon(Icons.vpn_key),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isApiKeyVisible = !_isApiKeyVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: !_isApiKeyVisible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '나중에 설정 메뉴에서도 API 키를 추가하거나 변경할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // 회원가입 버튼
                    ElevatedButton(
                      onPressed: authViewModel.isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authViewModel.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('회원가입'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 로그인 페이지로 이동
                    if (widget.onNavigateToLogin != null)
                      TextButton(
                        onPressed: widget.onNavigateToLogin,
                        child: const Text('이미 계정이 있으신가요? 로그인하기'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 