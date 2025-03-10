import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_key_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isApiKeyValid = true;
  String _apiKeyErrorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _isApiKeyValid = true;
        _apiKeyErrorMessage = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiKeyService = ApiKeyService();
      final isValid = await apiKeyService.validateAPIKey(_apiKeyController.text.trim());
      
      setState(() {
        _isApiKeyValid = isValid;
        _apiKeyErrorMessage = isValid ? '' : '유효하지 않은 API 키입니다.';
      });
    } catch (e) {
      setState(() {
        _isApiKeyValid = false;
        _apiKeyErrorMessage = '검증 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showApiKeyTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 설정 튜토리얼'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Google AI Studio 접속하기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _launchUrl('https://makersuite.google.com/app/apikey'),
                child: const Text(
                  'https://makersuite.google.com/app/apikey',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '2. Google 계정으로 로그인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Google 계정이 필요합니다. 없다면 새로 만드세요.'),
              const SizedBox(height: 12),
              
              const Text(
                '3. API 키 생성하기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('로그인 후 "Create API key" 버튼을 클릭하여 새 API 키를 생성하세요.'),
              Image.network(
                'https://storage.googleapis.com/pdf-learner.appspot.com/tutorial/gemini_api_key_create.png',
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text('이미지를 불러올 수 없습니다.'),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '4. API 키 복사하기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('생성된 API 키를 복사하여 여기에 붙여넣으세요.'),
              Image.network(
                'https://storage.googleapis.com/pdf-learner.appspot.com/tutorial/gemini_api_key_copy.png',
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text('이미지를 불러올 수 없습니다.'),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '5. 테스트용 API 키',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('테스트를 위해 다음 API 키를 사용할 수 있습니다:'),
              SelectableText(
                'AIzaSyBAaUaNUqLKupp0Il9OHczUyb5VXDU2EhM',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '참고사항:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• API 키는 선택사항입니다. 입력하지 않아도 기본 기능을 사용할 수 있습니다.\n'
                  '• 자신의 API 키를 사용하면 더 많은 요청을 처리할 수 있습니다.\n'
                  '• API 키는 안전하게 저장되며 귀하의 요청에만 사용됩니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_apiKeyController.text.isNotEmpty && !_isApiKeyValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 API 키입니다. 비워두거나 올바른 API 키를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await context.read<AuthService>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      
      // API 키가 입력되었고 유효하다면 저장
      if (_apiKeyController.text.isNotEmpty && _isApiKeyValid) {
        final apiKeyService = ApiKeyService();
        await apiKeyService.saveAPIKey(user.uid, _apiKeyController.text.trim());
      }
      
      if (mounted) {
        // 회원가입 성공 시 홈 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
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
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API 키 (선택사항)',
                          border: const OutlineInputBorder(),
                          helperText: '자신의 Gemini API 키를 입력하세요',
                          errorText: _isApiKeyValid ? null : _apiKeyErrorMessage,
                          suffixIcon: _apiKeyController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    _isApiKeyValid ? Icons.check_circle : Icons.error,
                                    color: _isApiKeyValid ? Colors.green : Colors.red,
                                  ),
                                  onPressed: _validateApiKey,
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _isApiKeyValid = true;
                              _apiKeyErrorMessage = '';
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'API 키 설정 방법',
                      onPressed: _showApiKeyTutorial,
                    ),
                  ],
                ),
                if (_apiKeyController.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _validateApiKey,
                      child: const Text('API 키 검증하기'),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('회원가입'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('이미 계정이 있으신가요? 로그인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 