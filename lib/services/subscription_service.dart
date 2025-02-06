enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise
}

class SubscriptionFeatures {
  static const Map<SubscriptionTier, Map<String, dynamic>> features = {
    SubscriptionTier.free: {
      'dailyQuizLimit': 5,
      'summaryLength': 'short',
      'aiAnalysis': false,
      'exportFeatures': false,
      'collaborationFeatures': false,
    },
    SubscriptionTier.basic: {
      'dailyQuizLimit': 20,
      'summaryLength': 'medium',
      'aiAnalysis': true,
      'exportFeatures': false,
      'collaborationFeatures': false,
      'price': '₩9,900/월',
    },
    SubscriptionTier.premium: {
      'dailyQuizLimit': 100,
      'summaryLength': 'long',
      'aiAnalysis': true,
      'exportFeatures': true,
      'collaborationFeatures': true,
      'price': '₩19,900/월',
    },
    SubscriptionTier.enterprise: {
      'dailyQuizLimit': 'unlimited',
      'summaryLength': 'custom',
      'aiAnalysis': true,
      'exportFeatures': true,
      'collaborationFeatures': true,
      'customSupport': true,
      'price': '별도 문의',
    },
  };
} 