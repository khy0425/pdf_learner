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
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 제목
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 설명 텍스트
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 액션 버튼
          if (widget.onAction != null && widget.actionLabel != null)
            ElevatedButton.icon(
              onPressed: widget.onAction,
              icon: const Icon(Icons.add),
              label: Text(widget.actionLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 