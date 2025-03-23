// 웹이 아닌 플랫폼을 위한 스텁 파일
// dart:html의 일부 클래스를 스텁으로 제공합니다

class IFrameElement {
  String src = '';
  String style = '';
  String id = '';
  String srcdoc = '';
  bool allowFullscreen = false;
  String allow = '';
  
  set width(String value) {}
  set height(String value) {}
  set border(String value) {}
}

class DivElement {
  String id = '';
  String style = '';
  
  void append(dynamic child) {}
}

class ScriptElement {
  String src = '';
  String type = '';
  bool async = false;
  
  // 이벤트 핸들러
  void set onLoad(Function handler) {}
  void set onError(Function handler) {}
  
  // 속성 설정
  dynamic get onLoad => null;
  dynamic get onError => null;
}

class Document {
  Element createElement(String tag) {
    return Element();
  }
  
  Element? getElementById(String id) {
    return null;
  }
  
  Element get body => Element();
  Element get head => Element();
  
  List<Element> getElementsByTagName(String tagName) {
    return [];
  }
}

class Element {
  List<Element> children = [];
  String id = '';
  String style = '';
  String src = '';
  
  void appendChild(Element child) {}
  void setAttribute(String name, String value) {}
  void removeChild(Element child) {}
  void append(dynamic child) {}
  void remove() {}
}

class StringStyle {
  set width(String value) {}
  set height(String value) {}
  set border(String value) {}
  set overflow(String value) {}
  set background(String value) {}
  set position(String value) {}
  set top(String value) {}
  set left(String value) {}
}

Document document = Document();

class PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic factory) {}
}

PlatformViewRegistry platformViewRegistry = PlatformViewRegistry(); 