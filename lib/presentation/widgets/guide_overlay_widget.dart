import 'package:flutter/material.dart';
import 'dart:math';

/// 화면 위에 가이드 오버레이를 표시하는 위젯
/// GlobalKey를 사용하지 않고 상대적 위치만을 사용하여 오버레이를 표시합니다.
class GuideOverlayWidget extends StatefulWidget {
  /// 가이드 완료 시 호출할 콜백
  final VoidCallback onFinish;
  
  /// 화면 크기 정보 (MediaQuery에서 가져옴)
  final Size screenSize;
  
  /// 버튼 위치 정보 (화면 상단 왼쪽 기준 상대적 위치)
  final Map<String, Offset> buttonPositions;
  
  /// 가이드 단계 정보
  final List<GuideStepInfo> steps;

  const GuideOverlayWidget({
    super.key,
    required this.onFinish,
    required this.screenSize,
    required this.buttonPositions,
    required this.steps,
  });

  @override
  State<GuideOverlayWidget> createState() => _GuideOverlayWidgetState();
}

class _GuideOverlayWidgetState extends State<GuideOverlayWidget> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    // 현재 단계 정보
    final currentStep = widget.steps[_currentStep];
    
    // 현재 단계의 버튼 위치
    final buttonPosition = widget.buttonPositions[currentStep.id] ?? 
                          Offset(widget.screenSize.width / 2, widget.screenSize.height / 2);
    
    // 툴팁 위치 계산 (화면 경계 고려)
    final contentWidth = min(300.0, widget.screenSize.width * 0.8);
    double tooltipLeft = buttonPosition.dx - contentWidth / 2;
    double tooltipTop = buttonPosition.dy + 40; // 버튼 아래에 표시
    
    // 화면 경계를 벗어나지 않도록 조정
    tooltipLeft = max(20, min(tooltipLeft, widget.screenSize.width - contentWidth - 20));
    
    // 툴팁이 하단을 벗어나는 경우 버튼 위에 표시
    if (tooltipTop + 180 > widget.screenSize.height) {
      tooltipTop = max(20, buttonPosition.dy - 180);
    }
    
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 배경 오버레이 (반투명 검정)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // 빈 영역 터치 시 이벤트 무시
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          
          // 현재 단계 버튼 하이라이트
          Positioned(
            left: buttonPosition.dx - 25,
            top: buttonPosition.dy - 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 가이드 툴팁 내용
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
                  Row(
                    children: [
                      Icon(currentStep.icon, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentStep.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            inherit: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    currentStep.description,
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
                        '${_currentStep + 1}/${widget.steps.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          inherit: true,
                        ),
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              widget.onFinish();
                            },
                            child: const Text(
                              '건너뛰기',
                              style: TextStyle(inherit: true),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStep < widget.steps.length - 1) {
                                setState(() {
                                  _currentStep++;
                                });
                              } else {
                                widget.onFinish();
                              }
                            },
                            child: Text(
                              _currentStep < widget.steps.length - 1 ? '다음' : '완료',
                              style: const TextStyle(inherit: true),
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

/// 가이드 단계 정보 클래스
class GuideStepInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const GuideStepInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
} 