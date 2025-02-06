import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APISettingsScreen extends StatefulWidget {
  @override
  State<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends State<APISettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _currentApiKey;
  bool _isEnvKeyUsed = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentApiKey();
  }

  Future<void> _loadCurrentApiKey() async {
    final envApiKey = dotenv.env['GEMINI_API_KEY'];
    if (envApiKey?.isNotEmpty ?? false) {
      setState(() {
        _currentApiKey = envApiKey;
        _apiKeyController.text = envApiKey!;
        _isEnvKeyUsed = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentApiKey = prefs.getString('user_api_key');
      if (_currentApiKey != null) {
        _apiKeyController.text = _currentApiKey!;
      }
    });
  }

  Future<void> _saveApiKey() async {
    setState(() => _isLoading = true);
    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        throw Exception('API 키를 입력해주세요');
      }

      // API 키 유효성 검사
      final isValid = await _validateApiKey(apiKey);
      if (!isValid) {
        throw Exception('유효하지 않은 API 키입니다');
      }

      // API 키 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_api_key', apiKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 저장되었습니다')),
        );
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

  Future<bool> _validateApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Hello',
            }]
          }],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _showApiGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 발급 방법'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Google AI Studio 방문',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('https://makersuite.google.com/app/apikey로 이동'),
              const SizedBox(height: 16),
              Text(
                '2. 구글 계정으로 로그인',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('구글 계정이 필요합니다'),
              const SizedBox(height: 16),
              Text(
                '3. API 키 생성',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('새 API 키 생성 버튼을 클릭하여 키를 발급받습니다'),
              const SizedBox(height: 16),
              Text(
                '4. API 키 복사',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('발급받은 API 키를 복사하여 앱에 입력합니다'),
              const SizedBox(height: 16),
              const Text('* API 키는 안전하게 보관해주세요'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://makersuite.google.com/app/apikey'),
            ),
            child: const Text('사이트 방문'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API 키 상태 카드
            if (_currentApiKey != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(_isEnvKeyUsed ? 'API 키 설정됨 (환경 변수)' : 'API 키 설정됨'),
                  subtitle: Text(_currentApiKey!.substring(0, 10) + '...'),
                  trailing: _isEnvKeyUsed ? null : IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('API 키 삭제'),
                          content: const Text('저장된 API 키를 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('user_api_key');
                        _apiKeyController.clear();
                        setState(() => _currentApiKey = null);
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),
            
            // API 키 입력 카드 (환경 변수 API 키가 없을 때만 표시)
            if (!_isEnvKeyUsed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API 키 설정',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Gemini API 키',
                          hintText: '직접 API 키 입력 또는 프리미엄 구독 사용',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            FilledButton.icon(
                              onPressed: _saveApiKey,
                              icon: const Icon(Icons.save),
                              label: const Text('저장'),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _showApiGuide(context),
                            icon: const Icon(Icons.help_outline),
                            label: const Text('API 키 발급 방법'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            
            // 프리미엄 구독 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '프리미엄 구독',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('프리미엄 구독 시 API 키 설정 없이 모든 기능 사용 가능'),
                    const SizedBox(height: 8),
                    const Text('• 무제한 AI 기능 사용'),
                    const Text('• API 키 설정 불필요'),
                    const Text('• 고급 기능 제공'),
                    const Text('• 광고 제거'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/subscription'),
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('구독 시작하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 