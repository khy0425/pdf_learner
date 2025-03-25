// 웹이 아닌 플랫폼에서 사용할 스텁 구현
class Window {
  static Window get window => Window();
  dynamic localStorage;
}

class Document {
  dynamic body;
}

class Element {
  List<Element> children = [];
  void click() {}
  void remove() {}
}

class AnchorElement extends Element {
  String? href;
  String? download;
  String? target;
}

class FileUploadInputElement extends Element {
  String? accept;
  bool? multiple;
  List<File> files = [];
  void click() {}
}

class File {
  String name;
  int size;
  String type;

  File(this.name, this.size, this.type);
}

class FileReader {
  dynamic result;
  Function? onLoad;
  void readAsArrayBuffer(File file) {}
}

class Blob {
  List<int> bytes;
  String type;

  Blob(this.bytes, this.type);

  static String createObjectUrlFromBlob(Blob blob) => '';
}

class HttpRequest {
  static Future<HttpRequest> request(
    String url, {
    String? method,
    dynamic sendData,
    Map<String, String>? requestHeaders,
    bool? withCredentials,
    int? timeout,
  }) async {
    throw UnimplementedError('HttpRequest.request() is only supported on web');
  }
}

Window window = Window();
Document document = Document(); 