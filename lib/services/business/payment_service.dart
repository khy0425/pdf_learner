import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/subscription_tier.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // PayPal 플랜 ID 상수
  static const String PLUS_PLAN_ID = 'P-8K191198418577211M6ZFB3Q';
  static const String PREMIUM_PLAN_ID = 'P-7V8807917R0068540M6ZFD2A';
  static const String PREMIUM_TRIAL_PLAN_ID = 'P-TRIAL_PLAN_ID';  // 실제 PayPal 플랜 ID로 교체 필요
  
  // PayPal 결제 처리
  Future<PaymentResult> processPayPalSubscription({
    required SubscriptionTier tier,
    required BuildContext context,
  }) async {
    try {
      final planId = _getPlanId(tier);
      
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaypalCheckout(
            sandboxMode: false,
            clientId: const String.fromEnvironment('PAYPAL_CLIENT_ID'),
            secretKey: const String.fromEnvironment('PAYPAL_SECRET_KEY'),
            returnURL: "success.example.com",
            cancelURL: "cancel.example.com",
            subscriptionPlanId: planId,
            onApprove: (String subscriptionId) async {
              await _verifySubscription(
                subscriptionId: subscriptionId,
                tier: tier,
              );
            },
          ),
        ),
      );

      if (result?.status == 'APPROVED') {
        return PaymentResult(
          success: true,
          paymentId: result!.subscriptionId,
          message: '구독이 시작되었습니다.',
        );
      }

      throw Exception('구독 신청이 취소되었습니다.');
    } catch (e) {
      print('PayPal 구독 오류: $e');
      return PaymentResult(
        success: false,
        paymentId: '',
        message: '구독 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  String _getPlanId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus:
        return PLUS_PLAN_ID;
      case SubscriptionTier.premium:
        return PREMIUM_PLAN_ID;
      case SubscriptionTier.premiumTrial:
        return PREMIUM_TRIAL_PLAN_ID;
      default:
        throw Exception('Invalid subscription tier');
    }
  }

  // 구독 검증
  Future<void> _verifySubscription({
    required String subscriptionId,
    required SubscriptionTier tier,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPayPalSubscription');
      final result = await callable.call({
        'subscriptionId': subscriptionId,
        'tier': tier.name,
      });

      if (!result.data['success']) {
        throw Exception(result.data['message']);
      }
    } catch (e) {
      print('구독 검증 오류: $e');
      throw Exception('구독 검증 실패');
    }
  }
} 