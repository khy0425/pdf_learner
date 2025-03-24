import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../views/auth/gemini_api_tutorial_view.dart';
import '../../theme/app_theme.dart';

/// API 키 상태 위젯
/// API 키 설정 여부와 사용자 구독 상태에 따라 다른 UI를 표시합니다.
class ApiKeyStatusWidget extends StatelessWidget {
  final bool isCheckingApiKey;
  final bool hasValidApiKey;
  final bool isPremiumUser;
  final String? maskedApiKey;

  const ApiKeyStatusWidget({
    super.key,
    required this.isCheckingApiKey,
    required this.hasValidApiKey,
    required this.isPremiumUser,
    this.maskedApiKey,
  });

  @override
  Widget build(BuildContext context) {
    if (isCheckingApiKey) {
      return _buildLoadingCard();
    }
    
    if (isPremiumUser) {
      return _buildPremiumCard();
    }
    
    if (hasValidApiKey) {
      return _buildValidApiKeyCard(context);
    }
    
    return _buildNoApiKeyCard(context);
  }
  
  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            const Text(
              'API 키 상태 확인 중...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '프리미엄 계정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '프리미엄 구독 중이므로 AI 기능을 제한 없이 사용할 수 있습니다.',
              style: TextStyle(fontSize: 14),
            ),
            if (maskedApiKey != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'API 키: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(maskedApiKey!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildValidApiKeyCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'API 키 설정됨',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'API 키가 설정되어 있어 모든 AI 기능을 사용할 수 있습니다.',
              style: TextStyle(fontSize: 14),
            ),
            if (maskedApiKey != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'API 키: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(maskedApiKey!),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('관리'),
                    onPressed: () => Navigator.pushNamed(context, '/api-key-management'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoApiKeyCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'API 키 필요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'AI 기능을 사용하려면 Gemini API 키가 필요합니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('API 키 정보'),
                    onPressed: () => Navigator.pushNamed(context, '/api-key-info'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('API 키 추가'),
                    onPressed: () => Navigator.pushNamed(context, '/api-key-add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '* 무료로 API 키를 발급받을 수 있습니다',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 