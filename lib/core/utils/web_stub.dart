// dart:html 웹 전용 API에 대한 스텁 클래스
// Flutter 웹이 아닌 환경(Android, iOS 등)에서 컴파일 오류 방지를 위한 파일입니다.

// 이 파일은 플랫폼에 따라 조건부로 가져오기 위해 사용됩니다.
// web 환경에서는 dart:html을 실제로 사용하고,
// 비 web 환경에서는 이 스텁 파일을 사용합니다.

import 'dart:typed_data';

/// Storage 인터페이스의 간단한 구현
class Storage {
  final Map<String, String> _data = <String, String>{};

  /// 저장된 항목 수
  int get length => _data.length;

  /// 모든 키 목록 반환
  Iterable<String> get keys => _data.keys;

  /// 키로 값 가져오기 (연산자 방식)
  String? operator [](String key) => _data[key];

  /// 키에 값 저장하기 (연산자 방식)
  void operator []=(String key, String value) {
    _data[key] = value;
  }

  /// 키로 값 가져오기 (메서드 방식)
  String? getItem(String key) => _data[key];
  
  /// 키에 값 저장하기 (메서드 방식)
  void setItem(String key, String value) => _data[key] = value;

  /// 키에 해당하는 값 제거 (메서드 방식)
  void removeItem(String key) => _data.remove(key);
  
  /// 키에 해당하는 값 제거 (일반 방식)
  void remove(String key) => _data.remove(key);

  /// 모든 데이터 삭제
  void clear() => _data.clear();

  /// 지정된 인덱스의 키 반환
  String key(int index) {
    return _data.keys.elementAt(index);
  }

  /// 값 존재 여부 확인
  bool containsKey(String key) => _data.containsKey(key);
}

/// Window 클래스 스텁
class Window {
  /// localStorage 인스턴스
  final Storage localStorage = Storage();
  
  /// sessionStorage 인스턴스
  final Storage sessionStorage = Storage();
  
  /// Location 인스턴스
  final Location location = Location();
}

/// Location 스텁
class Location {
  String href = 'about:blank';
  String host = 'localhost';
  String hostname = 'localhost';
  String origin = 'http://localhost';
  String protocol = 'http:';
  
  void reload() {
    // 스텁 - 아무 작업 안함
  }
}

/// window 전역 객체
final Window window = Window();

/// Document 클래스 스텁
class Document {
  /// body 요소
  final Element body = Element();
  
  /// 요소 생성
  Element createElement(String tagName) {
    if (tagName == 'a') return AnchorElement();
    if (tagName == 'input') return InputElement();
    return Element();
  }
  
  /// ID로 요소 가져오기
  Element? getElementById(String id) {
    return null;
  }
}

/// document 전역 객체
final Document document = Document();

/// HTML 요소 스텁
class Element {
  /// 스타일 속성
  final Map<String, String> style = {};
  
  /// 자식 요소 목록
  final List<Element> children = [];
  
  /// 자식 요소 추가
  void appendChild(Element child) {
    children.add(child);
  }
  
  /// 요소 제거
  void remove() {
    // 스텁 구현 - 아무 작업도 수행하지 않음
  }
  
  /// 속성 설정
  void setAttribute(String name, String value) {
    // 스텁 구현 - 아무 작업도 수행하지 않음
  }
  
  /// 클래스 추가
  void addClass(String className) {
    // 스텁 구현 - 아무 작업도 수행하지 않음
  }
}

/// a 태그 스텁
class AnchorElement extends Element {
  /// href 속성
  String href = '';
  
  /// download 속성
  String download = '';
  
  /// target 속성
  String target = '';
  
  /// click 이벤트 발생
  void click() {
    // 스텁 구현 - 아무 작업도 수행하지 않음
  }
}

/// input 요소 스텁
class InputElement extends Element {
  String type = 'text';
  String value = '';
  bool multiple = false;
  String accept = '';
  
  /// click 이벤트 발생
  void click() {
    // 스텁 구현 - 아무 작업도 수행하지 않음
  }
  
  /// 이벤트 리스너
  Stream<Event> get onChange => _onChange.stream;
  final _onChange = StreamController<Event>.broadcast();
  
  /// 파일 목록
  List<File>? get files => null;
}

/// 이벤트 스텁
class Event {}

/// 스트림 컨트롤러
class StreamController<T> {
  /// 생성자
  StreamController.broadcast();
  
  /// 스트림 객체
  Stream<T> get stream => Stream<T>.empty();
}

/// 스트림 스텁
class Stream<T> {
  /// 빈 스트림 생성
  Stream.empty();
  
  /// 리스너 등록
  void listen(Function(T) onData, {Function? onError, Function? onDone}) {}
}

/// File 클래스 스텁
class File {
  /// 파일 이름
  final String name;
  
  /// 파일 크기
  final int size;
  
  /// 파일 타입
  final String type;
  
  /// 생성자
  File(this.name, this.size, this.type);
}

/// 파일 리더 스텁
class FileReader {
  dynamic result;
  
  Stream<Event> get onLoad => Stream<Event>.empty();
  Stream<Event> get onError => Stream<Event>.empty();
  
  void readAsText(File file) {}
  void readAsArrayBuffer(File file) {}
}

/// Blob 클래스 스텁
class Blob {
  final dynamic _data;
  final String _type;
  
  Blob(this._data, this._type);
}

/// HttpRequest 스텁
class HttpRequest {
  int status = 200;
  dynamic response;
  String responseText = '';
  
  static Future<HttpRequest> request(
    String url, {
    String method = 'GET',
    String? responseType,
    dynamic sendData,
  }) async {
    return HttpRequest();
  }
}

/// URL 스텁
class Url {
  /// URL 생성
  static String createObjectUrl(dynamic blob) => '';
  
  /// Blob에서 URL 생성
  static String createObjectUrlFromBlob(Blob blob) => '';
  
  /// URL 해제
  static void revokeObjectUrl(String url) {}
} 