// 웹이 아닌 환경에서 사용될 stub 파일
// dart:html을 모방하는 기본 클래스 정의

class Element {
  void append(dynamic other) {}
}

class IFrameElement extends Element {
  String src = '';
  String width = '';
  String height = '';
  bool allowFullscreen = false;
  
  // style 객체
  final ElementStyle style = ElementStyle();
}

class ElementStyle {
  String width = '';
  String height = '';
  String border = '';
}

class Document {
  Element? body;
  Element? head;
  
  Element? getElementById(String id) => null;
  List<Element> getElementsByTagName(String tagName) => [];
}

// 전역 문서 객체
final document = Document();

/// HTML 모듈을 사용할 수 없는 환경에서 사용하는 스텁 클래스
class AnchorElement {
  String href = '';
  String download = '';
  String target = '';
  
  void click() {}
}

class Blob {
  Blob(List<dynamic> content, [Map<String, String>? options]) {}
}

class window {
  static String createObjectURL(dynamic blob) => '';
  static void open(String url, String target) {}
  static void revokeObjectURL(String url) {}
}

class FileReader {
  dynamic result;
  
  void readAsArrayBuffer(dynamic blob) {}
  
  set onLoadEnd(Function callback) {}
} 