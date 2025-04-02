import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gemini API 키 입력 화면
class GeminiApiKeyView extends StatefulWidget {
  final String? initialApiKey;
  final Function(String) onApiKeySaved;
  final VoidCallback? onSkip;
  
  const GeminiApiKeyView({
    Key? key,
    this.initialApiKey,
    required this.onApiKeySaved,
    this.onSkip,
  }) : super(key: key);
  
  @override
  State<GeminiApiKeyView> createState() => _GeminiApiKeyViewState();
}

class _GeminiApiKeyViewState extends State<GeminiApiKeyView> {
  // 타임스탬프 기반 고유 키 사용
  final _formKey = UniqueKey();
  final _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialApiKey != null) {
      _apiKeyController.text = widget.initialApiKey!;
    }
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
  
  /// Gemini API 키 저장
  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final apiKey = _apiKeyController.text.trim();
      widget.onApiKeySaved(apiKey);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 키 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  /// Gemini API 키 발급 페이지 열기
  Future<void> _openGeminiApiPage() async {
    final Uri url = Uri.parse('https://ai.google.dev/tutorials/setup');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL을 열 수 없습니다')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    // 로그인 상태 확인
    final bool isLoggedIn = authViewModel.isLoggedIn;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API 키 설정'),
        actions: [
          if (widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('건너뛰기'),
            ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 이미지
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
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
                        Icons.api,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 제목
                  Text(
                    'Gemini API 키 설정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 비로그인 상태 알림 메시지
                  if (!isLoggedIn)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.error,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '로그인이 필요합니다',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gemini API 키를 저장하고 사용하려면 먼저 로그인해야 합니다. 로그인 후 API 키를 설정해 주세요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onErrorContainer,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/auth');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('로그인 화면으로 이동'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 설명
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini API 키가 필요한 이유',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF Learner는 Gemini API를 사용하여 PDF 문서를 분석하고 학습을 도와줍니다. '
                          'API 키를 설정하면 더 정확한 분석과 개인화된 학습 경험을 제공받을 수 있습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // API 키 입력 필드
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'Gemini API 키',
                      hintText: 'AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6',
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isApiKeyVisible = !_isApiKeyVisible;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_paste),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data != null && data.text != null) {
                                _apiKeyController.text = data.text!;
                              }
                            },
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabled: isLoggedIn, // 로그인된 경우에만 입력 가능
                    ),
                    obscureText: !_isApiKeyVisible,
                    validator: (value) {
                      if (!isLoggedIn) {
                        return '로그인 후 API 키를 설정할 수 있습니다';
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'API 키를 입력해주세요';
                      }
                      if (value.length < 10) {
                        return '유효한 API 키를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // API 키 발급 안내
                  OutlinedButton.icon(
                    onPressed: _openGeminiApiPage,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Gemini API 키 발급 방법 보기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoggedIn && !_isLoading ? _saveApiKey : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(isLoggedIn ? 'API 키 저장' : '로그인 필요'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 