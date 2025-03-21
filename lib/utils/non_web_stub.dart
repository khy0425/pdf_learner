/// 웹이 아닌 환경에서 dart:html과 dart:js를 대체하기 위한 스텁 파일입니다.
/// 이 파일은 웹이 아닌 환경에서 컴파일 오류를 방지하기 위해 사용됩니다.

// 빈 클래스와 함수들을 정의하여 웹 환경에서만 사용되는 코드가 컴파일되도록 합니다.
class Window {
  dynamic get location => Location();
  static dynamic get localStorage => <String, String>{};
  static dynamic get navigator => _Navigator();
  static dynamic get history => _History();
  
  void dispatchEvent(dynamic event) {}
  void open(String url, String target) {}
}

class _Location {
  String get href => '';
  set href(String value) {}
}

class _Navigator {
  String get userAgent => '';
}

class _History {
  void back() {}
}

class Document {
  dynamic getElementById(String id) => null;
  dynamic get body => null;
}

class Element {
  List<Element> get children => [];
  dynamic get style => _Style();
  int get clientWidth => 0;
  int get clientHeight => 0;
}

class _Style {
  String get display => '';
  set display(String value) {}
  String get opacity => '';
  set opacity(String value) {}
  String get position => '';
  set position(String value) {}
  String get top => '';
  set top(String value) {}
  String get left => '';
  set left(String value) {}
  String get width => '';
  set width(String value) {}
  String get height => '';
  set height(String value) {}
  String get zIndex => '';
  set zIndex(String value) {}
  String get visibility => '';
  set visibility(String value) {}
  String get backgroundColor => '';
  set backgroundColor(String value) {}
}

class Event {
  Event(String type);
}

// 전역 객체
final window = Window();
final document = Document();

// js 스텁
class JsObject {
  static dynamic jsify(dynamic object) => object;
}

// 빈 컨텍스트 클래스
class JsContext {
  dynamic callMethod(String name, [List<dynamic>? args]) => null;
  dynamic operator [](String key) => null;
  operator []=(String key, dynamic value) {}
  bool hasProperty(String name) => false;
  dynamic get context => null;
}

// js 객체의 스텁 구현
final context = JsContext();

// 함수를 JS interop으로 변환하는 대체 함수
T allowInterop<T extends Function>(T function) => function;

// Web APIs를 지원하지 않는 환경을 위한 스텁 구현
// dart:js 및 dart:html 라이브러리를 지원하지 않는 네이티브 플랫폼에서 사용됨

/// JS 통합을 위한 스텁 함수
class js {
  static JsContext get context => JsContext();
  static dynamic allowInterop(Function function) => function;
}

/// HTML 스텁 클래스
class Blob {
  Blob(List<dynamic> data, [String? type]) {}
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href}) {}
  void setAttribute(String name, String value) {}
  void click() {}
}

class Location {
  String get href => '';
  set href(String value) {}
} 