import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';
import 'storage_service.dart';

/// StorageService의 구현체 - PDFLocalDataSource에서 사용됨
@Injectable(as: StorageService)
class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;
  
  StorageServiceImpl(this._prefs);
  
  @override
  Future<Directory> getTemporaryDirectory() async {
    if (kIsWeb) {
      // 웹에서는 임시 디렉토리 개념이 없으므로 가상 경로 반환
      return Directory('/temp');
    } else {
      return await getTemporaryDirectoryFromSystem();
    }
  }
  
  Future<Directory> getTemporaryDirectoryFromSystem() async {
    return await path_provider.getTemporaryDirectory();
  }
  
  @override
  Future<Directory> getDocumentsDirectory() async {
    if (kIsWeb) {
      // 웹에서는 문서 디렉토리 개념이 없으므로 가상 경로 반환
      return Directory('/documents');
    } else {
      return await path_provider.getApplicationDocumentsDirectory();
    }
  }
  
  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    if (kIsWeb) {
      // 웹에서는 파일 시스템 접근이 제한되므로 가상으로 처리
      return;
    } else {
      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);
    }
  }
  
  @override
  Future<void> deleteFile(String filePath) async {
    if (kIsWeb) {
      // 웹에서는 파일 시스템 접근이 제한됨
      return;
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
  
  @override
  Future<int> getPDFPageCount(String filePath) async {
    if (kIsWeb) {
      // 웹에서의 PDF 페이지 수 확인 로직
      // 실제 구현에서는 웹 전용 PDF 라이브러리 사용
      return 1;
    } else {
      // 실제 네이티브 구현에서는 PDF 라이브러리 사용 필요
      // 임시 구현
      try {
        return 1;
      } catch (e) {
        return 0;
      }
    }
  }
  
  @override
  Future<int> getFileSize(String filePath) async {
    if (kIsWeb) {
      // 웹에서의 파일 크기 확인 로직
      return 0;
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    }
  }
  
  @override
  Future<bool> fileExists(String filePath) async {
    if (kIsWeb) {
      // 웹에서의 파일 존재 확인 로직
      return false;
    } else {
      final file = File(filePath);
      return await file.exists();
    }
  }
  
  @override
  Future<void> clearCache() async {
    if (kIsWeb) {
      // 웹에서의 캐시 삭제 로직
      return;
    } else {
      try {
        final tempDir = await getTemporaryDirectory();
        final cacheDir = Directory('${tempDir.path}/cache');
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        // 예외 처리
      }
    }
  }
  
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    if (kIsWeb) {
      // 웹에서의 파일 저장 로직 (임시 구현)
      final uuid = const Uuid().v4();
      return '/virtual_storage/$uuid/$fileName';
    } else {
      try {
        final dir = directory != null 
            ? Directory(directory)
            : await getApplicationDocumentsDirectory();
            
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        final filePath = path.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      } catch (e) {
        throw Exception('파일 저장 실패: $e');
      }
    }
  }
  
  @override
  Future<Uint8List?> readFile(String filePath) async {
    if (kIsWeb) {
      // 웹에서의 파일 읽기 로직
      return null;
    } else {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
        return null;
      } catch (e) {
        return null;
      }
    }
  }
  
  @override
  Future<List<FileSystemEntity>> getDirectoryFiles(String directoryPath) async {
    if (kIsWeb) {
      // 웹에서의 디렉토리 파일 목록 가져오기 로직
      return [];
    } else {
      try {
        final directory = Directory(directoryPath);
        if (await directory.exists()) {
          return await directory.list().toList();
        }
        return [];
      } catch (e) {
        return [];
      }
    }
  }
  
  // SharedPreferences 관련 메서드 구현
  @override
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  @override
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  @override
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  @override
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    return await _prefs.setString(key, jsonString);
  }
  
  @override
  Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) {
      return null;
    }
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  @override
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
  
  @override
  int get length {
    return _prefs.getKeys().length;
  }
  
  @override
  Future<bool> updateLastAccessed(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return await _prefs.setString('last_accessed_$id', now);
  }
} 