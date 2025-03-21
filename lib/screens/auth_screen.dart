import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_key_service.dart';
import '../providers/pdf_provider.dart';
import '../models/user_model.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 로그인된 경우 사용자 정보 표시
        if (authService.isLoggedIn) {
          final user = authService.user!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (user.photoURL != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.photoURL!),
                        radius: 20,
                      )
                    else
                      const CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 20,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => authService.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('로그아웃'),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: Text('구독 상태: ${user.subscriptionTier}'),
                  subtitle: const Text('구독을 업그레이드하여 더 많은 기능을 사용해보세요'),
                  trailing: TextButton(
                    onPressed: () {
                      // TODO: 구독 관리 페이지로 이동
                    },
                    child: const Text('구독 관리'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('API 키 관리'),
                  subtitle: Text(user.apiKey != null ? '설정됨' : '설정되지 않음'),
                  trailing: TextButton(
                    onPressed: () {
                      // TODO: API 키 관리 페이지로 이동
                    },
                    child: const Text('API 키 설정'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('계정 설정'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 계정 설정 페이지로 이동
                  },
                ),
              ],
            ),
          );
        }

        // 로그인되지 않은 경우 로그인 폼 표시
        return const LoginForm();
      },
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _handleAuth(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용 약관에 동의해주세요.')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    
    if (_isSignUp) {
      await authService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
        _displayNameController.text,
      );
    } else {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (authService.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.error!)),
        );
      }
    }
  }

  void _handleGoogleSignIn(BuildContext context) async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용 약관에 동의해주세요.')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    await authService.signInWithGoogle();

    if (authService.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authService.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSignUp ? '회원가입' : '로그인',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요.';
                }
                if (_isSignUp && value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다.';
                }
                return null;
              },
            ),
            if (_isSignUp) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agreeToTerms,
              onChanged: (value) => setState(() => _agreeToTerms = value!),
              title: const Text('이용 약관에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleAuth(context),
              child: Text(_isSignUp ? '회원가입' : '로그인'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _handleGoogleSignIn(context),
              child: const Text('Google로 계속하기'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
} 