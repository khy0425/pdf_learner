import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gemini API 키 발급 튜토리얼 화면
class GeminiApiTutorialView extends StatelessWidget {
  final VoidCallback? onClose;
  
  const GeminiApiTutorialView({
    Key? key,
    this.onClose,
  }) : super(key: key);
  
  /// Gemini API 키 발급 페이지 열기
  Future<void> _openGeminiApiPage() async {
    final Uri url = Uri.parse('https://ai.google.dev/tutorials/setup');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  
  /// Google Cloud Console 열기
  Future<void> _openGoogleCloudConsole() async {
    final Uri url = Uri.parse('https://console.cloud.google.com/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API 키 발급 방법'),
        actions: [
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
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
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 제목
                Center(
                  child: Text(
                    'Gemini API 키 발급 방법',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 소개
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Gemini API는 Google의 최신 AI 모델을 활용할 수 있게 해주는 서비스입니다. '
                    'PDF Learner는 이 API를 사용하여 PDF 문서를 분석하고 학습을 도와줍니다. '
                    '아래 단계를 따라 무료로 API 키를 발급받으세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 단계별 가이드
                _buildStepCard(
                  context,
                  step: 1,
                  title: 'Google AI Studio 방문하기',
                  description: 'Google AI Studio 웹사이트에 접속합니다. Google 계정으로 로그인이 필요합니다.',
                  actionText: 'Google AI Studio 열기',
                  onAction: () async {
                    final Uri url = Uri.parse('https://makersuite.google.com/app/apikey');
                    if (!await launchUrl(url)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                  imagePath: 'assets/images/tutorial/gemini_step1.png',
                ),
                
                const SizedBox(height: 16),
                
                _buildStepCard(
                  context,
                  step: 2,
                  title: 'API 키 생성하기',
                  description: '로그인 후 "Get API key" 버튼을 클릭하고, "Create API key in new project"를 선택합니다.',
                  actionText: null,
                  onAction: null,
                  imagePath: 'assets/images/tutorial/gemini_step2.png',
                ),
                
                const SizedBox(height: 16),
                
                _buildStepCard(
                  context,
                  step: 3,
                  title: '약관 동의 및 키 생성',
                  description: '이용 약관에 동의하고 "Create API key" 버튼을 클릭합니다. 생성된 API 키를 복사합니다.',
                  actionText: null,
                  onAction: null,
                  imagePath: 'assets/images/tutorial/gemini_step3.png',
                ),
                
                const SizedBox(height: 16),
                
                _buildStepCard(
                  context,
                  step: 4,
                  title: 'API 키 저장하기',
                  description: '복사한 API 키를 PDF Learner 앱의 API 키 입력 필드에 붙여넣고 저장합니다.',
                  actionText: null,
                  onAction: null,
                  imagePath: 'assets/images/tutorial/gemini_step4.png',
                ),
                
                const SizedBox(height: 32),
                
                // 주의사항
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '주의사항',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• API 키는 안전하게 보관하세요. 다른 사람과 공유하지 마세요.\n'
                        '• 무료 티어는 월간 사용량 제한이 있습니다.\n'
                        '• API 키는 PDF Learner 앱 내에서 안전하게 암호화되어 저장됩니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 도움말 링크
                Center(
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openGeminiApiPage,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Gemini API 공식 문서'),
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openGoogleCloudConsole,
                        icon: const Icon(Icons.cloud),
                        label: const Text('Google Cloud Console'),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 단계별 카드 위젯 생성
  Widget _buildStepCard(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    String? actionText,
    VoidCallback? onAction,
    String? imagePath,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 단계 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                
                if (imagePath != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(actionText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 