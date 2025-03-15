import 'package:flutter/material.dart';
import '../common/wave_painter.dart';
import './feature_item.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';

/// 빈 상태 화면 위젯
/// PDF 파일이 없을 때 표시되는 화면입니다.
class EmptyStateView extends StatefulWidget {
  final VoidCallback onAddPdf;
  
  const EmptyStateView({
    Key? key,
    required this.onAddPdf,
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
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
    
    // 익명 ID인지 확인
    final bool isAnonymousUser = pdfProvider.currentUserId.isEmpty || 
                                pdfProvider.currentUserId.startsWith('anonymous_');
    
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
                  Icons.picture_as_pdf,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 제목
          Text(
            '아직 PDF 파일이 없어요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 설명 텍스트 - 항상 PDF 추가 안내 메시지만 표시
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'PDF 파일을 추가하여 학습을 시작해보세요!',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // PDF 추가 버튼
          ElevatedButton.icon(
            onPressed: widget.onAddPdf,
            icon: const Icon(Icons.add),
            label: const Text('PDF 파일 추가하기'),
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
          
          const SizedBox(height: 16),
          
          // 익명 사용자에게만 보이는 로그인 권유 메시지
          if (isAnonymousUser)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '로그인하면 더 많은 기능 사용 가능',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그인하여 여러 기기에서 PDF 파일을 동기화하고 학습 진행 상황을 저장해보세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // 상위 스크린에서 로그인 다이얼로그 표시 로직 호출
                      Navigator.pushNamed(context, '/login'); // 로그인 화면으로 이동하는 대안
                    },
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('로그인하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 