import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tutorial_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 400,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: PageView(
                      children: [
                        // API 키 상태 확인 페이지
                        FutureBuilder<bool>(
                          future: _checkApiKeys(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final hasApiKeys = snapshot.data ?? false;
                            return TutorialPage(
                              title: '환영합니다!',
                              description: hasApiKeys 
                                  ? 'API 키가 정상적으로 설정되어 있습니다.\n이제 PDF 학습을 시작해보세요!'
                                  : 'API 키 설정이 필요합니다.\n설정 메뉴에서 API 키를 입력해주세요.',
                              icon: hasApiKeys ? Icons.check_circle : Icons.warning,
                            );
                          },
                        ),
                        const TutorialPage(
                          title: 'PDF 업로드',
                          description: 'PDF 파일을 드래그하거나 선택하여 업로드하세요.',
                          icon: Icons.upload_file,
                        ),
                        // ... 다른 튜토리얼 페이지들
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          context.read<TutorialProvider>().completeTutorial(
                            skipForToday: true,
                          );
                        },
                        child: const Text('오늘 하루 보지 않기'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          context.read<TutorialProvider>().completeTutorial();
                        },
                        child: const Text('시작하기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkApiKeys() async {
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    final hfKey = dotenv.env['HUGGING_FACE_API_KEY'];
    return (geminiKey?.isNotEmpty ?? false) && (hfKey?.isNotEmpty ?? false);
  }
}

class TutorialPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const TutorialPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 