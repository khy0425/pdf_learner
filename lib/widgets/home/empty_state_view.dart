import 'package:flutter/material.dart';
import '../common/wave_painter.dart';
import './feature_item.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../view_models/pdf_file_view_model.dart';
import '../../services/api_key_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../views/auth/gemini_api_tutorial_view.dart';

/// 빈 상태 화면 위젯
/// PDF 파일이 없을 때 표시되는 화면입니다.
class EmptyStateView extends StatefulWidget {
  final VoidCallback? onAddPdf;
  final IconData? icon;
  final String? title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyStateView({
    Key? key,
    this.onAddPdf,
    this.icon,
    this.title,
    this.message,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);
  
  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _random = math.Random();
  bool _isChecking = true;
  bool _hasValidApiKey = false;
  bool _isPremiumUser = false;
  
  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // API 키 상태 확인
    _checkApiKeyStatus();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // API 키 상태 확인
  Future<void> _checkApiKeyStatus() async {
    try {
      setState(() {
        _isChecking = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isChecking = false;
          _hasValidApiKey = false;
        });
        return;
      }
      
      final apiKeyService = Provider.of<ApiKeyService>(context, listen: false);
      
      // 프리미엄 사용자 여부 확인
      final isPremium = await apiKeyService.isPremiumUser(user.uid);
      
      // API 키 확인
      final apiKey = await apiKeyService.getApiKey(user.uid);
      final isValidKey = apiKey != null && apiKey.isNotEmpty && apiKeyService.isValidApiKey(apiKey);
      
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isPremiumUser = isPremium;
          _hasValidApiKey = isValidKey || isPremium; // 프리미엄 사용자는 항상 유효한 API 키를 가짐
        });
      }
    } catch (e) {
      debugPrint('API 키 상태 확인 중 오류: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasValidApiKey = false;
        });
      }
    }
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
                  widget.icon ?? Icons.upload_file,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 제목
          Text(
            widget.title ?? 'PDF 파일이 없습니다',
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
              widget.message ?? '+ 버튼을 눌러 PDF 파일을 업로드하세요',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // API 키 상태 카드
          _buildApiKeyStatusCard(colorScheme),
          
          const SizedBox(height: 24),
          
          // PDF 추가 버튼
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
              onPressed: widget.onAddPdf ?? widget.onAction,
              icon: const Icon(Icons.add),
              label: Text(widget.actionLabel ?? 'PDF 추가하기'),
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
  
  // API 키 상태 카드
  Widget _buildApiKeyStatusCard(ColorScheme colorScheme) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Text(
              'API 키 상태 확인 중...',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    // API 키 상태에 따른 UI 설정
    Color bgColor;
    Color iconColor;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;
    
    if (_isPremiumUser) {
      bgColor = Colors.purple.withOpacity(0.2);
      iconColor = Colors.purple;
      statusIcon = Icons.workspace_premium;
      statusTitle = '프리미엄 API 액세스';
      statusMessage = '유료 회원은 API 키가 자동으로 제공됩니다';
    } else if (_hasValidApiKey) {
      bgColor = Colors.green.withOpacity(0.2);
      iconColor = Colors.green;
      statusIcon = Icons.verified;
      statusTitle = 'API 키가 설정되었습니다';
      statusMessage = 'AI 기능을 사용할 준비가 되었습니다';
    } else {
      bgColor = Colors.orange.withOpacity(0.2);
      iconColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'API 키 필요';
      statusMessage = 'PDF 내용 분석을 위해 API 키가 필요합니다';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isPremiumUser && !_hasValidApiKey)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeminiApiTutorialView(
                      onClose: null,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.key),
              label: const Text('API 키 설정하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (_hasValidApiKey && !_isPremiumUser)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeminiApiTutorialView(
                      onClose: null,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('API 키 관리'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
} 