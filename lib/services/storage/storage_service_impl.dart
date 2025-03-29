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
  final SharedPreferences _preferences;
  
  StorageServiceImpl({required SharedPreferences preferences})
    : _preferences = preferences;
  
  @override
  Future<Directory> getTemporaryDirectory() async {
    return await path_provider.getTemporaryDirectory();
  }
  
  @override
  Future<Directory> getDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }
  
  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('원본 파일이 존재하지 않습니다: $sourcePath');
      }
      
      // 타겟 디렉토리 확인 및 생성
      final targetFile = File(targetPath);
      final targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // 파일 복사
      await sourceFile.copy(targetPath);
    } catch (e) {
      debugPrint('파일 복사 오류: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('파일 삭제 오류: $e');
      rethrow;
    }
  }
  
  @override
  Future<int> getPDFPageCount(String filePath) async {
    // 실제 구현에서는 PDF 라이브러리를 사용하여 페이지 수 가져오기
    return 0;
  }
  
  @override
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('파일 크기 가져오기 오류: $e');
      return 0;
    }
  }
  
  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('파일 존재 확인 오류: $e');
      return false;
    }
  }
  
  @override
  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFiles = await tempDir.list().toList();
      
      for (final file in cacheFiles) {
        if (file is File) {
          await file.delete();
        } else if (file is Directory) {
          await file.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('캐시 정리 오류: $e');
      rethrow;
    }
  }
  
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    try {
      final Directory baseDir;
      if (directory != null) {
        baseDir = Directory(directory);
      } else {
        baseDir = await path_provider.getApplicationDocumentsDirectory();
      }
      
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }
      
      final filePath = '${baseDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      debugPrint('파일 저장 오류: $e');
      rethrow;
    }
  }
  
  @override
  Future<Uint8List?> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('파일 읽기 오류: $e');
      return null;
    }
  }
  
  @override
  Future<List<FileSystemEntity>> getDirectoryFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }
      
      return await directory.list().toList();
    } catch (e) {
      debugPrint('디렉토리 파일 가져오기 오류: $e');
      return [];
    }
  }
  
  // SharedPreferences 관련 메서드들
  
  @override
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }
  
  @override
  String? getString(String key) {
    return _preferences.getString(key);
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }
  
  @override
  int? getInt(String key) {
    return _preferences.getInt(key);
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    return await _preferences.setDouble(key, value);
  }
  
  @override
  double? getDouble(String key) {
    return _preferences.getDouble(key);
  }
  
  @override
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }
  
  @override
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }
  
  @override
  List<String>? getStringList(String key) {
    return _preferences.getStringList(key);
  }
  
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }
  
  @override
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      return null;
    }
  }
  
  @override
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return await _preferences.clear();
  }
  
  @override
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }
  
  @override
  Set<String> getKeys() {
    return _preferences.getKeys();
  }
  
  @override
  int get length => _preferences.getKeys().length;
  
  @override
  Future<bool> updateLastAccessed(String id) async {
    final key = 'last_accessed_$id';
    final now = DateTime.now().toIso8601String();
    return await setString(key, now);
  }
} 