/// dart:js_util을 대체하기 위한 비웹 환경 스텁 클래스

T getProperty<T>(Object object, String name) {
  throw UnimplementedError('js_util.getProperty 실행 불가: 웹 환경이 아닙니다.');
}

void setProperty(Object object, String name, Object? value) {
  throw UnimplementedError('js_util.setProperty 실행 불가: 웹 환경이 아닙니다.');
}

Object callMethod(Object object, String method, List<Object?> args) {
  throw UnimplementedError('js_util.callMethod 실행 불가: 웹 환경이 아닙니다.');
}

Future<T> promiseToFuture<T>(Object jsPromise) {
  throw UnimplementedError('js_util.promiseToFuture 실행 불가: 웹 환경이 아닙니다.');
} 