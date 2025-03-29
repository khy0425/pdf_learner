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
  
  /// 키-값 쌍에 대해 forEach 적용
  void forEach(void Function(String key, String value) f) {
    _data.forEach(f);
  }
}

/// Window 클래스 스텁
class Window {
  /// localStorage 인스턴스
  final Storage localStorage = Storage();
  
  /// sessionStorage 인스턴스
  final Storage sessionStorage = Storage();
  
  /// Location 인스턴스
  final Location location = Location();
  
  /// Navigator 인스턴스
  final Navigator navigator = Navigator();
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

/// Navigator 스텁
class Navigator {
  /// 클립보드 API
  final Clipboard? clipboard = Clipboard();
  
  /// Share API
  final dynamic shareData = ShareData();
  
  /// Share API 사용 가능 여부 확인
  bool get canShare => false;
  
  /// 공유 메서드
  Future<bool> shareContent(Map<String, dynamic> data) async => false;
}

/// Clipboard 스텁
class Clipboard {
  /// 텍스트 쓰기
  Future<void> writeText(String text) async {}
  
  /// 텍스트 읽기
  Future<String> readText() async => '';
  
  /// 데이터 복사
  Future<void> write(Map<String, dynamic> data) async {}
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
    if (tagName == 'canvas') return CanvasElement();
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

/// Canvas 엘리먼트
class CanvasElement extends Element {
  int width = 0;
  int height = 0;
  
  /// Canvas 렌더링 컨텍스트 가져오기
  CanvasRenderingContext2D getContext(String contextId, [Map<String, dynamic>? options]) {
    return CanvasRenderingContext2D();
  }
  
  /// Canvas 렌더링 컨텍스트 가져오기 (2d)
  CanvasRenderingContext2D getContext2d() {
    return CanvasRenderingContext2D();
  }
  
  /// 데이터 URL로 변환
  String toDataUrl([String type = 'image/png', num quality = 0.92]) {
    return '';
  }
}

/// Canvas 2D 렌더링 컨텍스트
class CanvasRenderingContext2D {
  /// 폰트 설정
  String font = '10px sans-serif';
  
  /// 텍스트 정렬
  String textAlign = 'start';
  
  /// 채우기 스타일
  String fillStyle = '#000000';
  
  /// 선 스타일
  String strokeStyle = '#000000';
  
  /// 선 굵기
  double lineWidth = 1.0;
  
  void drawImage(Element image, int x, int y, [int? width, int? height]) {}
  void putImageData(ImageData imageData, int x, int y) {}
  void clearRect(int x, int y, int width, int height) {}
  void fillRect(int x, int y, int width, int height) {}
  void strokeRect(int x, int y, int width, int height) {}
  void fillText(String text, double x, double y, [double? maxWidth]) {}
  void strokeText(String text, double x, double y, [double? maxWidth]) {}
  
  ImageData getImageData(int x, int y, int width, int height) {
    return ImageData();
  }
  
  ImageData createImageData(int width, int height) {
    return ImageData();
  }
  
  /// 경로 시작
  void beginPath() {}
  
  /// 경로 닫기
  void closePath() {}
  
  /// 선 그리기
  void stroke() {}
  
  /// 채우기
  void fill() {}
  
  /// 경로 이동
  void moveTo(double x, double y) {}
  
  /// 선 그리기
  void lineTo(double x, double y) {}
  
  /// 원호 그리기
  void arc(double x, double y, double radius, double startAngle, double endAngle, [bool anticlockwise = false]) {}
}

/// 이미지 데이터
class ImageData {
  Uint8List get data => Uint8List(0);
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
  
  /// 마지막 수정 시간
  final DateTime lastModified;
  
  File({this.name = '', this.size = 0, this.type = '', DateTime? lastModified}) 
    : lastModified = lastModified ?? DateTime.now();
  
  /// 파일 존재 여부 확인
  Future<bool> exists() async => false;
  
  /// 파일 읽기
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  
  /// 파일 텍스트 읽기
  Future<String> readAsString() async => '';
  
  /// 파일 쓰기
  Future<void> writeAsBytes(List<int> bytes) async {}
  
  /// 파일 텍스트 쓰기
  Future<void> writeAsString(String contents) async {}
}

/// 파일 업로드 엘리먼트
class FileUploadInputElement extends InputElement {
  // 추가 구현 없음
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
  
  Blob(this._data, [this._type = '']);
}

/// HttpRequest 스텁
class HttpRequest {
  /// 상태 코드
  int status = 200;
  
  /// 응답 데이터
  dynamic response;
  
  /// HTTP 요청 전송
  static Future<HttpRequest> request(String url, {String method = 'GET', String? responseType, dynamic send}) async {
    return HttpRequest();
  }
}

/// Url 유틸리티 스텁
class Url {
  /// Blob에서 Object URL 생성
  static String createObjectUrlFromBlob(Blob blob) => '';
  
  /// Object URL 해제
  static void revokeObjectUrl(String url) {}
}

/// ShareData 인터페이스
class ShareData {
  /// URL 공유
  final String? url;
  
  /// 제목 공유
  final String? title;
  
  /// 텍스트 공유
  final String? text;
  
  /// 파일 공유
  final List<File>? files;
  
  ShareData({this.url, this.title, this.text, this.files});
  
  /// Map으로 변환
  Map<String, dynamic> toMap() => {
    if (url != null) 'url': url,
    if (title != null) 'title': title,
    if (text != null) 'text': text,
  };
}

/// PDF 관련 클래스들
/// PdfPage 스텁
class PdfPage {
  final int width;
  final int height;
  
  PdfPage({this.width = 0, this.height = 0});
  
  Size get size => Size(width.toDouble(), height.toDouble());
  
  /// 페이지 텍스트
  Future<String> get text async => '';
  
  /// 페이지를 이미지로 변환
  Future<PdfPageImage?> render({int? width, int? height}) async {
    final renderWidth = width ?? this.width;
    final renderHeight = height ?? this.height;
    return PdfPageImage(
      width: renderWidth, 
      height: renderHeight,
      bytes: Uint8List(0),
    );
  }
  
  /// 이미지 생성
  Future<PdfBitmap?> createImage({int? width, int? height}) async {
    final image = await render(width: width, height: height);
    if (image == null) return null;
    return PdfBitmap(image.bytes);
  }
}

/// PdfDocument 스텁
class PdfDocument {
  /// 페이지 목록
  final List<PdfPage> pages;
  
  /// 페이지 수
  int get pageCount => pages.length;
  
  /// 문서 로드 함수
  PdfDocument({Uint8List? inputBytes}) : pages = [] {
    // 더미 페이지 추가
    pages.add(PdfPage(width: 595, height: 842));
    pages.add(PdfPage(width: 595, height: 842));
  }
  
  /// 페이지 가져오기
  Future<PdfPage> getPage(int pageNumber) async {
    final index = pageNumber - 1;
    if (index < 0 || index >= pages.length) {
      throw RangeError('페이지 번호가 유효하지 않습니다: $pageNumber');
    }
    return pages[index];
  }
  
  /// 문서 데이터로 열기
  static Future<PdfDocument> openData(Uint8List data) async {
    return PdfDocument(inputBytes: data);
  }
  
  /// 문서 닫기
  void dispose() {
    // 리소스 정리
  }
}

/// PdfBitmap 스텁
class PdfBitmap {
  /// 이미지 데이터
  final Uint8List _bytes;
  
  /// 이미지 너비
  final int width;
  
  /// 이미지 높이
  final int height;
  
  PdfBitmap(this._bytes, {this.width = 100, this.height = 100});
  
  /// 이미지 바이트 데이터
  Future<Uint8List> get bytes async => _bytes;
}

/// PDF 페이지 이미지 클래스
class PdfPageImage {
  /// 이미지 너비
  final int width;
  
  /// 이미지 높이
  final int height;
  
  /// 이미지 바이트 데이터
  final Uint8List bytes;
  
  PdfPageImage({
    required this.width, 
    required this.height, 
    Uint8List? bytes
  }) : bytes = bytes ?? Uint8List(0);
}

/// Size 클래스
class Size {
  final double width;
  final double height;
  
  Size(this.width, this.height);
} 