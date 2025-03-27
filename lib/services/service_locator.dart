import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'performance_service.dart';
import 'remote_config_service.dart';
import 'storage_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'ads_service.dart';
import 'in_app_purchase_service.dart';
import 'subscription_service.dart';
import 'api_key_service.dart';
import 'ai_service.dart';
import 'pdf/pdf_service.dart';
import 'firebase_service.dart';
import '../domain/repositories/pdf_repository.dart';
import '../data/repositories/pdf_repository_impl.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secureStorage;
  late final FirebaseAuth _auth;
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;
  late final FirebaseRemoteConfig _remoteConfig;
  late final FirebaseStorage _storage;
  late final FirebaseFirestore _firestore;
  late final FlutterLocalNotificationsPlugin _notifications;
  late final InAppPurchase _inAppPurchase;

  // 서비스 인스턴스
  late final AuthService authService;
  late final AnalyticsService analyticsService;
  late final CrashlyticsService crashlyticsService;
  late final PerformanceService performanceService;
  late final RemoteConfigService remoteConfigService;
  late final StorageService storageService;
  late final DatabaseService databaseService;
  late final NotificationService notificationService;
  late final AdsService adsService;
  late final InAppPurchaseService inAppPurchaseService;
  late final SubscriptionService subscriptionService;
  late final ApiKeyService apiKeyService;
  late final AIService aiService;
  late final FirebaseService firebaseService;
  late final PDFRepository pdfRepository;
  late final PDFService pdfService;

  Future<void> initialize() async {
    // 기본 서비스 초기화
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
    _auth = FirebaseAuth.instance;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _performance = FirebasePerformance.instance;
    _remoteConfig = FirebaseRemoteConfig.instance;
    _storage = FirebaseStorage.instance;
    _firestore = FirebaseFirestore.instance;
    _notifications = FlutterLocalNotificationsPlugin();
    _inAppPurchase = InAppPurchase.instance;

    // 서비스 인스턴스 생성
    authService = AuthService(_auth);
    analyticsService = AnalyticsService(_analytics);
    crashlyticsService = CrashlyticsService(_crashlytics);
    performanceService = PerformanceService(_performance);
    remoteConfigService = RemoteConfigService(_remoteConfig);
    storageService = StorageService(_storage);
    databaseService = DatabaseService(_firestore);
    notificationService = NotificationService(_notifications);
    adsService = AdsService(isTestMode: true);
    inAppPurchaseService = InAppPurchaseService(_inAppPurchase);
    subscriptionService = SubscriptionService(_prefs);
    apiKeyService = ApiKeyService(_secureStorage);
    aiService = AIService(
      apiKey: await apiKeyService.getApiKey('openai_api_key') ?? '',
    );
    firebaseService = FirebaseService();
    pdfRepository = PDFRepositoryImpl(firebaseService, _prefs);
    pdfService = PDFServiceImpl();

    // 서비스 초기화
    await Future.wait([
      authService.initialize(),
      analyticsService.initialize(),
      crashlyticsService.initialize(),
      performanceService.initialize(),
      remoteConfigService.initialize(),
      storageService.initialize(),
      databaseService.initialize(),
      notificationService.initialize(),
      adsService.initialize(),
      inAppPurchaseService.initialize(),
      subscriptionService.initialize(),
      apiKeyService.initialize(),
      aiService.initialize(),
    ]);
  }

  void dispose() {
    // 서비스 정리
    adsService.disposeAllAds();
    inAppPurchaseService.dispose();
    pdfService.dispose();
  }
} 