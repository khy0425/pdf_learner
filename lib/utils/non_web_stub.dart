/// 웹이 아닌 환경에서 dart:html과 dart:js를 대체하기 위한 스텁 파일입니다.
/// 이 파일은 웹이 아닌 환경에서 컴파일 오류를 방지하기 위해 사용됩니다.

// 빈 클래스와 함수들을 정의하여 웹 환경에서만 사용되는 코드가 컴파일되도록 합니다.
class Window {
  static dynamic get location => _Location();
  static dynamic get localStorage => <String, String>{};
  static dynamic get navigator => _Navigator();
  static dynamic get history => _History();
  
  void dispatchEvent(dynamic event) {}
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

class Context {
  bool hasProperty(String name) => false;
  void operator []=(String name, dynamic value) {}
  dynamic operator [](String name) => null;
  dynamic callMethod(String name, [List<dynamic>? args]) => null;
}

// 안전한 JS 컨텍스트 접근을 위한 전역 변수
final context = Context();

// 함수를 JS interop으로 변환하는 대체 함수
T allowInterop<T extends Function>(T function) => function; 