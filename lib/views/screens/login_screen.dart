import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    setState(() => _errorMessage = null);

    try {
      bool success;
      if (_isLoginMode) {
        success = await authViewModel.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authViewModel.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _emailController.text.split('@').first, // 임시 이름 (이메일 아이디 부분)
        );
      }
      
      if (!success && mounted) {
        setState(() => _errorMessage = authViewModel.errorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    setState(() => _errorMessage = null);

    try {
      final success = await authViewModel.signInWithGoogle();
      if (!success && mounted) {
        setState(() => _errorMessage = authViewModel.errorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isLoading = authViewModel.isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 로고 이미지
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.menu_book,
                          size: 100,
                          color: Colors.blue,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // 앱 이름
                    const Text(
                      'PDF Learner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 제목
                    Text(
                      _isLoginMode ? '로그인' : '회원가입',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 이메일 입력 필드
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
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
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (!_isLoginMode && value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // 로그인/회원가입 버튼
                    ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isLoginMode ? '로그인' : '회원가입'),
                    ),
                    const SizedBox(height: 16),
                    
                    // 구글 로그인 버튼
                    OutlinedButton.icon(
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.g_mobiledata);
                        },
                      ),
                      label: const Text('Google로 계속하기'),
                      onPressed: isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 에러 메시지
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // 로그인/회원가입 모드 전환 버튼
                    TextButton(
                      onPressed: isLoading ? null : _toggleLoginMode,
                      child: Text(
                        _isLoginMode
                            ? '계정이 없으신가요? 회원가입하기'
                            : '이미 계정이 있으신가요? 로그인하기',
                      ),
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