import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// 앱의 환경 변수 및 설정을 관리하는 유틸리티 클래스
class ConfigUtils {
  // PayPal 관련 설정
  static String getPayPalBasicPlanId() {
    final planId = dotenv.env['PAYPAL_BASIC_PLAN_ID'];
    if (planId == null || planId.isEmpty) {
      throw Exception('PayPal 기본 플랜 ID가 설정되지 않았습니다.');
    }
    return planId;
  }

  static String getPayPalPremiumPlanId() {
    final planId = dotenv.env['PAYPAL_PREMIUM_PLAN_ID'];
    if (planId == null || planId.isEmpty) {
      throw Exception('PayPal 프리미엄 플랜 ID가 설정되지 않았습니다.');
    }
    return planId;
  }

  static String getPayPalClientId() {
    final clientId = dotenv.env['PAYPAL_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception('PayPal 클라이언트 ID가 설정되지 않았습니다.');
    }
    return clientId;
  }

  static String getPayPalMerchantId() {
    final merchantId = dotenv.env['PAYPAL_MERCHANT_ID'];
    if (merchantId == null || merchantId.isEmpty) {
      throw Exception('PayPal 판매자 ID가 설정되지 않았습니다.');
    }
    return merchantId;
  }

  // 앱 버전 정보
  static String getAppVersion() {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  // 앱 환경 (dev, staging, prod)
  static String getEnvironment() {
    return dotenv.env['ENVIRONMENT'] ?? 'dev';
  }

  // API 엔드포인트
  static String getApiBaseUrl() {
    final env = getEnvironment();
    switch (env) {
      case 'prod':
        return dotenv.env['API_URL_PROD'] ?? 'https://api.pdflearner.com';
      case 'staging':
        return dotenv.env['API_URL_STAGING'] ?? 'https://staging-api.pdflearner.com';
      default:
        return dotenv.env['API_URL_DEV'] ?? 'https://dev-api.pdflearner.com';
    }
  }

  // Firebase 설정
  static bool isFirebaseEnabled() {
    return (dotenv.env['FIREBASE_ENABLED'] ?? 'true') == 'true';
  }

  // 기타 설정값
  static int getMaxPdfFileSize() {
    return int.parse(dotenv.env['MAX_PDF_FILE_SIZE'] ?? '100'); // MB 단위
  }

  static int getMaxPdfPages() {
    return int.parse(dotenv.env['MAX_PDF_PAGES'] ?? '1000');
  }

  static bool isPremiumFeaturesEnabled() {
    return (dotenv.env['PREMIUM_FEATURES_ENABLED'] ?? 'true') == 'true';
  }
} 