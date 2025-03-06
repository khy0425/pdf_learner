import '../services/subscription_service.dart';
import '../models/feature.dart';
import '../services/pdf_service.dart';
import '../providers/pdf_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsageLimiter {
  final SubscriptionService _subscriptionService;
  final PDFService _pdfService;
  
  UsageLimiter(this._subscriptionService, this._pdfService);

  Future<bool> canUseFeature(Feature feature) async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      final tier = subscription['tier'] as SubscriptionTier;
      final features = subscription['features'] as Map<String, dynamic>;
      
      // 해당 기능이 구독 티어에서 사용 가능한지 확인
      if (!features.containsKey(feature.name)) {
        return false;
      }
      
      // 일일 사용량 제한 확인
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usage = await _getFeatureUsage(feature, today);
      
      // 기본적으로 각 기능별 일일 제한은 5회로 설정
      final limit = 5;
      
      return usage < limit;
    } catch (e) {
      print('기능 사용 가능 여부 확인 중 오류: $e');
      return false;
    }
  }

  Future<bool> canUseAIFeature() async {
    try {
      final tier = await _subscriptionService.getCurrentTier();
      final currentUsage = await _subscriptionService.getDailyAIUsage();
      
      // 각 티어별 AI 사용 한도 설정
      int limit;
      switch (tier) {
        case SubscriptionTier.free:
        case SubscriptionTier.guest:
          limit = 2;
          break;
        case SubscriptionTier.basic:
          limit = 5;
          break;
        case SubscriptionTier.plus:
          limit = 20;
          break;
        case SubscriptionTier.premium:
        case SubscriptionTier.premiumTrial:
        case SubscriptionTier.enterprise:
          limit = 100;
          break;
      }
      
      return currentUsage < limit;
    } catch (e) {
      print('AI 사용량 체크 오류: $e');
      return false;
    }
  }

  Future<void> incrementAIUsage() async {
    try {
      // AI 관련 기능 사용량 증가
      await _subscriptionService.incrementUsage('basicAISummary');
      await _subscriptionService.incrementUsage('aiQuiz');
    } catch (e) {
      print('AI 사용량 증가 중 오류: $e');
    }
  }

  Future<Map<String, dynamic>> getUsageStatus() async {
    final tier = await _subscriptionService.getCurrentTier();
    final currentUsage = await _subscriptionService.getDailyAIUsage();
    
    // 각 티어별 AI 사용 한도 설정
    int limit;
    switch (tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.guest:
        limit = 2;
        break;
      case SubscriptionTier.basic:
        limit = 5;
        break;
      case SubscriptionTier.plus:
        limit = 20;
        break;
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumTrial:
      case SubscriptionTier.enterprise:
        limit = 100;
        break;
    }
    
    return {
      'currentUsage': currentUsage,
      'limit': limit,
      'remainingUsage': limit - currentUsage,
      'features': ['pdfViewer', 'basicAISummary', 'basicQuiz'],
    };
  }

  Future<void> incrementUsage(Feature feature) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageRef = FirebaseFirestore.instance
        .collection('usage')
        .doc(_subscriptionService.userId)
        .collection('daily')
        .doc(today);

    await usageRef.set({
      feature.name: FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> _getFeatureUsage(Feature feature, String date) async {
    final doc = await FirebaseFirestore.instance
        .collection('usage')
        .doc(_subscriptionService.userId)
        .collection('daily')
        .doc(date)
        .get();
    
    return doc.data()?[feature.name] ?? 0;
  }
  
  /// PDF 파일이 현재 구독 티어에서 사용 가능한지 확인
  Future<Map<String, dynamic>> canUsePdf(PdfFileInfo pdfFile) async {
    try {
      final tier = await _subscriptionService.getCurrentTier();
      return await _pdfService.checkPdfUsability(pdfFile, tier);
    } catch (e) {
      print('PDF 사용 가능 여부 확인 중 오류: $e');
      return {
        'usable': false,
        'reason': 'error',
        'message': '파일 확인 중 오류가 발생했습니다. 다시 시도해주세요.',
      };
    }
  }
  
  /// 프리미엄 기능 사용 시 업그레이드 메시지 반환
  String getUpgradeMessage(SubscriptionTier currentTier) {
    switch (currentTier) {
      case SubscriptionTier.guest:
        return '이 기능은 무료 사용자에게 제한됩니다.\n회원가입하고 더 많은 기능을 사용해보세요!';
      case SubscriptionTier.basic:
        return '이 기능은 기본 회원에게 제한됩니다.\n플러스 또는 프리미엄 회원으로 업그레이드하세요.';
      case SubscriptionTier.plus:
        return '이 기능은 플러스 회원에게 제한됩니다.\n프리미엄 회원으로 업그레이드하세요.';
      default:
        return '이 기능을 사용할 수 없습니다.';
    }
  }
} 