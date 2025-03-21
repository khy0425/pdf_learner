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
import '../../theme/app_theme.dart';

/// 빈 상태 화면 위젯
/// PDF 파일이 없을 때 표시되는 화면입니다.
class EmptyStateView extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onUploadPressed;

  const EmptyStateView({
    Key? key,
    required this.isLoggedIn,
    required this.onUploadPressed,
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
      final isValidKey = apiKey != null && apiKey.isNotEmpty && await apiKeyService.isValidApiKey(apiKey);
      
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
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 상단 이미지/아이콘
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_file,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 메인 타이틀
            Text(
              '아직 PDF 파일이 없습니다',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 설명 텍스트
            Text(
              widget.isLoggedIn
                  ? 'PDF 파일을 업로드하고 AI 학습을 시작하세요'
                  : '게스트 모드에서는 최대 3개의 PDF 파일을 업로드할 수 있습니다',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // 업로드 버튼
            ElevatedButton.icon(
              onPressed: widget.onUploadPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text(
                'PDF 업로드',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 로그인 버튼 (로그인하지 않은 경우)
            if (!widget.isLoggedIn)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                icon: const Icon(Icons.login),
                label: const Text('로그인하고 더 많은 기능 사용하기'),
              ),
              
            const SizedBox(height: 32),
            
            // 기능 목록 설명
            if (widget.isLoggedIn) ...[
              const Divider(),
              const SizedBox(height: 24),
              
              const Text(
                'PDF Learner의 AI 기능',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureItem(
                icon: Icons.summarize,
                title: 'AI 요약',
                description: 'PDF 내용을 AI가 자동으로 요약해줍니다',
              ),
              
              _buildFeatureItem(
                icon: Icons.quiz,
                title: '퀴즈 생성',
                description: 'PDF 내용을 바탕으로 학습 퀴즈를 생성합니다',
              ),
              
              _buildFeatureItem(
                icon: Icons.highlight,
                title: '중요 내용 하이라이트',
                description: '중요한 내용을 자동으로 찾아 하이라이트합니다',
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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