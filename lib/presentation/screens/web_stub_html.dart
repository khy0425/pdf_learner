/// 네이티브 환경에서 사용할 html 모듈의 스텁 구현
/// 이 파일은 웹 환경이 아닐 때 dart.library.io 조건부 임포트로 사용됩니다.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'web/html_types.dart' as html;

export 'web/html_types.dart';

class Window {
  final Document document;
  final Location location;
  final Navigator navigator;
  final Map<String, String> localStorage = {};

  Window()
      : document = Document(),
        location = Location(),
        navigator = Navigator();

  void addEventListener(String type, Function(Event) callback) {}
  void removeEventListener(String type, Function(Event) callback) {}
}

class MessageEvent extends Event {
  final dynamic data;

  MessageEvent(this.data) : super('message');
}

class Event {
  final String type;
  Event(this.type);
}

class Element {
  String? type;
  String? value;
  bool? checked;
  bool? disabled;
  bool? multiple;
  String? accept;
  List<File>? files;
  String? href;
  String? id;
  String? name;
  final List<Element> children = [];

  void append(Element child) {
    children.add(child);
  }

  void appendChild(Element child) {
    children.add(child);
  }

  Stream<Event> get onClick => Stream.empty();
  Stream<Event> get onChange => Stream.empty();
  Stream<Event> get onLoad => Stream.empty();
  Stream<Event> get onError => Stream.empty();
}

class Document {
  final Body body;
  Document() : body = Body();

  Element? getElementById(String id) {
    return null;
  }

  List<Element> getElementsByTagName(String tagName) {
    return [];
  }
}

class Location {
  String href = '';
}

class Navigator {
  final Clipboard clipboard = Clipboard();
}

class Plugin {
  final String name;
  Plugin(this.name);
}

class Body {
  final List<Element> children = [];

  void add(Element child) {
    children.add(child);
  }

  void remove(Element child) {
    children.remove(child);
  }
}

class DivElement extends Element {}

class IFrameElement extends Element {}

class InputElement extends Element {
  InputElement() {
    type = 'text';
    value = '';
    checked = false;
    disabled = false;
    multiple = false;
    accept = '';
    files = [];
  }
}

class CanvasElement extends Element {}

class AnchorElement extends Element {
  AnchorElement() {
    href = '';
  }
}

class FileUploadInputElement extends InputElement {
  List<File>? files;

  FileUploadInputElement() {
    files = [];
  }
}

class File {
  final String name;
  final String type;
  final int size;
  final DateTime lastModified;

  File({
    required this.name,
    required this.type,
    required this.size,
    required this.lastModified,
  });
}

class Blob {
  final List<dynamic> data;
  final String type;

  Blob(this.data, this.type);

  static String createObjectUrlFromBlob(Blob blob) {
    return 'blob:${DateTime.now().millisecondsSinceEpoch}';
  }
}

class FileReader {
  Stream<Event> get onLoad => Stream.empty();
  Stream<Event> get onError => Stream.empty();
  dynamic result;

  void readAsDataUrl(Blob blob) {}
  void readAsArrayBuffer(Blob blob) {}
  void readAsText(Blob blob) {}
}

final window = Window();

/// 네이티브 플랫폼에서 사용하는 dart:html의 스텁 구현
/// 
/// 이 파일은 웹이 아닌 환경에서 dart:html 패키지 대신 사용되어 
/// 조건부 임포트가 가능하도록 합니다.

// window 객체 스텁
class Window {
  final html.Document document = html.Document();
  final html.Location location = html.Location();
  final html.Navigator navigator = html.Navigator();
  final Map<String, String> localStorage = {};
  final Map<String, String> sessionStorage = {};
  
  void alert(String message) {
    // 네이티브에서는 동작 안함
  }
  
  void open(String url, String target) {
    // 네이티브에서는 동작 안함
  }
}

// document 객체 스텁
class Document {
  html.Body? body = html.Body();
  
  html.Element createElement(String tagName) {
    switch (tagName) {
      case 'a':
        return html.AnchorElement();
      case 'canvas':
        return html.CanvasElement();
      case 'div':
        return html.DivElement();
      case 'input':
        return html.InputElement();
      default:
        return html.Element();
    }
  }
  
  html.Element? getElementById(String id) {
    return null;
  }
  
  List<html.Element> getElementsByTagName(String tagName) {
    return [];
  }
}

// 요소 스텁
class Element {
  String id = '';
  String className = '';
  String innerHTML = '';
  String innerText = '';
  Style style = Style();
  List<html.Element> children = [];
  
  void setAttribute(String name, String value) {
    // 네이티브에서는 동작 안함
  }
  
  String getAttribute(String name) {
    return '';
  }
  
  void append(html.Element child) {
    children.add(child);
  }
  
  void appendChild(html.Element child) {
    children.add(child);
  }
  
  void remove() {
    // 네이티브에서는 동작 안함
  }
  
  Stream<html.Event> get onClick => Stream.empty();
  Stream<html.Event> get onChange => Stream.empty();
  Stream<html.Event> get onAbort => Stream.empty();
  Stream<html.Event> get onError => Stream.empty();
  Stream<html.Event> get onLoad => Stream.empty();
}

// HTML Input Element 스텁
class InputElement extends html.Element {
  String type = 'text';
  String value = '';
  String placeholder = '';
  bool multiple = false;
  String accept = '';
  List<html.File>? files;
  
  InputElement() : super();
  
  void click() {
    // 네이티브에서는 동작 안함
  }
}

// HTML Canvas Element 스텁
class CanvasElement extends html.Element {
  int width = 0;
  int height = 0;
  
  html.CanvasRenderingContext2D? getContext(String contextId) {
    if (contextId == '2d') {
      return html.CanvasRenderingContext2D();
    }
    return null;
  }
  
  String toDataUrl(String type, [num quality = 0.92]) {
    return '';
  }
}

// 캔버스 렌더링 컨텍스트 스텁
class CanvasRenderingContext2D {
  void setFillColorRgb(int r, int g, int b, [num a = 1]) {}
  void setStrokeColorRgb(int r, int g, int b, [num a = 1]) {}
  void fillRect(num x, num y, num width, num height) {}
  void strokeRect(num x, num y, num width, num height) {}
  void clearRect(num x, num y, num width, num height) {}
  void drawImage(html.Element image, num x, num y, [num width = 0, num height = 0]) {}
}

// HTML Anchor Element 스텁
class AnchorElement extends html.Element {
  String href = '';
  String download = '';
  String target = '';
  String rel = '';
  
  void click() {
    // 네이티브에서는 동작 안함
  }
}

// HTML Div Element 스텁
class DivElement extends html.Element {}

// File Upload Input Element 스텁
class FileUploadInputElement extends html.InputElement {
  FileUploadInputElement() : super() {
    type = 'file';
  }
}

// FILE 객체 스텁
class File {
  final String name;
  final int size;
  final String type;
  final int? lastModified;
  
  File({
    this.name = '',
    this.size = 0,
    this.type = '',
    this.lastModified,
  });
}

// Body 객체 스텁
class Body extends html.Element {}

// Blob 객체 스텁
class Blob {
  final List<dynamic> parts;
  final String type;
  
  Blob(this.parts, [this.type = '']);
  
  int get size => 0;
  
  html.Blob slice(int start, int end, [String? contentType]) {
    return html.Blob([], contentType ?? type);
  }
  
  Future<dynamic> arrayBuffer() async {
    return Uint8List(0).buffer;
  }
}

// URL 유틸리티 스텁
class Url {
  static String createObjectUrlFromBlob(html.Blob blob) {
    return '';
  }
  
  static void revokeObjectUrl(String url) {
    // 네이티브에서는 동작 안함
  }
}

// 파일 리더 스텁
class FileReader {
  dynamic result;
  
  Stream<html.Event> get onLoad => Stream.empty();
  Stream<html.Event> get onError => Stream.empty();
  
  void readAsArrayBuffer(html.Blob blob) {
    // 네이티브에서는 동작 안함
  }
  
  void readAsText(html.Blob blob, [String encoding = 'UTF-8']) {
    // 네이티브에서는 동작 안함
  }
  
  void readAsDataUrl(html.Blob blob) {
    // 네이티브에서는 동작 안함
  }
}

// HTTP 요청 스텁
class HttpRequest {
  int status = 0;
  String statusText = '';
  dynamic response;
  String responseText = '';
  
  static Future<HttpRequest> request(
    String url, {
    String method = 'GET',
    bool withCredentials = false,
    String? responseType,
    String? mimeType,
    Map<String, String>? requestHeaders,
    dynamic sendData,
  }) async {
    return HttpRequest();
  }
}

// 위치 객체 스텁
class Location {
  String href = '';
  String host = '';
  String hostname = '';
  String pathname = '';
  String search = '';
  String hash = '';
  
  void reload() {
    // 네이티브에서는 동작 안함
  }
}

// navigator 객체 스텁
class Navigator {
  Clipboard? clipboard = Clipboard();
}

// 클립보드 스텁
class Clipboard {
  Future<void> writeText(String text) async {
    // 네이티브에서는 동작 안함
  }
}

// 이벤트 스텁
class Event {
  final String type;
  Event([this.type = '']);
}

// IDB 데이터베이스 스텁 (IndexedDB)
class IdbFactory {
  Future<IdbDatabase> open(String name, {int? version, Function? onUpgradeNeeded}) async {
    return IdbDatabase();
  }
  
  Future<void> deleteDatabase(String name) async {
    // 네이티브에서는 동작 안함
  }
}

class IdbDatabase {
  String name = '';
  int version = 1;
  
  IdbObjectStore createObjectStore(String name, {bool? autoIncrement}) {
    return IdbObjectStore();
  }
  
  IdbTransaction transaction(List<String> storeNames, String mode) {
    return IdbTransaction();
  }
  
  void close() {
    // 네이티브에서는 동작 안함
  }
}

class IdbTransaction {
  IdbObjectStore objectStore(String name) {
    return IdbObjectStore();
  }
  
  void abort() {
    // 네이티브에서는 동작 안함
  }
}

class IdbObjectStore {
  String name = '';
  
  Future<dynamic> put(dynamic value, [dynamic key]) async {
    return null;
  }
  
  Future<dynamic> add(dynamic value, [dynamic key]) async {
    return null;
  }
  
  Future<dynamic> get(dynamic key) async {
    return null;
  }
  
  Future<dynamic> delete(dynamic key) async {
    return null;
  }
  
  Future<void> clear() async {
    // 네이티브에서는 동작 안함
  }
}

// ByteBuffer를 구현하기 위한 클래스
class ByteBuffer {
  final List<int> _bytes;
  
  ByteBuffer(this._bytes);
  
  Uint8List asUint8List() {
    return Uint8List.fromList(_bytes);
  }
}

// Uint8List 구현
class Uint8List {
  final List<int> _bytes;
  
  Uint8List(int length) : _bytes = List<int>.filled(length, 0);
  
  factory Uint8List.fromList(List<int> list) {
    return Uint8List(list.length).._bytes.setAll(0, list);
  }
  
  ByteBuffer get buffer => ByteBuffer(_bytes);
  
  List<int> toList() => _bytes.toList();
  
  int operator [](int index) => _bytes[index];
  void operator []=(int index, int value) => _bytes[index] = value;
  
  int get length => _bytes.length;
}

// 스타일 스텁
class Style {
  String display = '';
  String visibility = '';
  String position = '';
  String top = '';
  String left = '';
  String width = '';
  String height = '';
  String backgroundColor = '';
  String color = '';
}

/// IFrame 요소 스텁
class IFrameElement {
  String src = '';
  final style = _ElementStyle();
}

/// 요소 스타일 스텁
class _ElementStyle {
  String height = '';
  String width = '';
  String border = '';
}

/// 웹 스텁에서는 아무 기능도 하지 않는 빈 클래스
class HtmlElement {
  // 스텁 구현
}

/// ui 네임스페이스의 platformViewRegistry 스텁
class PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic Function(int viewId) viewFactory) {
    // 웹이 아닌 환경에서는 아무 동작도 하지 않음
  }
} 