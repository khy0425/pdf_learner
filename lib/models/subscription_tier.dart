import 'package:cloud_firestore/cloud_firestore.dart';
import './feature.dart';  // Feature enum import만 유지

enum SubscriptionTier {
  guest([
    Feature.pdfViewer,
    Feature.basicSearch,
    Feature.basicAISummary,
    Feature.basicQuiz,
  ]),
  
  basic([
    Feature.pdfViewer,
    Feature.basicSearch,
    Feature.basicAISummary,
    Feature.basicQuiz,
    Feature.bookmark,
    Feature.basicStudyNote,
  ]),
  
  plus([
    Feature.pdfViewer,
    Feature.basicSearch,
    Feature.advancedSearch,
    Feature.bookmark,
    Feature.basicStudyNote,
    Feature.advancedAISummary,
    Feature.aiQuiz,
    Feature.highlightSync,
    Feature.cloudStorage,
    Feature.adFree,
  ]),
  
  premium([
    Feature.pdfViewer,
    Feature.advancedSearch,
    Feature.bookmark,
    Feature.advancedStudyNote,
    Feature.unlimitedAISummary,
    Feature.unlimitedQuiz,
    Feature.multiDeviceSync,
    Feature.statsAnalysis,
    Feature.prioritySupport,
    Feature.customThemes,
    Feature.adFree,
  ]),
  premiumTrial([
    Feature.pdfViewer,
    Feature.advancedSearch,
    Feature.bookmark,
    Feature.advancedStudyNote,
    Feature.unlimitedAISummary,
    Feature.unlimitedQuiz,
    Feature.multiDeviceSync,
    Feature.statsAnalysis,
    Feature.prioritySupport,
    Feature.customThemes,
    Feature.adFree,
  ]);

  final List<Feature> features;
  const SubscriptionTier(this.features);

  bool hasFeature(Feature feature) {
    return features.contains(feature);
  }

  // AI 기능 일일 사용 한도
  Map<Feature, int> get dailyAILimits {
    switch (this) {
      case SubscriptionTier.guest:
        return {
          Feature.basicAISummary: 1,  // 일일 1회
          Feature.basicQuiz: 1,       // 일일 1회
        };
      case SubscriptionTier.basic:
        return {
          Feature.basicAISummary: 3,  // 일일 3회
          Feature.basicQuiz: 3,       // 일일 3회
        };
      case SubscriptionTier.plus:
        return {
          Feature.advancedAISummary: 20,  // 일일 20회
          Feature.aiQuiz: 20,             // 일일 20회
        };
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumTrial:  // 프리미엄 체험도 동일한 한도 적용
        return {
          Feature.unlimitedAISummary: 100,  // 일일 100회
          Feature.unlimitedQuiz: 100,       // 일일 100회
        };
    }
  }

  // 한도 초과시 표시할 메시지
  String getLimitExceededMessage(Feature feature) {
    switch (this) {
      case SubscriptionTier.guest:
        return '무료 사용 한도를 초과했습니다.\n회원가입하고 더 많은 기능을 사용해보세요!';
      case SubscriptionTier.basic:
        return '일일 사용 한도를 초과했습니다.\n플러스 회원으로 업그레이드하면 더 많이 사용할 수 있습니다.';
      case SubscriptionTier.plus:
        return '일일 사용 한도를 초과했습니다.\n프리미엄 회원으로 업그레이드하면 더 많이 사용할 수 있습니다.';
      default:
        return '일일 사용 한도를 초과했습니다.';
    }
  }

  // 가격 정보
  int get monthlyPrice {
    switch (this) {
      case SubscriptionTier.guest:
        return 0;
      case SubscriptionTier.basic:
        return 0;
      case SubscriptionTier.plus:
        return 4900;
      case SubscriptionTier.premium:
        return 9900;
      case SubscriptionTier.premiumTrial:
        return 1000;  // $1 체험판
    }
  }

  // 표시 이름
  String get displayName {
    switch (this) {
      case SubscriptionTier.guest:
        return '체험 사용자';
      case SubscriptionTier.basic:
        return '기본 회원';
      case SubscriptionTier.plus:
        return '플러스 회원';
      case SubscriptionTier.premium:
        return '프리미엄 회원';
      case SubscriptionTier.premiumTrial:
        return '프리미엄 체험';
    }
  }

  double get priceUSD {
    switch (this) {
      case SubscriptionTier.guest:
      case SubscriptionTier.basic:
        return 0.0;
      case SubscriptionTier.plus:
        return 3.99;
      case SubscriptionTier.premium:
        return 7.99;
      case SubscriptionTier.premiumTrial:
        return 1.00;
    }
  }

  String get displayPrice {
    switch (this) {
      case SubscriptionTier.guest:
      case SubscriptionTier.basic:
        return '무료';
      case SubscriptionTier.plus:
        return '₩4,900/월 (\$3.99/month)';
      case SubscriptionTier.premium:
        return '₩9,900/월 (\$7.99/month)';
      case SubscriptionTier.premiumTrial:
        return '7일 체험 (\$1)';
    }
  }

  int get dailyAILimit {
    switch (this) {
      case SubscriptionTier.guest:
        return 2;
      case SubscriptionTier.basic:
        return 5;
      case SubscriptionTier.plus:
        return 20;
      case SubscriptionTier.premium:
        return 100;
      case SubscriptionTier.premiumTrial:
        return 100;  // 프리미엄과 동일한 한도
    }
  }

  Set<Feature> get availableFeatures {
    switch (this) {
      case SubscriptionTier.guest:
        return {
          Feature.pdfViewer,
          Feature.basicAISummary,
        };
      case SubscriptionTier.basic:
        return {
          Feature.pdfViewer,
          Feature.basicAISummary,
          Feature.bookmark,
          Feature.basicStudyNote,
        };
      case SubscriptionTier.plus:
        return {
          Feature.pdfViewer,
          Feature.basicSearch,
          Feature.advancedSearch,
          Feature.bookmark,
          Feature.basicStudyNote,
          Feature.advancedAISummary,
          Feature.aiQuiz,
          Feature.highlightSync,
          Feature.cloudStorage,
          Feature.adFree,
        };
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumTrial:  // 프리미엄 체험도 모든 기능 사용 가능
        return Feature.values.toSet();
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.guest:
        return 'AI 기능 체험 가능';
      case SubscriptionTier.basic:
        return '기본적인 학습 기능';
      case SubscriptionTier.plus:
        return '고급 AI 기능 + 클라우드';
      case SubscriptionTier.premium:
        return '모든 프리미엄 기능';
      case SubscriptionTier.premiumTrial:
        return '7일 동안 모든 프리미엄 기능 체험\n이후 월 \$7.99 자동 결제';
    }
  }
}

// Feature enum 정의 제거 (feature.dart로 이동) 