import 'package:flutter/material.dart';
import 'dart:math';

class PDFViewerGuideOverlay extends StatefulWidget {
  final Offset menuButtonPosition;
  final Offset searchButtonPosition;
  final Offset summaryButtonPosition;
  final Offset quizButtonPosition;
  final Offset helpButtonPosition;
  final VoidCallback onFinish;

  const PDFViewerGuideOverlay({
    Key? key,
    required this.menuButtonPosition,
    required this.searchButtonPosition,
    required this.summaryButtonPosition,
    required this.quizButtonPosition,
    required this.helpButtonPosition,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<PDFViewerGuideOverlay> createState() => _PDFViewerGuideOverlayState();
}

class _PDFViewerGuideOverlayState extends State<PDFViewerGuideOverlay> {
  int _currentStep = 0;
  final List<String> _titleTexts = [
    '목차 기능',
    '검색 기능',
    'AI 요약 기능',
    'AI 퀴즈 생성 기능',
    '도움말'
  ];

  final List<String> _descriptionTexts = [
    'PDF 문서의 목차를 확인할 수 있습니다.',
    '문서 내에서 특정 키워드를 검색할 수 있습니다.',
    'AI가 문서의 주요 내용을 요약해 줍니다.',
    'AI가 문서 내용을 기반으로 퀴즈를 생성합니다.',
    '문서 뷰어 사용법과 기능에 대한 도움말을 확인할 수 있습니다.'
  ];

  @override
  Widget build(BuildContext context) {
    List<Offset> positions = [
      widget.menuButtonPosition,
      widget.searchButtonPosition,
      widget.summaryButtonPosition,
      widget.quizButtonPosition,
      widget.helpButtonPosition,
    ];
    
    // 현재 스텝에 따른 대상 버튼 위치
    Offset targetPosition = positions[_currentStep];
    
    // 화면 크기
    final screenSize = MediaQuery.of(context).size;
    
    // 콘텐츠 크기 - 반응형 조정
    final contentWidth = min(300.0, screenSize.width * 0.8);
    
    // 툴팁 위치 계산
    double tooltipLeft = targetPosition.dx - contentWidth / 2;
    double tooltipTop = targetPosition.dy + 35; // 버튼 아래에 표시
    
    // 화면 경계를 벗어나지 않도록 조정
    tooltipLeft = max(20, min(tooltipLeft, screenSize.width - contentWidth - 20));
    
    // 툴팁이 하단을 벗어나는 경우 버튼 위에 표시
    if (tooltipTop + 180 > screenSize.height) {
      tooltipTop = max(20, targetPosition.dy - 180);
    }
    
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 배경 오버레이 (반투명 검정)
          GestureDetector(
            onTap: () {
              // 터치 무시
            },
            child: Container(
              color: Colors.black.withOpacity(0.6),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // 현재 단계 하이라이트
          Positioned(
            left: targetPosition.dx - 25,
            top: targetPosition.dy - 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 툴팁 내용
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: Container(
              width: contentWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleTexts[_currentStep],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      inherit: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionTexts[_currentStep],
                    style: const TextStyle(
                      fontSize: 14,
                      inherit: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentStep + 1}/${_titleTexts.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          inherit: true,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: () {
                                // 다음 프레임에서 상태 업데이트
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _currentStep--;
                                    });
                                  }
                                });
                              },
                              child: const Text(
                                '이전',
                                style: TextStyle(
                                  inherit: true,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStep < _titleTexts.length - 1) {
                                // 다음 단계로 이동
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _currentStep++;
                                    });
                                  }
                                });
                              } else {
                                // 마지막 단계에서는 완료 처리
                                widget.onFinish();
                              }
                            },
                            child: Text(
                              _currentStep < _titleTexts.length - 1 ? '다음' : '완료',
                              style: const TextStyle(
                                inherit: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuideStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Offset position;

  GuideStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.position,
  });
} 