import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/home_view_model.dart';
import '../../views/auth/gemini_api_tutorial_view.dart';

/// API 키 상태 위젯
/// API 키 설정 여부와 사용자 구독 상태에 따라 다른 UI를 표시합니다.
class ApiKeyStatusWidget extends StatelessWidget {
  const ApiKeyStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          // 로딩 중인 경우
          if (viewModel.isCheckingApiKey) {
            return _buildLoadingCard(colorScheme);
          }
          
          // 프리미엄 사용자인 경우
          if (viewModel.isPremiumUser) {
            return _buildPremiumCard(context, colorScheme);
          }
          
          // API 키가 유효한 경우
          if (viewModel.hasValidApiKey) {
            return _buildValidKeyCard(context, colorScheme, viewModel.maskedApiKey);
          }
          
          // API 키가 없거나 유효하지 않은 경우
          return _buildNoKeyCard(context, colorScheme);
        },
      ),
    );
  }
  
  // 로딩 중인 카드
  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            const Text('API 키 상태 확인 중...'),
          ],
        ),
      ),
    );
  }
  
  // 프리미엄 사용자용 카드
  Widget _buildPremiumCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.withOpacity(0.3), width: 1),
      ),
      color: Colors.deepPurple.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '프리미엄 회원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '자동 활성화됨',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '프리미엄 회원은 추가 API 키 설정 없이 모든 서비스를 이용할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple[700],
              ),
            ),
            const SizedBox(height: 16),
            // 장점 리스트
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildPremiumFeatureRow(
                    Icons.auto_awesome,
                    '더 큰 파일 업로드 (최대 20MB)',
                  ),
                  const SizedBox(height: 8),
                  _buildPremiumFeatureRow(
                    Icons.flash_on,
                    '더 빠른 처리 속도',
                  ),
                  const SizedBox(height: 8),
                  _buildPremiumFeatureRow(
                    Icons.key_off,
                    'API 키 설정 불필요',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 프리미엄 기능 행
  Widget _buildPremiumFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.purple[700],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.purple[900],
          ),
        ),
      ],
    );
  }
  
  // 유효한 API 키가 있는 경우의 카드
  Widget _buildValidKeyCard(BuildContext context, ColorScheme colorScheme, String? maskedApiKey) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      color: Colors.green.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '유효함',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.key,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  maskedApiKey ?? '******',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeminiApiTutorialView(
                      onClose: null,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('API 키 관리'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // API 키가 없거나 유효하지 않은 경우의 카드
  Widget _buildNoKeyCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      color: Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '미설정',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF 파일 분석을 위해 Gemini API 키가 필요합니다. API 키를 설정하거나 프리미엄 구독을 시작하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const GeminiApiTutorialView(
                            onClose: null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text('API 키 발급받기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                    icon: const Icon(Icons.workspace_premium, size: 16),
                    label: const Text('프리미엄 구독'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 