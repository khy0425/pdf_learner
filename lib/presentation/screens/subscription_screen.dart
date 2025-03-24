import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:your_app/services/firebase_auth_service.dart';
import 'package:your_app/models/user.dart';

class SubscriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('멤버십 안내')),
      body: Consumer<FirebaseAuthService>(
        builder: (context, authService, _) {
          final user = authService.currentUser;
          if (user == null) return const SizedBox();

          return Column(
            children: [
              // 현재 구독 상태
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      user.isPremium ? Icons.star : Icons.person_outline,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 멤버십: ${user.subscription.displayName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (user.subscriptionExpiresAt != null)
                          Text(
                            '만료일: ${DateFormat('yyyy/MM/dd').format(user.subscriptionExpiresAt!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // 멤버십 비교표
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSubscriptionCard(
                      context,
                      UserSubscription.free,
                      price: '무료',
                      isCurrentPlan: !user.isPremium,
                    ),
                    const SizedBox(height: 16),
                    _buildSubscriptionCard(
                      context,
                      UserSubscription.premium,
                      price: '월 9,900원',
                      isCurrentPlan: user.isPremium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    UserSubscription subscription, {
    required String price,
    required bool isCurrentPlan,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  subscription.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (isCurrentPlan) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('현재 이용중'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ],
            ),
            Text(
              price,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ...subscription.features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 20),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
            if (!isCurrentPlan && subscription == UserSubscription.premium)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: () => _showUpgradeDialog(context),
                  child: const Text('프리미엄으로 업그레이드'),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 