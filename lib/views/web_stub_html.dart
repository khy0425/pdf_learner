/// 웹이 아닌 환경에서 사용할 dart:html 스텁
import 'package:flutter/widgets.dart';

/// IFrame 요소 스텁
class IFrameElement {
  String src = '';
  final style = _ElementStyle();
}

/// 요소 스타일 스텁
class _ElementStyle {
  String height = '';
  String width = '';
  String border = '';
}

/// 웹 스텁에서는 아무 기능도 하지 않는 빈 클래스
class HtmlElement {
  // 스텁 구현
}

/// ui 네임스페이스의 platformViewRegistry 스텁
class PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic Function(int viewId) viewFactory) {
    // 웹이 아닌 환경에서는 아무 동작도 하지 않음
  }
} 