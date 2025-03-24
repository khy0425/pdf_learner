import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../widgets/web_ad_widget.dart';
import '../widgets/mobile_ad_widget.dart';
import '../services/subscription_service.dart';
import 'package:provider/provider.dart';

/// 플랫폼에 따라 적절한 광고 위젯을 선택하는 컴포넌트
class PlatformAdWidget extends StatelessWidget {
  /// 광고를 표시할 위치 (기본값은 하단)
  final AdPosition position;
  
  /// 광고 크기 (기본값은 배너)
  final AdBannerSize size;
  
  /// 광고 유형 (기본값은 배너)
  final AdType adType;
  
  /// 광고 ID (기본값은 null, null이면 서비스에서 기본값 사용)
  final String? adUnitId;

  const PlatformAdWidget({
    Key? key,
    this.position = AdPosition.bottom,
    this.size = AdBannerSize.banner,
    this.adType = AdType.banner,
    this.adUnitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 구독 서비스에서 구독 상태 확인
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    // 구독 중인 경우 광고를 표시하지 않음
    if (subscriptionService.hasActiveSubscription) {
      return const SizedBox.shrink();
    }
    
    // 화면 크기에 따라 광고 크기 조정
    final screenWidth = MediaQuery.of(context).size.width;
    AdBannerSize adSize = size;
    
    // 화면 너비가 600px보다 크면 더 큰 배너 사용
    if (screenWidth > 600 && size == AdBannerSize.banner) {
      adSize = AdBannerSize.largeBanner;
    }
    
    // 플랫폼에 따라 다른 광고 위젯 반환
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: kIsWeb 
          ? WebAdWidget(
              position: position,
              size: adSize,
              adType: adType,
              adUnitId: adUnitId,
            )
          : MobileAdWidget(
              position: position,
              size: adSize,
              adType: adType,
              adUnitId: adUnitId,
            ),
      ),
    );
  }
} 