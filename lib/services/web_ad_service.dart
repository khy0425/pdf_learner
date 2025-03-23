import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import 'ad_service.dart';
import '../widgets/web_ad_widget.dart';

/// 웹 광고 관련 서비스
class WebAdService extends ChangeNotifier {
  // 광고 로드 상태
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  bool _isInitialized = false;
  String? _error;
  
  // Google AdSense 계정 정보
  static const String _publisherId = 'ca-pub-3940256099942544';
  
  // 광고 ID 목록
  static const Map<String, String> _adUnits = {
    'banner': '6300978111',
    'interstitial': '1033173712',
    'rewarded': '5224354917',
  };
  
  // Getters
  bool get isAdLoaded => _isAdLoaded;
  bool get isAdShowing => _isAdShowing;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  // Singleton
  static final WebAdService _instance = WebAdService._internal();
  factory WebAdService() => _instance;
  WebAdService._internal();
  
  /// Google AdSense 초기화
  Future<void> initialize() async {
    if (!kIsWeb) return;
    if (_isInitialized) return;
    
    // 이미 초기화 되었는지 확인
    try {
      // 이미 window에 adInitialized 변수가 존재하는지 확인
      final bool alreadyInitialized = js.context.hasProperty('adInitialized') &&
                                     js.context['adInitialized'] == true;
      
      if (alreadyInitialized) {
        debugPrint('AdSense가 이미 초기화되어 있습니다.');
        _isInitialized = true;
        _isAdLoaded = true;
        notifyListeners();
        return;
      }

      final adSenseClientId = AdService.getAdSenseClientId();
      
      // AdSense 스크립트 로드를 위한 지연
      await Future.delayed(const Duration(milliseconds: 500));
      
      // console에 디버그 로그 추가 및 초기화 상태 명확히 확인
      js.context.callMethod('eval', ['''
        console.log('AdSense 초기화 시작...');
        if (typeof window.adInitialized === 'undefined' || window.adInitialized !== true) {
          console.log('AdSense 초기화 진행 중...');
          window.adInitialized = true;
          
          // AdSense 스크립트가 이미 로드되었는지 확인
          if (typeof adsbygoogle === 'undefined') {
            adsbygoogle = [];
          }
        
          if (!window.adPageLevelEnabled) {
            // 페이지 레벨 광고는 비활성화 (오류 방지)
            window.adPageLevelEnabled = true;
            console.log('AdSense 페이지 레벨 광고는 비활성화됨');
          }
          console.log('AdSense 초기화 완료');
        } else {
          console.log('AdSense가 이미 초기화되어 있습니다.');
        }
      ''']);
      
      _isInitialized = true;
      _isAdLoaded = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('AdSense 초기화 오류: $_error');
      
      // 오류 발생 시 재시도 횟수 제한
      if (!_isInitialized) {
        await Future.delayed(const Duration(seconds: 5));
        return initialize();
      }
    }
  }
  
  /// 광고 로드 요청
  Future<bool> loadAd(String adUnitType) async {
    if (!kIsWeb) return false;
    
    final SubscriptionService subscriptionService = SubscriptionService();
    
    // 구독 중인 사용자에게는 광고를 표시하지 않음
    if (subscriptionService.hasActiveSubscription) {
      return false;
    }
    
    try {
      final adUnitId = _adUnits[adUnitType];
      if (adUnitId == null) {
        debugPrint('알 수 없는 광고 유닛 타입: $adUnitType');
        return false;
      }
      
      // 광고 로드 요청
      js.context.callMethod('eval', ['''
        (adsbygoogle = window.adsbygoogle || []).push({});
      ''']);
      
      _isAdLoaded = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('광고 로드 오류: $_error');
      return false;
    }
  }
  
  /// 웹 광고 위젯 생성
  Widget createWebAdWidget(BuildContext context) {
    // 구독 상태에 따라 광고 표시 여부 결정
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    if (subscriptionService.hasActiveSubscription) {
      return const SizedBox.shrink();
    }
    
    return const WebAdWidget(
      position: AdPosition.bottom,
      size: AdBannerSize.banner,
    );
  }
  
  /// 전면 광고 표시
  Future<bool> showInterstitialAd() async {
    if (!kIsWeb) return false;
    
    final SubscriptionService subscriptionService = SubscriptionService();
    
    // 구독 중인 사용자에게는 광고를 표시하지 않음
    if (subscriptionService.hasActiveSubscription) {
      return false;
    }
    
    if (!_isAdLoaded) {
      await loadAd('interstitial');
    }
    
    try {
      _isAdShowing = true;
      notifyListeners();
      
      // 실제 광고 표시 코드는 HTML/JS 측에서 처리해야 함
      // 여기서는 가상의 메소드 호출
      js.context.callMethod('showInterstitialAd', []);
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('전면 광고 표시 오류: $_error');
      _isAdShowing = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 보상형 광고 표시
  Future<bool> showRewardedAd(Function onRewarded) async {
    if (!kIsWeb) return false;
    
    if (!_isAdLoaded) {
      await loadAd('rewarded');
    }
    
    try {
      _isAdShowing = true;
      notifyListeners();
      
      // 보상 함수를 글로벌 스코프에 등록
      js.context['onAdRewarded'] = (_) {
        onRewarded();
      };
      
      // 실제 광고 표시 코드는 HTML/JS 측에서 처리해야 함
      js.context.callMethod('showRewardedAd', []);
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('보상형 광고 표시 오류: $_error');
      _isAdShowing = false;
      notifyListeners();
      return false;
    }
  }
} 