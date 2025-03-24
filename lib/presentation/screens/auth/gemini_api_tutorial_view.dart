import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API 키 발급 가이드'),
        actions: [
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 소개
            _buildSectionTitle('Gemini API 키란?', theme),
            _buildParagraph(
              'Gemini API는 Google의 AI 모델에 접근하여 텍스트 생성, 분석 및 요약 기능을 제공합니다. '
              '이 가이드는 Google AI Studio에서 Gemini API 키를 생성하는 방법을 설명합니다.',
              theme,
            ),
            _buildDivider(),
            
            // 주요 단계 요약
            _buildSectionTitle('주요 단계', theme),
            _buildStepsList([
              '1. Google AI Studio 웹사이트 방문하기',
              '2. Google 계정으로 로그인하기',
              '3. Gemini API 키 만들기',
              '4. API 키 복사하여 앱에 붙여넣기',
            ], theme),
            _buildDivider(),
            
            // 상세 가이드
            _buildSectionTitle('상세 가이드', theme),
            
            // 단계 1
            _buildStepTitle('1. Google AI Studio 방문', theme),
            _buildParagraph(
              '웹 브라우저를 열고 Google AI Studio 웹사이트(aistudio.google.com)에 접속합니다.',
              theme,
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildImagePlaceholder('Google AI Studio 홈페이지', theme),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Google AI Studio 방문하기'),
                      onPressed: () {
                        // TODO: URL 실행 (웹에서는 window.open)
                        // 모바일에서는 url_launcher 패키지 사용
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // 단계 2
            _buildStepTitle('2. Google 계정으로 로그인', theme),
            _buildParagraph(
              '웹사이트 상단의 "로그인" 버튼을 클릭하고 Google 계정으로 로그인합니다. '
              '계정이 없다면 새로 만들어야 합니다.',
              theme,
            ),
            _buildImagePlaceholder('로그인 화면', theme),
            
            // 단계 3
            _buildStepTitle('3. 프로젝트 구성', theme),
            _buildParagraph(
              '로그인 후, "Get API key" 또는 "API 키 가져오기" 버튼을 클릭합니다. '
              '새로운 프로젝트를 만들거나 기존 프로젝트를 선택하여 진행합니다.',
              theme,
            ),
            _buildImagePlaceholder('API 키 생성 버튼', theme),
            
            // 단계 4
            _buildStepTitle('4. API 키 생성', theme),
            _buildParagraph(
              '화면의 안내에 따라 API 키를 생성합니다. API 키가 생성되면 키를 복사합니다. '
              '이 키는 "AI"로 시작하며, 보안을 위해 다른 사람과 공유하면 안 됩니다.',
              theme,
            ),
            _buildImagePlaceholder('API 키 복사 화면', theme),
            
            // 단계 5
            _buildStepTitle('5. 앱에 API 키 입력', theme),
            _buildParagraph(
              '복사한 API 키를 앱의 "API 키 설정" 화면에 붙여넣습니다. '
              '이제 자신의 Gemini API 할당량으로 앱의 모든 기능을 이용할 수 있습니다.',
              theme,
            ),
            
            _buildDivider(),
            
            // 할당량 및 제한 정보
            _buildSectionTitle('할당량 및 한도', theme),
            _buildParagraph(
              'Google AI Studio의 무료 API 키는 분당 요청 수와 월간 총 요청 수에 제한이 있습니다. '
              '정확한 한도는 Google의 정책에 따라 변경될 수 있으므로 Google AI Studio의 공식 문서를 참고하세요.',
              theme,
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주의사항',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      'API 키는 개인 정보처럼 안전하게 보관해주세요.',
                      theme,
                    ),
                    _buildBulletPoint(
                      '할당량 초과 시 요약 생성이 일시적으로 불가능합니다.',
                      theme,
                    ),
                    _buildBulletPoint(
                      '유료 구독자는 자체 키 없이도 요약 서비스를 이용할 수 있습니다.',
                      theme,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 도움말 및 지원
            _buildSectionTitle('추가 도움말', theme),
            _buildParagraph(
              'API 키 발급에 어려움이 있거나 추가 질문이 있으시면 앱 내 피드백 기능이나 support@pdflearner.com으로 문의해주세요.',
              theme,
            ),
            
            const SizedBox(height: 24),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Google AI Studio 도움말'),
                    onPressed: () {
                      // TODO: URL 실행
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('이해했습니다'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 섹션 제목 위젯
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  
  /// 단계 제목 위젯
  Widget _buildStepTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 문단 텍스트 위젯
  Widget _buildParagraph(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
  
  /// 구분선 위젯
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
    );
  }
  
  /// 이미지 자리 표시자 위젯 (실제 앱에서는 이미지로 대체)
  Widget _buildImagePlaceholder(String label, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 단계 목록 위젯
  Widget _buildStepsList(List<String> steps, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            step,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    );
  }
  
  /// 글머리 기호 항목 위젯
  Widget _buildBulletPoint(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
} 