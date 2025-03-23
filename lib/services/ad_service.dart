import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_service.dart';
import 'package:provider/provider.dart';

/// 광고 위치 열거형
enum AdPosition { top, bottom, inline }

/// 광고 크기 열거형
enum AdBannerSize { banner, largeBanner, mediumRectangle }

/// 광고 유형 열거형
enum AdType { banner, interstitial, rewarded }

/// 광고 관련 서비스를 제공하는 클래스
class AdService extends ChangeNotifier {
  // 싱글톤 패턴 구현
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Google AdMob 테스트 광고 ID (개발 중에만 사용)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Google AdSense 테스트 ID (개발 중에만, 로컬 테스트용)
  static const String _testAdSenseClientId = 'ca-pub-3940256099942544';
  static const String _testAdSenseAdUnitId = '7259870550';

  // 실제 배포용 광고 ID
  static const String _appId = 'ca-app-pub-1075071967728463~8648332543';
  static const String _bannerAdUnitId = 'ca-app-pub-1075071967728463/2667246118'; // PDF Banner 광고 ID
  static const String _interstitialAdUnitId = ''; // 전면 광고 ID (아직 생성 안됨)
  static const String _rewardedAdUnitId = 'ca-app-pub-1075071967728463/8917793841'; // 리워드 광고 ID
  static const String _adSenseClientId = 'ca-pub-1075071967728463';
  static const String _adSenseAdUnitId = '2667246118'; // PDF 배너 광고와 동일한 ID 사용

  // 마지막 전면 광고 표시 시간
  DateTime _lastInterstitialAdTime = DateTime.now().subtract(const Duration(hours: 1));
  // 전면 광고 객체
  InterstitialAd? _interstitialAd;
  // 보상형 광고 객체
  RewardedAd? _rewardedAd;
  // 보상형 광고 로드 완료 여부
  bool _isRewardedAdLoaded = false;
  // 배너 광고 객체
  BannerAd? _bannerAd;
  // 광고가 로드되었는지 여부
  bool _isAdLoaded = false;
  
  // 게터
  BannerAd? get bannerAd => _bannerAd;
  bool get isAdLoaded => _isAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  
  /// 서비스 초기화
  Future<void> initialize() async {
    // 웹 플랫폼이 아닌 경우에만 광고 로드
    if (!kIsWeb) {
      // MobileAds는 main.dart에서 이미 초기화했으므로 광고만 로드합니다
      
      // 배너 광고 로드
      _loadBannerAd();
      
      // 보상형 광고 미리 로드
      _loadRewardedAd();
    }
  }
  
  /// 배너 광고 로드
  void _loadBannerAd() {
    if (kIsWeb) return; // 웹에서는 실행하지 않음
    
    _bannerAd = BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          debugPrint('배너 광고 로드 실패: ${error.message}');
          notifyListeners();
          
          // 5초 후 다시 시도
          Future.delayed(const Duration(seconds: 5), () {
            _loadBannerAd();
          });
        },
      ),
    );
    
    _bannerAd?.load();
  }
  
  /// 보상형 광고 로드
  Future<bool> _loadRewardedAd() async {
    if (kIsWeb) return false; // 웹에서는 실행하지 않음
    if (_isRewardedAdLoaded) return true; // 이미 로드된 경우
    
    Completer<bool> completer = Completer<bool>();
    
    _isRewardedAdLoaded = false;
    notifyListeners();
    
    RewardedAd.load(
      adUnitId: getRewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          
          // 광고 닫힘 콜백 설정
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              // 광고가 닫히면 새 광고 로드
              _isRewardedAdLoaded = false;
              notifyListeners();
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              // 표시 실패 시 정리
              _isRewardedAdLoaded = false;
              notifyListeners();
              ad.dispose();
              _loadRewardedAd();
            },
          );
          
          notifyListeners();
          completer.complete(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdLoaded = false;
          notifyListeners();
          debugPrint('보상형 광고 로드 실패: ${error.message}');
          
          // 30초 후 다시 시도
          Future.delayed(const Duration(seconds: 30), () {
            _loadRewardedAd();
          });
          
          completer.complete(false);
        },
      ),
    );
    
    return completer.future;
  }
  
  /// 보상형 광고 표시
  /// [onRewarded] 보상 지급 시 호출될 콜백
  /// 반환값: 광고 표시 성공 여부
  Future<bool> showRewardedAd(Function(RewardItem reward) onRewarded) async {
    if (kIsWeb) return false; // 웹에서는 실행하지 않음
    
    // 광고가 로드되지 않은 경우 로드 시도
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      final loaded = await _loadRewardedAd();
      if (!loaded) return false;
    }
    
    // 이미 다른 광고가 표시 중인지 확인
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // bool isAdShowing = prefs.getBool('is_ad_showing') ?? false;
    // if (isAdShowing) return false;
    
    // 광고 표시 플래그 설정
    // await prefs.setBool('is_ad_showing', true);
    
    _rewardedAd!.show(onUserEarnedReward: (_, reward) {
      // 사용자에게 보상 지급
      onRewarded(reward);
    });
    
    return true;
  }
  
  /// 구독 상태에 따라 광고를 표시해야 하는지 확인
  Future<bool> shouldShowAds(BuildContext context) async {
    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      return !subscriptionService.hasActiveSubscription;
    } catch (e) {
      // Provider를 찾지 못한 경우나 다른 오류가 발생한 경우
      return true; // 기본적으로 광고 표시
    }
  }
  
  /// 배너 광고 ID 반환
  static String getBannerAdUnitId() {
    if (kDebugMode) {
      return _testBannerAdUnitId; // 개발 중에는 테스트 ID 사용
    }
    return _bannerAdUnitId.isNotEmpty ? _bannerAdUnitId : _testBannerAdUnitId;
  }
  
  /// 전면 광고 ID 반환
  static String getInterstitialAdUnitId() {
    if (kDebugMode) {
      return _testInterstitialAdUnitId; // 개발 중에는 테스트 ID 사용
    }
    return _interstitialAdUnitId.isNotEmpty ? _interstitialAdUnitId : _testInterstitialAdUnitId;
  }
  
  /// 보상형 광고 ID 반환
  static String getRewardedAdUnitId() {
    if (kDebugMode) {
      return _testRewardedAdUnitId; // 개발 중에는 테스트 ID 사용
    }
    return _rewardedAdUnitId;
  }
  
  /// AdSense 클라이언트 ID 얻기
  static String getAdSenseClientId() {
    if (kDebugMode) {
      // 테스트용 클라이언트 ID
      return 'ca-pub-3940256099942544';
    } else {
      // 실제 애드센스 클라이언트 ID
      return 'ca-pub-3940256099942544';
    }
  }
  
  /// AdSense 광고 유닛 ID 얻기
  static String getAdSenseAdUnitId() {
    if (kDebugMode) {
      // 테스트용 광고 유닛 ID
      return '6300978111';
    } else {
      // 실제 광고 유닛 ID
      return '6300978111';
    }
  }
  
  /// 광고 ID 설정 (앱 초기화 시 호출)
  static void setAdIds({
    String? bannerAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
    String? adSenseClientId,
    String? adSenseAdUnitId,
  }) {
    // 이미 상수로 설정되어 있으므로 수정하지 않음
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // PDF 뷰어 내부에서 광고 로드 가능 여부 확인
  bool isAdAvailable(AdType adType) {
    // 개발 환경에서는 항상 광고 가능으로 처리
    if (kDebugMode) {
      return true;
    }
    
    switch (adType) {
      case AdType.banner:
        return kIsWeb ? true : _isAdLoaded;
      case AdType.interstitial:
        return _interstitialAd != null;
      case AdType.rewarded:
        return _isRewardedAdLoaded;
      default:
        return false;
    }
  }
  
  // 광고 타입 가져오기
  AdBannerSize getBannerSizeForScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 화면 너비에 따라 광고 크기 결정
    if (screenWidth > 900) {
      return AdBannerSize.mediumRectangle;
    } else if (screenWidth > 600) {
      return AdBannerSize.largeBanner;
    } else {
      return AdBannerSize.banner;
    }
  }
} 