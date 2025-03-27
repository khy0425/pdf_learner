// 웹 환경에서 File 및 Directory 클래스에 대한 스텁 구현
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 웹 환경용 dart:io 스텁

/// 웹 환경을 위한 File 클래스 대체 구현
class File {
  final String path;
  
  File(this.path);
  
  /// 파일 존재 여부 확인 (웹에서는 항상 false 반환)
  Future<bool> exists() async {
    return false;
  }
  
  /// 파일을 바이트로 읽기 (웹에서는 항상 예외 발생)
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('Web environment does not support file operations');
  }
  
  /// 파일에 바이트 쓰기 (웹에서는 항상 예외 발생)
  Future<void> writeAsBytes(Uint8List bytes) async {
    throw UnsupportedError('Web environment does not support file operations');
  }
  
  /// 파일 복사
  Future<File> copy(String newPath) async {
    return File(newPath);
  }
  
  /// 파일 삭제
  Future<void> delete() async {}
}

/// 웹 환경을 위한 Directory 클래스 대체 구현
class Directory {
  final String path;
  
  Directory(this.path);
  
  /// 디렉토리 존재 여부 확인 (웹에서는 항상 false 반환)
  Future<bool> exists() async {
    return false;
  }
  
  /// 디렉토리 생성 (웹에서는 항상 this 반환)
  Future<Directory> create({bool recursive = false}) async {
    return this;
  }
  
  /// 임시 디렉토리 생성
  static Future<Directory> systemTemp() async {
    return Directory('/tmp');
  }
}

/// 파일 시스템 엔티티 스텁
class FileSystemEntity {
  final String path;
  
  FileSystemEntity(this.path);
  
  static Future<bool> isDirectory(String path) async => false;
  static Future<bool> isFile(String path) async => false;
}

// path_provider 스텁
Future<Directory> getApplicationDocumentsDirectory() async {
  if (!kIsWeb) {
    throw UnsupportedError('getApplicationDocumentsDirectory in web_stub.dart should not be called on non-web platforms.');
  }
  return Directory('/documents');
}

Future<Directory> getTemporaryDirectory() async {
  if (!kIsWeb) {
    throw UnsupportedError('getTemporaryDirectory in web_stub.dart should not be called on non-web platforms.');
  }
  return Directory('/temp');
}

Future<Directory> getExternalStorageDirectory() async {
  if (!kIsWeb) {
    throw UnsupportedError('getExternalStorageDirectory in web_stub.dart should not be called on non-web platforms.');
  }
  return Directory('/storage');
}

class WebPathProvider {
  static final WebPathProvider _instance = WebPathProvider._();
  
  static WebPathProvider get instance => _instance;
  
  WebPathProvider._();
  
  String getDocumentsPath() => '/documents';
  String getTemporaryPath() => '/temp';
}

class FileSystemEntityType {
  bool get isDirectory => false;
  bool get isFile => true;
  int get size => 0;
  
  @override
  String toString() => 'File';
}

// html 스텁
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

/// 웹이 아닌 환경에서 사용하는 스텁 파일
/// 
/// dart:html 등 웹 전용 패키지를 대체하기 위한 스텁 클래스들을 제공합니다.

/// 임시 디렉토리 관련 스텁
class TemporaryDirectoryStub {
  String get path => '';
}

/// 외부 저장소 관련 스텁
class ExternalStorageDirectoryStub {
  String get path => '';
}

/// 공통 저장소 관련 스텁
class CommonDirectoryStub {
  String? get path => null;
}

/// 애플리케이션 도큐먼트 디렉토리 관련 스텁
class ApplicationDocumentsDirectoryStub {
  String get path => '';
}

/// 웹 유틸리티 관련 스텁 함수들

/// 로컬 스토리지에서 데이터 로드
dynamic loadFromLocalStorage(String key) {
  return null;
}

/// 로컬 스토리지에 데이터 저장
void saveToLocalStorage(String key, dynamic data) {
  // 웹이 아닌 환경에서는 동작 안함
}

/// 로컬 스토리지에서 데이터 삭제
void removeFromLocalStorage(String key) {
  // 웹이 아닌 환경에서는 동작 안함
}

/// 로컬 스토리지 클리어
void clearLocalStorage() {
  // 웹이 아닌 환경에서는 동작 안함
}

/// 클립보드에 텍스트 복사
void copyToClipboard(String text) {
  // 웹이 아닌 환경에서는 동작 안함
}

/// 페이지 새로고침
void refreshPage() {
  // 웹이 아닌 환경에서는 동작 안함
}

/// Blob URL 생성 
String createBlobUrl(List<int> bytes, String mimeType) {
  return '';
}

/// IndexedDB 관련 함수
Future<void> saveToIndexedDB(String dbName, String storeName, String key, dynamic value) async {
  // 웹이 아닌 환경에서는 동작 안함
}

Future<dynamic> loadFromIndexedDB(String dbName, String storeName, String key) async {
  return null;
}

Future<void> removeFromIndexedDB(String dbName, String storeName, String key) async {
  // 웹이 아닌 환경에서는 동작 안함
}

Future<void> clearIndexedDB(String dbName, String storeName) async {
  // 웹이 아닌 환경에서는 동작 안함
}

/// 파일 선택 관련 함수
Future<Map<String, dynamic>?> pickFile(List<String> allowedExtensions) async {
  return null;
}

Future<List<Map<String, dynamic>>?> pickMultipleFiles(List<String> allowedExtensions) async {
  return null;
}

/// URL에서 파일 다운로드
Future<void> downloadFileFromUrl(String url, String filename) async {
  // 웹이 아닌 환경에서는 동작 안함
}

/// Base64에서 Blob URL 생성
String createBlobUrlFromBase64(String base64Data, String mimeType) {
  return '';
}

/// 바이트 배열에서 Blob URL 생성
String createBlobUrlFromBytes(List<int> bytes, String mimeType) {
  return '';
} 