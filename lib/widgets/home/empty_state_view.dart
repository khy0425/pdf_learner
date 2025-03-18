import 'package:flutter/material.dart';
import '../common/wave_painter.dart';
import './feature_item.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../view_models/pdf_file_view_model.dart';

/// 빈 상태 화면 위젯
/// PDF 파일이 없을 때 표시되는 화면입니다.
class EmptyStateView extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyStateView({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);
  
  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 빈 상태 애니메이션
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0, 
                  4 * math.sin(_animationController.value * math.pi),
                ),
                child: child,
              );
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.7),
                    colorScheme.secondary.withOpacity(0.5),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 제목
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              shadows: [
                Shadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 설명 텍스트
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 액션 버튼
          if (widget.onAction != null && widget.actionLabel != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add),
                label: Text(widget.actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 