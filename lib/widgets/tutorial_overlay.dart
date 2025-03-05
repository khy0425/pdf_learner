import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tutorial_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  
  const TutorialOverlay({
    super.key,
    required this.onFinish,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4; // 튜토리얼 페이지 수

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      // 마지막 페이지에서는 튜토리얼 종료
      widget.onFinish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

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
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        child: const Text('이전'),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _totalPages,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _nextPage,
                        child: Text(_currentPage < _totalPages - 1 ? '다음' : '완료'),
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
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
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