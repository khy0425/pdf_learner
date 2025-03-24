class UsageLimitDialog extends StatelessWidget {
  final SubscriptionTier currentTier;

  const UsageLimitDialog({
    super.key,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('사용 제한 도달'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('일일 AI 요약 사용 횟수 ${currentTier.dailyAILimit}회를 모두 사용하셨습니다.'),
          const SizedBox(height: 16),
          if (currentTier == SubscriptionTier.guest)
            const Text('회원가입하시면 매일 3회 무료로 사용하실 수 있습니다.')
          else if (currentTier == SubscriptionTier.free)
            const Text('프리미엄 회원으로 업그레이드하시면\n하루 100회까지 사용하실 수 있습니다.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        if (currentTier == SubscriptionTier.guest)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signup');
            },
            child: const Text('회원가입하기'),
          )
        else if (currentTier == SubscriptionTier.free)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text('프리미엄 가입하기'),
          ),
      ],
    );
  }
} 