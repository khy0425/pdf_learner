import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'terms_page.dart';
import '../dialogs/password_security_dialog.dart';

/// 회원가입 페이지
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // 인증된 상태이면 홈 페이지로 이동
          if (authViewModel.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
          }
          
          // 에러 상태이면 스낵바 표시
          if (authViewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(authViewModel.error ?? '오류가 발생했습니다'),
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
              // 에러 메시지를 표시한 후 상태 초기화
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
                          onPressed: () => Navigator.pop(context),
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
                          '회원가입',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5FEF),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'PDF 학습기의 모든 기능을 이용하기 위해 계정을 만들어보세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 회원가입 폼
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 이름 입력 필드
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: '이름',
                                  hintText: '실명 또는 닉네임을 입력하세요',
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
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
                                style: const TextStyle(fontSize: 16),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // 이메일 입력 필드
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
                                style: const TextStyle(fontSize: 16),
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
                                  hintText: '6자 이상 입력하세요',
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
                                style: const TextStyle(fontSize: 16),
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
                              
                              const SizedBox(height: 16),
                              
                              // 비밀번호 확인 입력 필드
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: '비밀번호 확인',
                                  hintText: '비밀번호를 다시 입력하세요',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
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
                                style: const TextStyle(fontSize: 16),
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
                              
                              const SizedBox(height: 16),
                              
                              // 이용약관 동의
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF5D5FEF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const Text(
                                    '이용약관 및 개인정보 처리방침에 동의합니다',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // 이용약관 및 개인정보처리방침 페이지로 이동
                                      _showTermsDialog(context);
                                    },
                                    child: const Text(
                                      '보기',
                                      style: TextStyle(
                                        color: Color(0xFF5D5FEF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // 회원가입 버튼
                              ElevatedButton(
                                onPressed: authViewModel.isLoading || !_acceptTerms
                                    ? null
                                    : () => _onSignUpPressed(authViewModel),
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
                                            '회원가입',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 로그인 링크
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '이미 계정이 있으신가요?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                '로그인',
                                style: TextStyle(
                                  color: Color(0xFF5D5FEF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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

  void _onSignUpPressed(AuthViewModel authViewModel) {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이용약관에 동의해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      authViewModel.signUpWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    }
  }
  
  /// 이용약관 및 개인정보처리방침 선택 다이얼로그
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('약관 선택'),
        content: const Text('확인하실 약관을 선택해주세요.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPage(isPrivacyPolicy: false),
                ),
              );
            },
            child: const Text('이용약관'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPage(isPrivacyPolicy: true),
                ),
              );
            },
            child: const Text('개인정보 처리방침'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
} 