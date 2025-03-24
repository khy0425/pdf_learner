import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';

class PremiumSubscriptionPage extends StatelessWidget {
  const PremiumSubscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 플랜'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 기본 플랜
          _buildSubscriptionCard(
            context: context,
            title: '베이직 플랜',
            features: const [
              '광고 제거',
              '최대 20개 퀴즈 생성/일',
              '중간 길이 요약 생성',
              'AI 분석 기능',
            ],
            price: '₩1/월',
            onSubscribe: () => _subscribeToBasic(context, subscriptionService),
            isRecommended: false,
          ),
          
          const SizedBox(height: 16),
          
          // 프리미엄 플랜
          _buildSubscriptionCard(
            context: context,
            title: '프리미엄 플랜',
            features: const [
              '광고 제거',
              '최대 100개 퀴즈 생성/일',
              '긴 길이 요약 생성',
              'AI 분석 기능',
              'PDF 내보내기 기능',
              '공동 작업 기능',
            ],
            price: '₩3/월',
            onSubscribe: () => _subscribeToPremium(context, subscriptionService),
            isRecommended: true,
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            '모든 구독은 정기 결제로 등록되며, 언제든지 취소할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionCard({
    required BuildContext context,
    required String title,
    required List<String> features,
    required String price,
    required VoidCallback onSubscribe,
    required bool isRecommended,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended 
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '추천',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              price,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor: isRecommended
                      ? Colors.white
                      : null,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onSubscribe,
                child: const Text('구독하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _subscribeToBasic(BuildContext context, SubscriptionService service) async {
    _showSubscriptionDialog(
      context: context,
      title: '베이직 플랜 구독',
      message: '월 ₩1,000원에 베이직 플랜을 구독하시겠습니까?',
      onConfirm: () async {
        final success = await service.subscribe(SubscriptionTier.basic, 1);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('베이직 플랜 구독이 완료되었습니다.')),
          );
          Navigator.of(context).pop(); // 구독 페이지 닫기
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구독 처리 중 오류가 발생했습니다.')),
          );
        }
      },
    );
  }
  
  void _subscribeToPremium(BuildContext context, SubscriptionService service) async {
    _showSubscriptionDialog(
      context: context,
      title: '프리미엄 플랜 구독',
      message: '월 ₩3,000원에 프리미엄 플랜을 구독하시겠습니까?',
      onConfirm: () async {
        final success = await service.subscribe(SubscriptionTier.premium, 1);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프리미엄 플랜 구독이 완료되었습니다.')),
          );
          Navigator.of(context).pop(); // 구독 페이지 닫기
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구독 처리 중 오류가 발생했습니다.')),
          );
        }
      },
    );
  }
  
  void _showSubscriptionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('구독하기'),
          ),
        ],
      ),
    );
  }
} 