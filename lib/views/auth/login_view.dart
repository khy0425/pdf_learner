import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true: 로그인, false: 회원가입
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 및 타이틀
                _buildHeader(context),
                
                const SizedBox(height: 32),
                
                // 이메일 입력
                _buildEmailField(),
                
                const SizedBox(height: 16),
                
                // 비밀번호 입력
                _buildPasswordField(),
                
                const SizedBox(height: 8),
                
                // 오류 메시지
                _buildErrorMessage(authViewModel),
                
                const SizedBox(height: 16),
                
                // 로그인/회원가입 버튼
                _buildSubmitButton(authViewModel),
                
                const SizedBox(height: 16),
                
                // 모드 전환 버튼
                _buildToggleModeButton(authViewModel),
                
                // 구분선
                _buildDivider(),
                
                const SizedBox(height: 16),
                
                // 소셜 로그인 버튼
                _buildGoogleSignInButton(authViewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_stories,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'PDF 학습 도우미 로그인' : 'PDF 학습 도우미 회원가입',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin 
            ? '계정에 로그인하여 PDF 학습을 시작하세요'
            : '새 계정을 만들어 PDF 학습을 시작하세요',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: '이메일',
        hintText: 'example@email.com',
        prefixIcon: const Icon(Icons.email),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력해주세요';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return '유효한 이메일 주소를 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: '비밀번호',
        hintText: '6자 이상 입력해주세요',
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
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요';
        }
        if (value.length < 6) {
          return '비밀번호는 6자 이상이어야 합니다';
        }
        return null;
      },
    );
  }

  Widget _buildErrorMessage(AuthViewModel authViewModel) {
    if (_errorMessage == null && authViewModel.error == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? authViewModel.error ?? '',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthViewModel authViewModel) {
    final isLoading = authViewModel.isLoading || _isSubmitting;
    
    return ElevatedButton(
      onPressed: isLoading ? null : () => _handleAuth(authViewModel),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(_isLogin ? '로그인' : '회원가입', style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildToggleModeButton(AuthViewModel authViewModel) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          _errorMessage = null;
          // 오류 메시지 초기화
          if (authViewModel.error != null) {
            authViewModel.clearError();
          }
        });
      },
      child: Text(_isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('또는'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton(AuthViewModel authViewModel) {
    final isLoading = authViewModel.isLoading || _isSubmitting;
    
    return OutlinedButton.icon(
      onPressed: isLoading ? null : () => _handleGoogleSignIn(authViewModel),
      icon: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        width: 24,
        height: 24,
      ),
      label: const Text('Google로 계속하기'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  void _handleAuth(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 키보드 숨기기
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      if (_isLogin) {
        await authViewModel.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authViewModel.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      // 성공 시 비밀번호 필드 초기화
      _passwordController.clear();
      
      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? '로그인 성공!' : '회원가입 성공!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleGoogleSignIn(AuthViewModel authViewModel) async {
    // 키보드 숨기기
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      await authViewModel.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
} 