import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// 앱의 환경 변수 및 설정을 관리하는 유틸리티 클래스
class ConfigUtils {
  // PayPal 관련 설정
  static String getPayPalBasicPlanId() {
    // 디버그 모드에서는 테스트 ID 사용, 릴리스 모드에서는 .env에서 로드
    if (kDebugMode) {
      return dotenv.env['PAYPAL_BASIC_PLAN_ID'] ?? 'P-0C773510SU364272XM7SPX6I'; // 테스트 ID
    }
    return dotenv.env['PAYPAL_BASIC_PLAN_ID'] ?? 'P-0C773510SU364272XM7SPX6I';
  }

  static String getPayPalPremiumPlanId() {
    if (kDebugMode) {
      return dotenv.env['PAYPAL_PREMIUM_PLAN_ID'] ?? 'P-2EM77373KV537191YM7SPYNY'; // 테스트 ID
    }
    return dotenv.env['PAYPAL_PREMIUM_PLAN_ID'] ?? 'P-2EM77373KV537191YM7SPYNY';
  }

  static String getPayPalClientId() {
    if (kDebugMode) {
      // 개발 환경용 클라이언트 ID
      return dotenv.env['PAYPAL_CLIENT_ID'] ?? 'AY4xA8BL8YVstPdRZRd_6BM6vhoEGu0ei3UUjOpn0EajAI2FG2yALLnjmniYERxr7R1BpZI0aQy3Xi9w';
    }
    // 프로덕션 환경에서는 .env 파일에서 로드
    return dotenv.env['PAYPAL_CLIENT_ID'] ?? 'AY4xA8BL8YVstPdRZRd_6BM6vhoEGu0ei3UUjOpn0EajAI2FG2yALLnjmniYERxr7R1BpZI0aQy3Xi9w';
  }

  static String getPayPalMerchantId() {
    return dotenv.env['PAYPAL_MERCHANT_ID'] ?? 'RJWUGHMG9C6FQ';
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