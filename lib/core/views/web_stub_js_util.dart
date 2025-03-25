// 웹이 아닌 플랫폼에서 사용할 스텁 구현

/// PromiseJsImpl 스텁
class PromiseJsImpl {
  static PromiseJsImpl resolve(dynamic value) => PromiseJsImpl();
  static PromiseJsImpl reject(dynamic error) => PromiseJsImpl();
  
  PromiseJsImpl then(Function(dynamic) onFulfilled, [Function? onRejected]) {
    return PromiseJsImpl();
  }
  
  PromiseJsImpl catchError(Function onError) {
    return PromiseJsImpl();
  }
  
  PromiseJsImpl whenComplete(Function action) {
    return PromiseJsImpl();
  }

  Future<T> toFuture<T>() async {
    return null as T;
  }

  static Future<T> resolveToFuture<T>(dynamic value) async {
    return value as T;
  }

  static Future<T> rejectToFuture<T>(dynamic error) async {
    throw error;
  }
}

dynamic callMethod(dynamic o, String method, List<dynamic> args) {
  throw UnimplementedError('js_util.callMethod() is only supported on web');
}

dynamic getProperty(dynamic o, String name) {
  throw UnimplementedError('js_util.getProperty() is only supported on web');
}

void setProperty(dynamic o, String name, dynamic value) {
  throw UnimplementedError('js_util.setProperty() is only supported on web');
}

dynamic newObject() {
  throw UnimplementedError('js_util.newObject() is only supported on web');
}

bool hasProperty(dynamic o, String name) {
  throw UnimplementedError('js_util.hasProperty() is only supported on web');
}

Future<T> promiseToFuture<T>(dynamic promise) async {
  throw UnimplementedError('js_util.promiseToFuture() is only supported on web');
}

T jsify<T>(dynamic object) {
  return object as T;
}

T dartify<T>(dynamic object) {
  return object as T;
} 