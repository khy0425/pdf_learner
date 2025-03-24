import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/web_ad_service.dart';

/// 웹 플랫폼을 위한 배너 광고 위젯
class WebAdBannerWidget extends StatelessWidget {
  const WebAdBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 웹 플랫폼이 아니면 표시하지 않음
    if (!kIsWeb) return const SizedBox.shrink();
    
    return Consumer<WebAdService>(
      builder: (context, webAdService, child) {
        if (!webAdService.isInitialized) {
          // 초기화되지 않았으면 초기화 시도
          webAdService.initialize();
          return const SizedBox(
            height: 90,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        
        // 웹 광고 위젯 생성
        return webAdService.createWebAdWidget(context);
      },
    );
  }
} 