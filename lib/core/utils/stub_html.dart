// 비 웹 환경을 위한 스텁 구현
// dart:html 대신 사용됩니다

class Element {
  String? id;
  String? className;
  String? innerHtml;
  
  void setAttribute(String name, String value) {}
  void setProperty(String name, String value) {}
  set style(dynamic style) {}
}

class IFrameElement extends Element {
  String? src;
  bool allowFullscreen = false;
  
  Stream<dynamic> get onLoad => Stream.empty();
}

class DocumentFragment {}

class Window {
  dynamic document;
  dynamic navigator;
}

Window get window => Window();

T querySelector<T>(String selector) => null as T;

class StylePropertyMapReadonly {}

class CssStyleDeclaration {
  String? width;
  String? height;
  String? border;
}

extension StyleExtension on Element {
  CssStyleDeclaration get style => CssStyleDeclaration();
}

class Event {} 