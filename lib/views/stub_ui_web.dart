// 웹이 아닌 플랫폼을 위한 스텁 파일
// dart:ui_web의 일부 기능을 스텁으로 제공합니다

class BrowserEngine {
  static const String blink = 'blink';
  static const String webkit = 'webkit';
}

String get browserEngine => BrowserEngine.blink;

class ViewEmbedder {
  static void registerViewFactory(String viewTypeId, dynamic viewFactory) {}
}

class PlatformViewRegistryImpl {
  void registerViewFactory(String viewTypeId, dynamic viewFactory) {}
}

PlatformViewRegistryImpl platformViewRegistry = PlatformViewRegistryImpl(); 