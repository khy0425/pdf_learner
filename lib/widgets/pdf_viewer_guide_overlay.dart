import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tutorial_provider.dart';

class PDFViewerGuideOverlay extends StatefulWidget {
  final GlobalKey menuBookKey;
  final GlobalKey searchKey;
  final GlobalKey summaryKey;
  final GlobalKey quizKey;
  final GlobalKey helpKey;

  const PDFViewerGuideOverlay({
    required this.menuBookKey,
    required this.searchKey,
    required this.summaryKey,
    required this.quizKey,
    required this.helpKey,
    super.key,
  });

  @override
  State<PDFViewerGuideOverlay> createState() => _PDFViewerGuideOverlayState();
}

class _PDFViewerGuideOverlayState extends State<PDFViewerGuideOverlay> {
  int _currentStep = 0;
  late List<GuideStep> _steps;

  @override
  void initState() {
    super.initState();
    // 초기 스텝은 빈 리스트로 시작
    _steps = [];
  }

  // 버튼 위치를 찾는 함수 수정
  Offset _findButtonPosition(GlobalKey key) {
    try {
      final RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;
      final Size size = renderBox.size;  // 버튼의 실제 크기 가져오기
      final position = renderBox.localToGlobal(Offset.zero);
      
      // 버튼의 중앙 위치 계산
      return Offset(
        position.dx + (size.width / 2),
        position.dy + (size.height / 2),
      );
    } catch (e) {
      return const Offset(0, 0);
    }
  }

  // 가이드 스텝 초기화
  void _initializeSteps(BuildContext context) {
    if (_steps.isNotEmpty) return;

    _steps = [
      GuideStep(
        title: '목차 보기',
        description: '문서의 목차를 확인하고 원하는 섹션으로 이동할 수 있습니다.',
        icon: Icons.menu_book,
        position: _findButtonPosition(widget.menuBookKey),
      ),
      GuideStep(
        title: '검색',
        description: 'Ctrl+F를 누르거나 이 버튼을 클릭하여 문서 내 검색이 가능합니다.',
        icon: Icons.search,
        position: _findButtonPosition(widget.searchKey),
      ),
      GuideStep(
        title: 'AI 요약',
        description: '현재 페이지의 내용을 AI가 요약해드립니다.',
        icon: Icons.summarize,
        position: _findButtonPosition(widget.summaryKey),
      ),
      GuideStep(
        title: '퀴즈 생성',
        description: 'PDF 내용을 바탕으로 학습 퀴즈를 생성합니다.',
        icon: Icons.quiz,
        position: _findButtonPosition(widget.quizKey),
      ),
      GuideStep(
        title: '도우미',
        description: '이 버튼을 클릭하면 언제든지 이 가이드를 다시 볼 수 있습니다.',
        icon: Icons.help_outline,
        position: _findButtonPosition(widget.helpKey),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _initializeSteps(context);
    
    if (_currentStep >= _steps.length) return const SizedBox.shrink();

    final step = _steps[_currentStep];
    final screenSize = MediaQuery.of(context).size;
    
    // 말풍선 위치 계산
    double tooltipLeft = step.position.dx - 125;  // 중앙 정렬을 위해 조정
    double tooltipTop = step.position.dy + 30;    // 버튼과의 간격 조정

    // 화면 경계를 벗어나지 않도록 조정
    if (tooltipLeft + 250 > screenSize.width) {
      tooltipLeft = screenSize.width - 260;
    }
    if (tooltipLeft < 10) tooltipLeft = 10;
    
    if (tooltipTop + 200 > screenSize.height) {
      tooltipTop = step.position.dy - 220;  // 말풍선이 위로 가도록 조정
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 반투명 배경
          Positioned.fill(
            child: GestureDetector(
              onTap: _nextStep,
              child: Container(color: Colors.black54),
            ),
          ),
          // 하이라이트 표시 수정
          Positioned(
            // 버튼 중앙에서 원의 반지름만큼 뺀 위치
            left: step.position.dx - 25,
            top: step.position.dy - 25,
            child: Container(
              width: 50,  // 버튼을 충분히 감싸도록 크기 증가
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          // 설명 말풍선
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(step.description),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _skipGuide,
                        child: const Text('건너뛰기'),
                      ),
                      FilledButton(
                        onPressed: _nextStep,
                        child: Text(
                          _currentStep < _steps.length - 1 ? '다음' : '완료'
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    if (_currentStep >= _steps.length) {
      _completeGuide();
    }
  }

  void _skipGuide() {
    setState(() {
      _currentStep = _steps.length;
    });
    _completeGuide();
  }

  void _completeGuide() {
    context.read<TutorialProvider>().completePDFViewerGuide();
  }
}

class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final Offset position;

  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.position,
  });
} 