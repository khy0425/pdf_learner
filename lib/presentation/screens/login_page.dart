import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dart:math' as Math;
import 'home_page.dart';

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    
    // 이미 로그인된 사용자가 있는지 확인
    final currentUser = context.read<AuthService>().currentUser;
    
    // 로그인된 사용자가 있다면 홈페이지로 이동
    if (currentUser != null && currentUser.uid.isNotEmpty && currentUser.uid != 'guest') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    
    // 이미 로그인된 경우 홈 화면으로 이동
    if (currentUser != null && currentUser.uid.isNotEmpty && currentUser.uid != 'guest') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 및 앱 이름
                  Column(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PDF 학습노트',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUpMode ? '회원가입하고 시작하기' : '로그인하고 시작하기',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 이메일 입력 필드
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (_isSignUpMode && value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 로그인/회원가입 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUpMode ? '회원가입' : '로그인'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 소셜 로그인 버튼
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Google로 계속하기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 로그인/회원가입 전환 버튼
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isSignUpMode = !_isSignUpMode;
                            });
                          },
                    child: Text(
                      _isSignUpMode
                          ? '이미 계정이 있으신가요? 로그인하기'
                          : '계정이 없으신가요? 회원가입하기',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 게스트 모드로 시작 버튼
                  TextButton(
                    onPressed: _isLoading ? null : _continueAsGuest,
                    child: const Text('게스트 모드로 시작하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// 폼 제출 처리 (로그인 또는 회원가입)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool success = false;
    
    try {
      if (_isSignUpMode) {
        final user = await authService.signUpWithEmail(email, password);
        success = user != null;
      } else {
        final user = await authService.signInWithEmail(email, password);
        success = user != null;
      }
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showErrorDialog('로그인 실패', '이메일 또는 비밀번호를 확인해주세요.');
      }
    } catch (e) {
      _showErrorDialog('오류 발생', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Google 로그인 처리
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = context.read<AuthService>();
      final user = await authService.signInWithGoogle();
      
      if (user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showErrorDialog('로그인 실패', 'Google 로그인에 실패했습니다.');
      }
    } catch (e) {
      _showErrorDialog('오류 발생', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 게스트 모드로 계속하기
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInAsGuest();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      _showErrorDialog('오류 발생', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// Google 로고를 그리는 CustomPainter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // 색상 정의
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);
    
    // 가운데 정렬을 위한 조정
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double iconSize = Math.min(width, height);
    
    // 스케일 조정
    canvas.save();
    canvas.translate(centerX - iconSize/2, centerY - iconSize/2);
    
    // G 로고 그리기 (SVG 경로에 기반한 단순화된 버전)
    final Path gPath = Path();
    
    // 빨간색 부분
    gPath.moveTo(iconSize * 0.5, iconSize * 0.2);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.2, iconSize * 0.2, iconSize * 0.6, iconSize * 0.6),
      -Math.pi / 2,
      Math.pi / 2,
      false
    );
    gPath.lineTo(iconSize * 0.8, iconSize * 0.5);
    gPath.lineTo(iconSize * 0.65, iconSize * 0.65);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.3, iconSize * 0.3, iconSize * 0.4, iconSize * 0.4),
      Math.pi / 4,
      -3 * Math.pi / 4,
      false
    );
    gPath.close();
    canvas.drawPath(gPath, redPaint);
    
    // 파란색 부분
    gPath.reset();
    gPath.moveTo(iconSize * 0.8, iconSize * 0.5);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.2, iconSize * 0.2, iconSize * 0.6, iconSize * 0.6),
      0,
      Math.pi / 2,
      false
    );
    gPath.lineTo(iconSize * 0.65, iconSize * 0.65);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.3, iconSize * 0.3, iconSize * 0.4, iconSize * 0.4),
      Math.pi / 4,
      -Math.pi / 4,
      false
    );
    gPath.close();
    canvas.drawPath(gPath, bluePaint);
    
    // 노란색 부분
    gPath.reset();
    gPath.moveTo(iconSize * 0.2, iconSize * 0.5);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.2, iconSize * 0.2, iconSize * 0.6, iconSize * 0.6),
      Math.pi,
      Math.pi / 2,
      false
    );
    gPath.lineTo(iconSize * 0.35, iconSize * 0.65);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.3, iconSize * 0.3, iconSize * 0.4, iconSize * 0.4),
      3 * Math.pi / 4,
      -Math.pi / 4,
      false
    );
    gPath.close();
    canvas.drawPath(gPath, yellowPaint);
    
    // 초록색 부분
    gPath.reset();
    gPath.moveTo(iconSize * 0.5, iconSize * 0.8);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.2, iconSize * 0.2, iconSize * 0.6, iconSize * 0.6),
      Math.pi / 2,
      Math.pi / 2,
      false
    );
    gPath.lineTo(iconSize * 0.35, iconSize * 0.65);
    gPath.lineTo(iconSize * 0.65, iconSize * 0.65);
    gPath.arcTo(
      Rect.fromLTWH(iconSize * 0.3, iconSize * 0.3, iconSize * 0.4, iconSize * 0.4),
      -3 * Math.pi / 4,
      Math.pi / 2,
      false
    );
    gPath.close();
    canvas.drawPath(gPath, greenPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 