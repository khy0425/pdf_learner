/// dart:js_util의 스텁 구현
/// 네이티브 앱에서 웹 코드에 접근할 때 사용됩니다.

dynamic callMethod(Object? target, String method, List<dynamic> args) {
  return null;
}

T getProperty<T>(Object object, String name) {
  return null as T;
}

void setProperty(Object object, String name, dynamic value) {}

Object newObject() {
  return Object();
}

dynamic jsify(Object? object) {
  return object;
}

T dartify<T>(dynamic object) {
  return object as T;
} 