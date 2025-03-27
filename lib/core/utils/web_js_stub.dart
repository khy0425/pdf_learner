/// dart:js를 대체하기 위한 비웹 환경 스텁 클래스

class JsObject {
  dynamic callMethod(String method, [List<dynamic>? args]) {
    throw UnimplementedError('JsObject.callMethod 실행 불가: 웹 환경이 아닙니다.');
  }
  
  dynamic operator [](String property) {
    throw UnimplementedError('JsObject[] 실행 불가: 웹 환경이 아닙니다.');
  }
  
  void operator []=(String property, dynamic value) {
    throw UnimplementedError('JsObject[]= 실행 불가: 웹 환경이 아닙니다.');
  }
}

final JsObject context = JsObject(); 