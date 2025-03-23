// 웹 환경에서 File 및 Directory 클래스에 대한 스텁 구현
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 웹 환경용 dart:io 스텁

/// 파일 클래스 스텁
class File {
  final String path;
  
  File(this.path);
  
  /// 파일 존재 여부 확인
  Future<bool> exists() async {
    return false;
  }
  
  /// 파일 읽기 - Uint8List 반환
  Future<Uint8List> readAsBytes() async {
    return Uint8List(0);
  }
  
  /// 파일 쓰기
  Future<File> writeAsBytes(List<int> bytes) async {
    return this;
  }
  
  /// 파일 복사
  Future<File> copy(String newPath) async {
    return File(newPath);
  }
  
  /// 파일 삭제
  Future<void> delete() async {}
}

/// 디렉토리 클래스 스텁
class Directory {
  final String path;
  
  Directory(this.path);
  
  /// 디렉토리 생성
  Future<Directory> create({bool recursive = false}) async {
    return this;
  }
  
  /// 디렉토리 존재 여부 확인
  Future<bool> exists() async {
    return false;
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