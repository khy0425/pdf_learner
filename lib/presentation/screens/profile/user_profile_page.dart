import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/subscription_badge.dart';
import '../../models/user_model.dart';
import '../auth/api_key_management_view.dart';
import '../auth/gemini_api_tutorial_view.dart';
import '../subscription/subscription_page.dart';
import 'package:intl/intl.dart';

/// 사용자 프로필 페이지
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            onPressed: _isLoading ? null : _handleLogout,
          ),
        ],
      ),
      body: Consumer2<AuthService, SubscriptionService>(
        builder: (context, authService, subscriptionService, _) {
          final user = authService.user;
          
          if (user == null) {
            return const Center(
              child: Text('로그인이 필요합니다'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 기본 정보
                _buildUserInfoCard(user, colorScheme, textTheme),
                
                const SizedBox(height: 16),
                
                // 구독 정보
                _buildSubscriptionCard(
                  user, 
                  colorScheme, 
                  textTheme, 
                  subscriptionService,
                ),
                
                const SizedBox(height: 16),
                
                // API 키 관리 섹션
                _buildApiKeySection(colorScheme, textTheme),
                
                const SizedBox(height: 16),
                
                // 앱 사용량 통계
                _buildUsageStatsCard(user, colorScheme, textTheme),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// 사용자 기본 정보 카드
  Widget _buildUserInfoCard(UserModel user, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.photoURL!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              user.displayName?.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Text(
                          user.displayName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? '사용자',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '가입일: ${DateFormat('yyyy년 MM월 dd일').format(user.createdAt ?? DateTime.now())}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('프로필 수정'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                // TODO: 프로필 수정 페이지로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// 구독 정보 카드
  Widget _buildSubscriptionCard(
    UserModel user, 
    ColorScheme colorScheme, 
    TextTheme textTheme,
    SubscriptionService subscriptionService,
  ) {
    final subscriptionTier = user.subscriptionTier ?? 'free';
    final badge = SubscriptionBadge.getBadgeForTier(subscriptionTier);
    final benefits = SubscriptionBadge.getBenefitsForTier(subscriptionTier);
    
    // 구독 만료일 계산 (샘플 코드)
    final now = DateTime.now();
    DateTime? expiryDate;
    
    if (subscriptionTier != 'free') {
      // 실제 구현에서는 사용자 모델이나 구독 서비스에서 가져와야 함
      expiryDate = now.add(const Duration(days: 30));
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '구독 정보',
                  style: textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badge.icon != null) ...[
                        Icon(badge.icon, size: 16, color: badge.textColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        badge.label,
                        style: TextStyle(
                          color: badge.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (expiryDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '만료일: ${DateFormat('yyyy년 MM월 dd일').format(expiryDate)}',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 1 - (expiryDate.difference(now).inDays / 30),
                backgroundColor: colorScheme.surfaceVariant,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                '남은 기간: ${expiryDate.difference(now).inDays}일',
                style: textTheme.bodySmall,
              ),
            ],
            
            const SizedBox(height: 16),
            
            Text(
              '구독 혜택',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // 구독 혜택 목록
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(benefit)),
                ],
              ),
            )).toList(),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('구독 플랜 변경'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// API 키 관리 섹션
  Widget _buildApiKeySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API 키 관리',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.key),
                    label: const Text('API 키 설정'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApiKeyManagementView(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: const Text('API 키 발급 튜토리얼'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GeminiApiTutorialView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Text(
              'API 키를 설정하면 자신의 Gemini API 할당량을 사용할 수 있습니다. '
              '유료 회원은 별도의 API 키 없이도 모든 기능을 사용할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 앱 사용량 통계 카드
  Widget _buildUsageStatsCard(UserModel user, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사용량 통계',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 통계 그리드
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  icon: Icons.summarize,
                  title: '요약 생성',
                  value: '${user.usageCount ?? 0}회',
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  icon: Icons.picture_as_pdf,
                  title: 'PDF 열람',
                  value: '${user.maxPdfsTotal ?? 0}개',
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  icon: Icons.calendar_today,
                  title: '일일 사용 한도',
                  value: '${user.maxUsagePerDay ?? 0}회',
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  icon: Icons.access_time,
                  title: '마지막 사용',
                  value: user.lastUsageAt != null 
                      ? DateFormat('MM/dd HH:mm').format(user.lastUsageAt!)
                      : '없음',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 통계 카드 아이템
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 