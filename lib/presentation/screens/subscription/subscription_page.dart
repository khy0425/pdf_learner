import 'package:flutter/material.dart';
import 'package:pdf_learner_v2/data/models/user_model.dart';
import 'package:pdf_learner_v2/services/subscription_service.dart';
import 'package:pdf_learner_v2/core/utils/subscription_badge.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf_learner_v2/services/auth_service.dart';

/// 구독 상품 정보 모델
class SubscriptionPlan {
  final String id;
  final String tier;
  final String title;
  final String description;
  final int priceMonthly;
  final int priceYearly;
  final List<String> features;
  final int discount;
  final Color color;
  final IconData? icon;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.title,
    required this.description,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
    this.discount = 0,
    required this.color,
    this.icon,
    this.isPopular = false,
  });
}

/// 구독 페이지 화면
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isYearly = true;
  bool _isLoading = false;
  String? _selectedPlanId;
  
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'standard',
      tier: 'standard',
      title: '스탠다드',
      description: '기본적인 요약 기능으로 PDF 학습 효율을 높이세요',
      priceMonthly: 4900,
      priceYearly: 49900,
      discount: 15,
      color: Colors.blue,
      icon: Icons.book,
      features: [
        '일 10회 PDF 요약 생성',
        '최대 20개 PDF 저장',
        '광고 제거',
        '기본 고객 지원',
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      tier: 'pro',
      title: '프로',
      description: '더 많은 PDF를 분석하고 고급 학습 기능을 활용하세요',
      priceMonthly: 9900,
      priceYearly: 99900,
      discount: 16,
      color: Colors.purple,
      icon: Icons.workspace_premium,
      isPopular: true,
      features: [
        '일 20회 PDF 요약 생성',
        '최대 50개 PDF 저장',
        '광고 제거',
        '자체 API 키 지원',
        '우선 고객 지원',
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      tier: 'premium',
      title: '프리미엄',
      description: '무제한에 가까운 사용량과 최고급 기능을 경험하세요',
      priceMonthly: 19900,
      priceYearly: 199900,
      discount: 16,
      color: Colors.amber.shade700,
      icon: Icons.diamond,
      features: [
        '일 50회 PDF 요약 생성',
        '최대 100개 PDF 저장',
        '광고 제거',
        '자체 API 키 지원',
        'VIP 고객 지원',
        '최신 기능 우선 이용',
      ],
    ),
  ];

  // a6 정의 추가
  final double a6 = 16.0; // 적절한 크기로 설정

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 플랜'),
      ),
      body: Consumer2<AuthService, SubscriptionService>(
        builder: (context, authService, subscriptionService, _) {
          final user = authService.user;
          final currentTier = user?.subscriptionTier ?? 'free';
          
          return Stack(
            children: [
              // 스크롤 가능한 본문
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 구독 상태
                    if (user != null) _buildCurrentSubscription(user, subscriptionService),
                    
                    const SizedBox(height: 24),
                    
                    // 결제 주기 선택
                    _buildBillingToggle(colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // 구독 플랜 목록
                    ...List.generate(_plans.length, (index) {
                      final plan = _plans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPlanCard(
                          plan, 
                          colorScheme, 
                          textTheme,
                          isSelected: _selectedPlanId == plan.id,
                          isCurrentPlan: currentTier == plan.tier,
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    
                    // 무료 플랜 정보
                    _buildFreePlanCard(colorScheme, textTheme),
                    
                    const SizedBox(height: 32),
                    
                    // 결제 정보 및 정책
                    _buildPaymentInfo(textTheme),
                  ],
                ),
              ),
              
              // 하단 고정 버튼
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomBar(
                  colorScheme, 
                  textTheme, 
                  subscriptionService,
                  user?.subscriptionTier ?? 'free',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 현재 구독 정보 표시
  Widget _buildCurrentSubscription(
    UserModel user,
    SubscriptionService subscriptionService,
  ) {
    final tier = user.subscriptionTier;
    final badge = SubscriptionBadge.getBadgeForTier(tier);
    final isActive = user.isSubscriptionActive;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '현재 구독 정보',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
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
                        Icon(
                          badge.icon,
                          size: 16,
                          color: badge.textColor,
                        ),
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
            
            const SizedBox(height: 16),
            
            if (isActive && user.subscriptionExpiryDate != null) ...[
              Text('만료일: ${_formatDate(user.subscriptionExpiryDate!)}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: subscriptionService.subscriptionProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text('남은 기간: ${subscriptionService.remainingDays}일'),
            ] else if (tier != 'free') ...[
              const Text('구독이 만료되었습니다'),
              const SizedBox(height: 8),
              const Text(
                '아래에서 구독을 갱신하거나 다른 플랜을 선택하세요',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              const Text('현재 무료 플랜을 사용 중입니다'),
              const SizedBox(height: 8),
              const Text(
                '더 많은 기능을 위해 유료 구독을 고려해보세요',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 결제 주기 토글 버튼
  Widget _buildBillingToggle(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제 주기',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBillingOption(
                  title: '월간 결제',
                  description: '매월 결제',
                  isSelected: !_isYearly,
                  onTap: () => setState(() => _isYearly = false),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    _buildBillingOption(
                      title: '연간 결제',
                      description: '연 1회 결제 (할인)',
                      isSelected: _isYearly,
                      onTap: () => setState(() => _isYearly = true),
                      colorScheme: colorScheme,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '할인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 결제 주기 선택 옵션
  Widget _buildBillingOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : Colors.grey,
                  size: a6,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.primary : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? colorScheme.primary.withOpacity(0.8) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 구독 플랜 카드 위젯
  Widget _buildPlanCard(
    SubscriptionPlan plan,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isSelected = false,
    bool isCurrentPlan = false,
  }) {
    final price = _isYearly ? plan.priceYearly : plan.priceMonthly;
    
    return GestureDetector(
      onTap: isCurrentPlan 
          ? null 
          : () => setState(() => _selectedPlanId = plan.id),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? plan.color.withOpacity(0.1) 
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? plan.color 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: plan.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 및 타이틀
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: plan.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        plan.icon ?? Icons.star,
                        color: plan.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: plan.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 가격 정보
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₩${_formatPrice(price)}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isYearly ? '/년' : '/월',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    if (_isYearly && plan.discount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${plan.discount}% 할인',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 기능 목록
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: plan.color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 8),
                
                if (isCurrentPlan)
                  OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: BorderSide(color: plan.color),
                    ),
                    child: const Text('현재 사용 중'),
                  ),
              ],
            ),
          ),
          
          // 인기 플랜 배지
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  '인기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// 무료 플랜 정보 카드
  Widget _buildFreePlanCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_border,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '무료 플랜',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '기본 PDF 학습 기능',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '무료 플랜 기능:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          _buildFeatureRow('일 3회 PDF 요약 생성'),
          _buildFeatureRow('최대 5개 PDF 저장'),
          _buildFeatureRow('광고 포함', isIncluded: false),
          _buildFeatureRow('기본 고객 지원'),
        ],
      ),
    );
  }
  
  /// 기능 행 위젯
  Widget _buildFeatureRow(String text, {bool isIncluded = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            color: isIncluded ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  /// 결제 정보 및 정책 위젯
  Widget _buildPaymentInfo(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 정보',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• 구독은 선택한 주기에 따라 자동 갱신됩니다.\n'
          '• 갱신일 24시간 전까지 취소할 수 있습니다.\n'
          '• 결제는 Google Play 계정이나 App Store 계정으로 청구됩니다.\n'
          '• 구독은 계정 설정에서 관리할 수 있습니다.\n'
          '• 현재 결제 기간이 끝나기 전에 취소해도 남은 기간 동안은 서비스를 계속 이용할 수 있습니다.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: 이용약관 페이지로 이동
              },
              child: const Text('이용약관'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                // TODO: 개인정보처리방침 페이지로 이동
              },
              child: const Text('개인정보처리방침'),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 하단 고정 버튼 바
  Widget _buildBottomBar(
    ColorScheme colorScheme, 
    TextTheme textTheme,
    SubscriptionService subscriptionService,
    String currentTier,
  ) {
    final selectedPlan = _plans.firstWhere(
      (plan) => plan.id == _selectedPlanId,
      orElse: () => _plans.first,
    );
    
    final price = _isYearly ? selectedPlan.priceYearly : selectedPlan.priceMonthly;
    final cycle = _isYearly ? '년' : '월';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedPlanId != null) ...[
                  Text(
                    '${selectedPlan.title} 플랜',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₩${_formatPrice(price)}/$cycle',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ] else ...[
                  const Text('플랜을 선택해주세요'),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _selectedPlanId == null || 
                       _isLoading || 
                       _selectedPlanId == currentTier
                ? null 
                : () => _processPurchase(
                    subscriptionService, 
                    selectedPlan, 
                    _isYearly ? 365 : 30,
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('구독하기'),
          ),
        ],
      ),
    );
  }
  
  /// 결제 처리 함수
  Future<void> _processPurchase(
    SubscriptionService subscriptionService,
    SubscriptionPlan plan,
    int durationInDays,
  ) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: 실제 결제 처리 로직 구현
      
      // 현재는 실제 결제 없이 바로 구독으로 처리
      await subscriptionService.upgradeSubscription(
        tier: plan.tier,
        durationInDays: durationInDays,
      );
      
      // 성공 메시지 및 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plan.title} 플랜 구독에 성공했습니다')),
        );
        Navigator.of(context).pop(true); // 성공 결과와 함께 돌아가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구독 처리 중 오류가 발생했습니다: $e')),
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
  
  /// 날짜 포맷 함수
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
  
  /// 가격 포맷 함수 (1,000 단위 콤마)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
} 