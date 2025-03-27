// 웹이 아닌 환경에서 사용될 stub 파일
// dart:ui_web을 모방하는 stub 클래스

class PlatformViewRegistry {
  dynamic registerViewFactory(String viewTypeId, dynamic Function(int viewId) viewFactory) {
    return null;
  }
}

final platformViewRegistry = PlatformViewRegistry(); 