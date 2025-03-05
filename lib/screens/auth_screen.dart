import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_service.dart';
import '../services/api_key_service.dart';
import '../services/anonymous_user_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool initialSignUp;
  
  const AuthScreen({Key? key, this.initialSignUp = false}) : super(key: key);
  
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  late bool _isSignUp;
  final _apiKeyService = ApiKeyService();
  final _anonymousUserService = AnonymousUserService();
  int _remainingFreeUsage = 0;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    _loadRemainingUsage();
  }
  
  Future<void> _loadRemainingUsage() async {
    _remainingFreeUsage = await _anonymousUserService.getRemainingFreeUsage();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSignUp ? '회원가입' : '로그인',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (!_isSignUp) ...[
                    Text(
                      '남은 무료 사용 횟수: $_remainingFreeUsage회',
                      style: TextStyle(
                        color: _remainingFreeUsage > 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
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
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API 키 (선택사항)',
                        border: OutlineInputBorder(),
                        helperText: '무료 요금제를 계속 사용하려면 API 키를 입력하세요',
                        helperMaxLines: 2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: Text(_isSignUp ? '가입하기' : '로그인'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(_isSignUp ? '이미 계정이 있나요?' : '계정 만들기'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.red,
                    ),
                    label: const Text('Google로 로그인'),
                    onPressed: _handleGoogleSignIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    try {
      final authService = context.read<AuthService>();
      if (_isSignUp) {
        // API 키 유효성 검사 (입력된 경우)
        final apiKey = _apiKeyController.text.trim();
        if (apiKey.isNotEmpty && !_apiKeyService.isValidApiKey(apiKey)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 API 키입니다.')),
          );
          return;
        }
        
        // 회원가입
        await authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
        );
        
        // API 키 저장 (입력된 경우)
        if (apiKey.isNotEmpty) {
          await _apiKeyService.saveUserApiKey(apiKey);
        }
        
        // 무료 사용 횟수 초기화
        await _anonymousUserService.resetUsage();
      } else {
        await authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      // 화면 전환은 main.dart에서 처리됨
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      
      // 무료 사용 횟수 초기화
      await _anonymousUserService.resetUsage();
      
      // 화면 전환은 main.dart에서 처리됨
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
} 