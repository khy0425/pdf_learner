/// 스텁 클래스는 웹 환경이 아닐 때 dart:html의 대안으로 사용됩니다.
class Storage {
  void operator []=(String key, String value) {}
  String? operator [](String key) => null;
  void remove(String key) {}
  void clear() {}
}

class Window {
  Storage get localStorage => Storage();
  Storage get sessionStorage => Storage();
}

Window window = Window(); 