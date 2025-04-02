import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf_learner_v2/services/auth_service.dart';
import 'package:pdf_learner_v2/services/api_keys.dart';
import 'package:pdf_learner_v2/core/utils/app_theme.dart';
import 'package:pdf_learner_v2/presentation/screens/auth/gemini_api_tutorial_view.dart';

/// API 키 관리 화면
class ApiKeyManagementView extends StatefulWidget {
  const ApiKeyManagementView({Key? key}) : super(key: key);

  @override
  _ApiKeyManagementViewState createState() => _ApiKeyManagementViewState();
}

class _ApiKeyManagementViewState extends State<ApiKeyManagementView> {
  // 타임스탬프 기반 고유 키 사용
  final _formKey = UniqueKey();
  final _apiKeyController = TextEditingController();
  String? _userProvidedApiKey;
  bool _isLoading = false;
  late ApiKeyManager _apiKeyManager;
  
  @override
  void initState() {
    super.initState();
    _apiKeyManager = ApiKeyManager();
    _loadApiKey();
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
  
  /// 저장된 API 키 로드
  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvidedKey = await _apiKeyManager.getUserProvidedKey();
      
      setState(() {
        _userProvidedApiKey = userProvidedKey;
        if (userProvidedKey != null) {
          // 마스킹된 API 키를 표시
          _apiKeyController.text = _maskApiKey(userProvidedKey);
        }
      });
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 로드 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// API 키 저장
  Future<void> _saveApiKey(String apiKey) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _apiKeyManager.saveUserProvidedKey(apiKey);
      
      setState(() {
        _userProvidedApiKey = apiKey;
        _apiKeyController.text = _maskApiKey(apiKey);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 성공적으로 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 저장 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// API 키 삭제
  Future<void> _deleteApiKey() async {
    if (_userProvidedApiKey == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _apiKeyManager.clearUserProvidedKey();
      
      setState(() {
        _userProvidedApiKey = null;
        _apiKeyController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 성공적으로 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// API 키 숨기기 (마스킹)
  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '********';
    }
    
    // 앞 4자리와 뒤 4자리만 보여주고 나머지는 *로 대체
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 키 설정'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.help_outline),
            label: const Text('도움말'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeminiApiTutorialView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final user = authService.user;
          final isPremium = user?.subscriptionTier != null && 
                           user!.subscriptionTier != 'free';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPremium)
                  Card(
                    color: colorScheme.primaryContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified, 
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '유료 회원 혜택',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '유료 회원은 자체 API 키를 입력하지 않아도 요약 서비스를 이용할 수 있습니다. '
                            '다만, 자신의 API 키를 사용하면 앱 할당량과 별도로 사용할 수 있습니다.',
                          ),
                        ],
                      ),
                    ),
                  ),
                
                Form(
                  key: _formKey,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gemini API 키',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Google AI Studio에서 발급받은 API 키를 입력하여 요약 서비스를 사용할 수 있습니다. '
                            'API 키는 안전하게 로컬에 저장됩니다.',
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'API 키',
                              hintText: 'Gemini API 키를 입력하세요',
                              prefixIcon: const Icon(Icons.key),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.help_outline),
                                tooltip: 'API 키 발급 방법',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GeminiApiTutorialView(),
                                    ),
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                if (_userProvidedApiKey != null) {
                                  // 이미 저장된 키가 있는 경우 유효성 검사 통과
                                  return null;
                                }
                                return 'API 키를 입력하세요';
                              }
                              
                              // 마스킹된 API 키가 아닌 경우에만 형식 검사
                              if (!value.contains('...')) {
                                if (!value.startsWith('AI')) {
                                  return 'AI로 시작하는 유효한 Gemini API 키를 입력하세요';
                                }
                                
                                if (value.length < 10) {
                                  return 'API 키가 너무 짧습니다';
                                }
                              }
                              
                              return null;
                            },
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            onChanged: (value) {
                              // 마스킹된 API 키를 수정하려는 경우 클리어
                              if (_userProvidedApiKey != null && 
                                  value != _apiKeyController.text &&
                                  _apiKeyController.text.contains('...')) {
                                setState(() {
                                  _apiKeyController.clear();
                                });
                              }
                            },
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            '참고: 자신의 API 키를 사용하면 자체 할당량으로 처리됩니다',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('저장'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                  onPressed: _isLoading ? null : () {
                                    String apiKey = _apiKeyController.text;
                                    
                                    // 마스킹된 API 키인 경우 기존 키 유지
                                    if (apiKey.contains('...') && _userProvidedApiKey != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('변경사항이 없습니다'),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    _saveApiKey(apiKey);
                                  },
                                ),
                              ),
                              if (_userProvidedApiKey != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                  ),
                                  label: Text(
                                    '삭제',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: colorScheme.error),
                                  ),
                                  onPressed: _isLoading ? null : _deleteApiKey,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API 키 정보',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInfoItem(
                          icon: Icons.security,
                          title: '보안',
                          description: 'API 키는 사용자의 기기에만 암호화되어 저장됩니다.',
                        ),
                        
                        _buildInfoItem(
                          icon: Icons.speed,
                          title: '사용량',
                          description: 'Google AI Studio에서 제공하는 할당량 한도에 따라 사용할 수 있습니다.',
                        ),
                        
                        _buildInfoItem(
                          icon: Icons.info_outline,
                          title: '무료 사용자',
                          description: '자체 API 키가 없는 무료 사용자는 일일 제한된 사용량으로 서비스를 이용할 수 있습니다.',
                        ),
                        
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Google AI Studio 방문하기'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: () {
                            // TODO: URL 실행 (웹에서는 window.open)
                            // 모바일에서는 url_launcher 패키지 사용
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// 정보 아이템 위젯
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 