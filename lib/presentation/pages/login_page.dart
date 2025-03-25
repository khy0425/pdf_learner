import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../dialogs/password_security_dialog.dart';

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          if (authViewModel.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
          }
          
          if (authViewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(authViewModel.error ?? '인증 오류가 발생했습니다'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              authViewModel.clearError();
            });
          }

          return Stack(
            children: [
              // 배경 그라데이션
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      const Color(0xFFF5F7FA),
                    ],
                  ),
                ),
              ),
              
              // 메인 콘텐츠
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 뒤로가기 버튼
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 앱 로고 및 헤더
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5D5FEF),
                                  Color(0xFF3D6AFF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5D5FEF).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 헤더 텍스트
                        const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5FEF),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'PDF 학습기에 오신 것을 환영합니다. 계정에 로그인해주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 이메일 필드
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: '이메일',
                                  hintText: 'example@email.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
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
                              const SizedBox(height: 16.0),
                              
                              // 비밀번호 필드
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: '비밀번호',
                                  hintText: '비밀번호를 입력하세요',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _isPasswordVisible 
                                              ? Icons.visibility_rounded 
                                              : Icons.visibility_off_rounded,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Color(0xFF5D5FEF),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => const PasswordSecurityDialog(),
                                          );
                                        },
                                        tooltip: '비밀번호 암호화 관리',
                                      ),
                                    ],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '비밀번호를 입력해주세요';
                                  }
                                  if (value.length < 6) {
                                    return '비밀번호는 6자 이상이어야 합니다';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8.0),
                              
                              // 비밀번호 찾기 링크
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/reset-password');
                                  },
                                  child: const Text(
                                    '비밀번호 찾기',
                                    style: TextStyle(
                                      color: Color(0xFF5D5FEF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              
                              // 로그인 버튼
                              ElevatedButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          authViewModel.signInWithEmailAndPassword(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF5D5FEF),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                ),
                                child: authViewModel.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Ink(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF5D5FEF),
                                              Color(0xFF3D6AFF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.all(Radius.circular(12)),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '로그인',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16.0),
                              
                              // 구분선
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      '또는',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              
                              // 구글 로그인 버튼
                              OutlinedButton.icon(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () {
                                        authViewModel.signInWithGoogle();
                                      },
                                icon: const Icon(Icons.g_mobiledata, size: 24),
                                label: const Text('Google로 로그인'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: const Color(0xFF5D5FEF).withOpacity(0.5)),
                                  foregroundColor: Colors.grey.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              
                              // 회원가입 링크
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '계정이 없으신가요?',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/signup');
                                    },
                                    child: const Text(
                                      '회원가입',
                                      style: TextStyle(
                                        color: Color(0xFF5D5FEF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // 익명 로그인 (게스트 모드) 버튼
                              TextButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () {
                                        authViewModel.signInAnonymously();
                                      },
                                child: Text(
                                  '게스트 모드로 계속하기',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 로딩 오버레이
              if (authViewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 