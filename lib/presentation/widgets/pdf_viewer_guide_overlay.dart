import 'package:flutter/material.dart';

class PDFViewerGuideOverlay extends StatefulWidget {
  final Offset menuButtonPosition;
  final Offset searchButtonPosition;
  final Offset summaryButtonPosition;
  final Offset quizButtonPosition;
  final Offset helpButtonPosition;
  final VoidCallback? onFinish;

  const PDFViewerGuideOverlay({
    required this.menuButtonPosition,
    required this.searchButtonPosition,
    required this.summaryButtonPosition,
    required this.quizButtonPosition,
    required this.helpButtonPosition,
    this.onFinish,
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
    _initializeSteps();
  }

  // 가이드 스텝 초기화
  void _initializeSteps() {
    _steps = [
      GuideStep(
        title: '목차 보기',
        description: '문서의 목차를 확인하고 원하는 섹션으로 이동할 수 있습니다.',
        icon: Icons.menu_book,
        position: widget.menuButtonPosition,
      ),
      GuideStep(
        title: '검색',
        description: 'Ctrl+F를 누르거나 이 버튼을 클릭하여 문서 내 검색이 가능합니다.',
        icon: Icons.search,
        position: widget.searchButtonPosition,
      ),
      GuideStep(
        title: 'AI 요약',
        description: '현재 페이지의 내용을 AI가 요약해드립니다.',
        icon: Icons.summarize,
        position: widget.summaryButtonPosition,
      ),
      GuideStep(
        title: '퀴즈 생성',
        description: 'PDF 내용을 바탕으로 학습 퀴즈를 생성합니다.',
        icon: Icons.quiz,
        position: widget.quizButtonPosition,
      ),
      GuideStep(
        title: '도우미',
        description: '이 버튼을 클릭하면 언제든지 이 가이드를 다시 볼 수 있습니다.',
        icon: Icons.help_outline,
        position: widget.helpButtonPosition,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
          // 하이라이트 표시
          Positioned(
            left: step.position.dx - 25,
            top: step.position.dy - 25,
            child: Container(
              width: 50,
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
    if (widget.onFinish != null) {
      widget.onFinish!();
    }
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