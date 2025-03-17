import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/api_key_service.dart';

class ApiKeyManagementView extends StatefulWidget {
  const ApiKeyManagementView({Key? key}) : super(key: key);

  @override
  State<ApiKeyManagementView> createState() => _ApiKeyManagementViewState();
}

class _ApiKeyManagementViewState extends State<ApiKeyManagementView> {
  final _apiKeyController = TextEditingController();
  String? _maskedApiKey;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiKeyService = ApiKeyService();
      
      if (authViewModel.isLoggedIn) {
        final apiKey = await apiKeyService.getApiKey(authViewModel.user!.uid);
        if (apiKey != null && apiKey.isNotEmpty) {
          setState(() {
            _maskedApiKey = apiKeyService.maskApiKey(apiKey);
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API 키를 불러오는 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'API 키를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiKeyService = ApiKeyService();
      
      final userId = authViewModel.isLoggedIn ? authViewModel.user!.uid : 'guest_user';
      await apiKeyService.saveApiKey(userId, _apiKeyController.text);
      
      setState(() {
        _maskedApiKey = apiKeyService.maskApiKey(_apiKeyController.text);
        _successMessage = 'API 키가 성공적으로 저장되었습니다';
        _apiKeyController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'API 키 저장 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteApiKey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiKeyService = ApiKeyService();
      
      final userId = authViewModel.isLoggedIn ? authViewModel.user!.uid : 'guest_user';
      await apiKeyService.deleteApiKey(userId);
      
      setState(() {
        _maskedApiKey = null;
        _successMessage = 'API 키가 성공적으로 삭제되었습니다';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'API 키 삭제 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 관리'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'OpenAI API 키',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'API 키는 PDF 분석에 사용됩니다. OpenAI API 키를 입력하세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveApiKey();
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // API 키 표시 및 관리 버튼
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'API 키',
                  hintText: 'OpenAI API 키를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                initialValue: _maskedApiKey ?? '••••••••••••••••••••••••••••••',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _showApiKeyDialog(),
              child: const Text('API 키 관리'),
            ),
          ],
        ),
        
        // 상태 메시지
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        
        if (_successMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
            ),
          ),
        
        // 설명 텍스트
        const SizedBox(height: 8),
        const Text(
          'API 키는 PDF 분석에 사용됩니다. OpenAI API 키를 입력하세요.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        
        // 삭제 버튼
        if (_maskedApiKey != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _deleteApiKey,
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              label: const Text('API 키 삭제', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
          ),
      ],
    );
  }
} 