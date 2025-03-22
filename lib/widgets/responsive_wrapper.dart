import 'package:flutter/material.dart';
import 'package:pdf_learner_v2/config/platform_config.dart';

/// 반응형 레이아웃을 구현하기 위한 래퍼 위젯
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  
  const ResponsiveWrapper({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final screenType = PlatformConfig().getScreenSizeType(context);
    
    switch (screenType) {
      case ScreenSizeType.mobile:
        return mobile;
      case ScreenSizeType.tablet:
        return tablet ?? mobile;
      case ScreenSizeType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSizeType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// 반응형 값을 제공하는 유틸리티 클래스
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;
  
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });
  
  /// 현재 화면 크기에 맞는 값을 반환
  T getValue(BuildContext context) {
    final screenType = PlatformConfig().getScreenSizeType(context);
    
    switch (screenType) {
      case ScreenSizeType.mobile:
        return mobile;
      case ScreenSizeType.tablet:
        return tablet ?? mobile;
      case ScreenSizeType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSizeType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// 반응형 위젯 확장 기능을 제공하는 확장 메서드
extension ResponsiveExtension on Widget {
  /// 현재 위젯을 반응형으로 래핑합니다
  Widget responsive({
    required BuildContext context,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
    EdgeInsets? largeDesktopPadding,
    double? mobileWidth,
    double? tabletWidth,
    double? desktopWidth,
    double? largeDesktopWidth,
  }) {
    final screenType = PlatformConfig().getScreenSizeType(context);
    
    Widget result = this;
    
    // 패딩 적용
    final padding = switch (screenType) {
      ScreenSizeType.mobile => mobilePadding,
      ScreenSizeType.tablet => tabletPadding ?? mobilePadding,
      ScreenSizeType.desktop => desktopPadding ?? tabletPadding ?? mobilePadding,
      ScreenSizeType.largeDesktop => largeDesktopPadding ?? desktopPadding ?? tabletPadding ?? mobilePadding,
    };
    
    if (padding != null) {
      result = Padding(padding: padding, child: result);
    }
    
    // 너비 제한 적용
    final maxWidth = switch (screenType) {
      ScreenSizeType.mobile => mobileWidth,
      ScreenSizeType.tablet => tabletWidth ?? mobileWidth,
      ScreenSizeType.desktop => desktopWidth ?? tabletWidth ?? mobileWidth,
      ScreenSizeType.largeDesktop => largeDesktopWidth ?? desktopWidth ?? tabletWidth ?? mobileWidth,
    };
    
    if (maxWidth != null) {
      result = Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: result,
      );
    }
    
    return result;
  }
} 