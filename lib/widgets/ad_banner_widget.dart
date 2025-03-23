import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdService>(
      builder: (context, adService, child) {
        return FutureBuilder<bool>(
          future: adService.shouldShowAds(context),
          builder: (context, snapshot) {
            // 광고를 표시하지 않아야 하는 경우 (프리미엄/베이직 유저)
            if (snapshot.hasData && !snapshot.data!) {
              return const SizedBox.shrink();
            }
            
            // 광고 로딩 중이거나 로드되지 않은 경우
            if (!adService.isAdLoaded || adService.bannerAd == null) {
              return const SizedBox(
                height: 50,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            
            // 광고가 로드되면 표시
            return Container(
              height: 50,
              alignment: Alignment.center,
              child: AdWidget(ad: adService.bannerAd!),
            );
          },
        );
      },
    );
  }
} 