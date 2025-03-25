/// 웹이 아닌 환경에서 dart:html과 dart:js를 대체하기 위한 스텁 파일입니다.
/// 이 파일은 웹이 아닌 환경에서 컴파일 오류를 방지하기 위해 사용됩니다.

/// html 네임스페이스의 스텁 파일
/// 웹이 아닌 환경에서 dart:html을 import할 때 사용됩니다.

/// PromiseJsImpl 스텁
import 'dart:async';

class PromiseJsImpl<T> {
  final Future<T> _future;

  PromiseJsImpl([Future<T>? future]) : _future = future ?? Future.value();

  static PromiseJsImpl<T> resolve<T>(T value) {
    return PromiseJsImpl<T>(Future.value(value));
  }

  static PromiseJsImpl<T> reject<T>(dynamic error) {
    return PromiseJsImpl<T>(Future.error(error));
  }

  PromiseJsImpl<R> then<R>(Function(T) onFulfilled, [Function? onRejected]) {
    return PromiseJsImpl<R>(
      _future.then(
        (value) => onFulfilled(value),
        onError: onRejected != null ? (error) => onRejected(error) : null,
      ),
    );
  }

  PromiseJsImpl<T> catchError(Function onError) {
    return PromiseJsImpl<T>(
      _future.catchError((error) => onError(error)),
    );
  }

  PromiseJsImpl<T> whenComplete(Function action) {
    return PromiseJsImpl<T>(
      _future.whenComplete(() => action()),
    );
  }

  Future<T> toFuture() => _future;

  static Future<T> resolveToFuture<T>(PromiseJsImpl<T> promise) => promise.toFuture();
  static Future<T> rejectToFuture<T>(PromiseJsImpl<T> promise) => promise.toFuture();
}

/// html의 window 스텁
class Window {
  Location location = Location();
  Navigator navigator = Navigator();
  Document document = Document();
  
  void alert(String message) {}
  void confirm(String message) {}
  void prompt(String message, String defaultValue) {}
  
  void open(String url, String target, {String? features}) {}
  void postMessage(dynamic message, String targetOrigin, {List<dynamic>? transfer}) {}
  
  void reload() {}
}

/// html의 navigator 스텁
class Navigator {
  String userAgent = '';
  
  void share(Map<String, dynamic> data) {}
}

/// html의 Location 스텁
class Location {
  String href = '';
  String host = '';
  String hostname = '';
  String protocol = '';
  String origin = '';
  String port = '';
  String pathname = '';
  String search = '';
  String hash = '';
  
  void reload() {}
  void replace(String url) {}
  void assign(String url) {}
}

/// html의 Document 스텁
class Document {
  Element body = Element();
  Element head = Element();
  
  Element createElement(String tagName) => Element();
  Element? getElementById(String id) => null;
  List<Element> getElementsByTagName(String tagName) => [];
  List<Element> getElementsByClassName(String className) => [];
  
  Element? querySelector(String selectors) => null;
  List<Element> querySelectorAll(String selectors) => [];
}

/// html의 Element 스텁
class Element {
  String id = '';
  String className = '';
  String innerHTML = '';
  String outerHTML = '';
  
  void append(dynamic child) {}
  void remove() {}
  
  void setAttribute(String name, String value) {}
  String? getAttribute(String name) => null;
  
  void addEventListener(String type, dynamic listener, {bool useCapture = false}) {}
  void removeEventListener(String type, dynamic listener, {bool useCapture = false}) {}
}

/// html의 style 스텁
class Style {
  String display = '';
  String position = '';
  String left = '';
  String top = '';
  String width = '';
  String height = '';
  String opacity = '';
}

/// html의 AnchorElement 스텁
class AnchorElement extends Element {
  String? href;
  
  AnchorElement({this.href});
}

/// html의 TextAreaElement 스텁
class TextAreaElement extends Element {
  String value = '';
  
  void select() {
    print('TextArea select (stub) called');
  }
}

/// html의 FileUploadInputElement 스텁
class FileUploadInputElement extends Element {
  String accept = '';
  bool multiple = false;
  List<File>? files;
  
  Stream<Event> get onChange => _OnChangeStreamController().stream;
}

/// html의 Event 스텁
class Event {
  bool preventDefault() => false;
  bool stopPropagation() => false;
}

/// html의 OnChange 스트림 컨트롤러 스텁
class _OnChangeStreamController {
  Stream<Event> get stream => Stream<Event>.empty();
}

/// html의 파일 스텁
class File {
  String get name => 'stub-file.txt';
  int get size => 0;
  String get type => 'text/plain';
}

/// html의 Blob 스텁
class Blob {
  Blob(List<dynamic> contents, String type) {
    print('Blob (stub) created with type: $type');
  }
}

/// html의 Url 스텁
class Url {
  static String createObjectUrlFromBlob(Blob blob) => 'stub://blob-url';
  static void revokeObjectUrl(String url) {
    print('URL.revokeObjectUrl (stub) called with: $url');
  }
}

/// html의 Notification 스텁
class Notification {
  static bool get supported => false;
  static String get permission => 'denied';
  
  static Future<String> requestPermission() async => 'denied';
  
  Notification(String title, {String? body, String? icon}) {
    print('Notification (stub) created with title: $title, body: $body');
  }
}

/// html의 Clipboard 스텁
class Clipboard {
  Future<void> writeText(String text) async {
    print('Clipboard writeText (stub) called with: $text');
    throw UnsupportedError('Clipboard API is not available in non-web environment');
  }
}

/// html의 IndexedDB 스텁
class IdbDatabase {
  String get name => 'stub-indexeddb';
  int get version => 1;
  
  void close() {
    print('IdbDatabase close (stub) called');
  }
}

/// JS 스텁 클래스
class JsObject {
  JsObject(dynamic object);
  dynamic operator [](Object property) => null;
  void operator []=(Object property, dynamic value) {}
  bool hasProperty(Object property) => false;
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

/// JS 스텁 클래스
class JsFunction {
  dynamic apply(dynamic thisArg, [List? args]) => null;
}

/// JS 스텁 클래스
class JsArray {
  int get length => 0;
  void add(dynamic value) {}
}

/// 윈도우 전역 객체
final Window window = Window();

// 빈 클래스와 함수들을 정의하여 웹 환경에서만 사용되는 코드가 컴파일되도록 합니다.
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

class HttpRequest {
  static Future<HttpRequest> request(String url, {String? method, dynamic sendData}) {
    throw UnsupportedError('HttpRequest는 비웹 환경에서 사용할 수 없습니다.');
  }
}

// js 스텁
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

class Storage {
  String? getItem(String key) => null;
  void setItem(String key, String value) {}
  void removeItem(String key) {}
  void clear() {}
}

// 유틸리티 함수들
dynamic jsify(dynamic dartObject) => dartObject;
dynamic dartify(dynamic jsObject) => jsObject;
dynamic handleThenable(dynamic jsPromise) => jsPromise; 