import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tutorial_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TutorialOverlay extends StatefulWidget {
  final Widget child;

  const TutorialOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // 현재 하이라이트된 위젯의 위치와 크기 정보
  Rect? _targetRect;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 애니메이션 시작
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // 대상 위젯의 위치와 크기 얻기
  void _updateTargetRect(BuildContext context, GlobalKey key) {
    try {
      RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        setState(() {
          _targetRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            size.width,
            size.height,
          );
        });
      }
    } catch (e) {
      print('위치 계산 오류: $e');
      _targetRect = null;
    }
  }
  
  // 툴팁 위치 계산
  Offset _calculateTooltipOffset(Size tooltipSize, Position position) {
    if (_targetRect == null) {
      // 대상 위치를 찾을 수 없는 경우 화면 중앙에 표시
      final screenSize = MediaQuery.of(context).size;
      return Offset(
        (screenSize.width - tooltipSize.width) / 2,
        (screenSize.height - tooltipSize.height) / 2,
      );
    }
    
    switch (position) {
      case Position.top:
        return Offset(
          _targetRect!.center.dx - tooltipSize.width / 2,
          _targetRect!.top - tooltipSize.height - 20,
        );
      case Position.bottom:
        return Offset(
          _targetRect!.center.dx - tooltipSize.width / 2,
          _targetRect!.bottom + 20,
        );
      case Position.left:
        return Offset(
          _targetRect!.left - tooltipSize.width - 20,
          _targetRect!.center.dy - tooltipSize.height / 2,
        );
      case Position.right:
        return Offset(
          _targetRect!.right + 20,
          _targetRect!.center.dy - tooltipSize.height / 2,
        );
      case Position.center:
        return Offset(
          _targetRect!.center.dx - tooltipSize.width / 2,
          _targetRect!.center.dy - tooltipSize.height / 2,
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialProvider>(
      builder: (context, tutorialProvider, _) {
        final currentStep = tutorialProvider.currentTutorialStep;
        
        if (!tutorialProvider.showTutorial || currentStep == null) {
          return widget.child;
        }
        
        // 대상 위젯의 위치 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateTargetRect(context, currentStep.targetKey);
        });
        
        return Stack(
          children: [
            widget.child,
            
            // 오버레이 배경
            Positioned.fill(
              child: FadeTransition(
                opacity: _animation,
                child: GestureDetector(
                  onTap: () {
                    // 배경 탭 시 다음 단계로
                    tutorialProvider.nextStep();
                  },
                  child: Container(
                    color: Colors.black54,
                    child: CustomPaint(
                      painter: _TargetPainter(
                        targetRect: _targetRect,
                        animation: _animation,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // 툴팁
            if (_targetRect != null)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  // 툴팁 크기 (추정)
                  final tooltipSize = Size(300, 180);
                  final offset = _calculateTooltipOffset(
                    tooltipSize, 
                    currentStep.position,
                  );
                  
                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: FadeTransition(
                      opacity: _animation,
                      child: _TutorialTooltip(
                        title: currentStep.title,
                        description: currentStep.description,
                        icon: currentStep.icon,
                        isFirst: tutorialProvider.currentStep == 0,
                        isLast: tutorialProvider.isLastStep,
                        onPrevious: () => tutorialProvider.previousStep(),
                        onNext: () => tutorialProvider.nextStep(),
                        onSkip: () => tutorialProvider.stopTutorial(),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// 투명한 구멍이 있는 오버레이를 그리는 CustomPainter
class _TargetPainter extends CustomPainter {
  final Rect? targetRect;
  final Animation<double> animation;
  
  _TargetPainter({this.targetRect, required this.animation});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect == null) return;
    
    final paint = Paint()..color = Colors.transparent;
    
    // 전체 캔버스 영역 그리기
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // 애니메이션 효과: 하이라이트 영역 주변에 발광 효과
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * animation.value;
    
    // 하이라이트된 영역에 확장된 원 그리기 (애니메이션 효과)
    final expandedRect = Rect.fromCenter(
      center: targetRect!.center,
      width: targetRect!.width + 10 * animation.value,
      height: targetRect!.height + 10 * animation.value,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(expandedRect, Radius.circular(8)),
      highlightPaint,
    );
    
    // 구멍 뚫기 (BlendMode.clear 활용)
    final holePaint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.clear;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect!, Radius.circular(4)),
      holePaint,
    );
  }
  
  @override
  bool shouldRepaint(_TargetPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect || 
           animation.value != oldDelegate.animation.value;
  }
}

// 튜토리얼 툴팁 위젯
class _TutorialTooltip extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  
  const _TutorialTooltip({
    required this.title,
    required this.description,
    this.icon,
    required this.isFirst,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
    required this.onSkip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 (제목 + 아이콘)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon!,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // 설명 텍스트
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          
          SizedBox(height: 20),
          
          // 하단 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 건너뛰기 버튼
              TextButton(
                onPressed: onSkip,
                child: Text('건너뛰기'),
              ),
              
              // 이전/다음 버튼
              Row(
                children: [
                  if (!isFirst)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: onPrevious,
                    ),
                  
                  IconButton(
                    icon: Icon(
                      isLast ? Icons.check : Icons.arrow_forward_ios,
                      size: 18,
                    ),
                    onPressed: onNext,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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