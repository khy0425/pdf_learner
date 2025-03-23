import 'package:flutter/material.dart';
import '../services/ad_service.dart';  // AdPosition과 AdBannerSize를 위한 임포트 추가
import 'platform_ad_widget.dart';

/// 모바일 환경의 광고 위젯
class MobileAdWidget extends StatelessWidget {
  /// 광고를 표시할 위치
  final AdPosition position;
  
  /// 광고 크기
  final AdBannerSize size;
  
  /// 광고 ID
  final String? adUnitId;

  const MobileAdWidget({
    Key? key,
    required this.position,
    required this.size,
    this.adUnitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 모바일 광고 위젯 (간단한 구현)
    return Container(
      width: double.infinity,
      height: _getHeight(),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border(
          top: position == AdPosition.bottom ? const BorderSide(color: Colors.grey, width: 0.5) : BorderSide.none,
          bottom: position == AdPosition.top ? const BorderSide(color: Colors.grey, width: 0.5) : BorderSide.none,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '광고 영역',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case AdBannerSize.banner:
        return 50;
      case AdBannerSize.largeBanner:
        return 100;
      case AdBannerSize.mediumRectangle:
        return 250;
      default:
        return 50;
    }
  }
} 