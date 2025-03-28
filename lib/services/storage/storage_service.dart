import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../../core/utils/web_storage_utils.dart';
import 'package:uuid/uuid.dart';

/// 저장소 서비스 인터페이스
/// 
/// 파일 및 문자열 데이터를 저장, 읽기, 삭제하는 기능 제공
abstract class StorageService {
  /// 임시 디렉토리 가져오기
  Future<Directory> getTemporaryDirectory();
  
  /// 문서 디렉토리 가져오기
  Future<Directory> getDocumentsDirectory();
  
  /// 파일 복사
  Future<void> copyFile(String sourcePath, String targetPath);
  
  /// 파일 삭제
  Future<void> deleteFile(String filePath);
  
  /// PDF 페이지 수 가져오기
  Future<int> getPDFPageCount(String filePath);
  
  /// PDF 파일 크기 가져오기
  Future<int> getFileSize(String filePath);
  
  /// 파일이 존재하는지 확인
  Future<bool> fileExists(String filePath);
  
  /// 앱 캐시 삭제
  Future<void> clearCache();
  
  /// 파일 저장
  Future<String> saveFile(Uint8List bytes, String fileName, {String? directory});
  
  /// 파일 읽기
  Future<Uint8List?> readFile(String filePath);
  
  /// 디렉토리 내 모든 파일 가져오기
  Future<List<FileSystemEntity>> getDirectoryFiles(String directoryPath);
  
  /// 문자열 값 저장
  Future<bool> setString(String key, String value);
  
  /// 문자열 값 읽기
  String? getString(String key);
  
  /// 정수 값 저장
  Future<bool> setInt(String key, int value);
  
  /// 정수 값 읽기
  int? getInt(String key);
  
  /// 더블 값 저장
  Future<bool> setDouble(String key, double value);
  
  /// 더블 값 읽기
  double? getDouble(String key);
  
  /// 불리언 값 저장
  Future<bool> setBool(String key, bool value);
  
  /// 불리언 값 읽기
  bool? getBool(String key);
  
  /// 문자열 목록 저장
  Future<bool> setStringList(String key, List<String> value);
  
  /// 문자열 목록 읽기
  List<String>? getStringList(String key);
  
  /// JSON 객체 저장
  Future<bool> setJson(String key, Map<String, dynamic> value);
  
  /// JSON 객체 읽기
  Map<String, dynamic>? getJson(String key);
  
  /// 키 삭제
  Future<bool> remove(String key);
  
  /// 모든 키-값 쌍 삭제
  Future<bool> clear();
  
  /// 키 존재 여부 확인
  bool containsKey(String key);
  
  /// 모든 키 가져오기
  Set<String> getKeys();
  
  /// 저장된 값의 수 가져오기
  int get length;
  
  /// 마지막 접근 시간 업데이트
  Future<bool> updateLastAccessed(String id);
}

/// 로컬 저장소 서비스 구현체
class StorageServiceImpl implements StorageService {
  final SharedPreferences _sharedPreferences;
  
  StorageServiceImpl(this._sharedPreferences);
  
  @override
  Future<Directory> getTemporaryDirectory() async {
    if (kIsWeb) {
      // 웹에서는 임시 디렉토리 개념이 없으므로 가상 경로 반환
      return Directory('/temp');
    } else {
      // path_provider 패키지의 getTemporaryDirectory() 메서드 사용
      return await path_provider.getTemporaryDirectory();
    }
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
      debugPrint('웹 환경에서는 파일 복사가 제한됩니다: $sourcePath -> $targetPath');
      return;
    } else {
      final sourceFile = File(sourcePath);
      final targetFile = File(targetPath);
      await sourceFile.copy(targetPath);
    }
  }
  
  @override
  Future<void> deleteFile(String filePath) async {
    if (kIsWeb) {
      // 웹에서는 파일 시스템 접근이 제한되므로 가상으로 처리
      debugPrint('웹 환경에서는 파일 삭제가 제한됩니다: $filePath');
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
      // 웹에서는 PDF 페이지 수 가져오기 구현 필요
      // 실제 구현에서는 웹 전용 PDF 라이브러리 사용해야 함
      return 1;
    } else {
      // 네이티브 환경에서는 PDF 라이브러리 사용하여 페이지 수 가져오기
      // 임시로 고정값 반환
      return 1;
    }
  }
  
  @override
  Future<int> getFileSize(String filePath) async {
    if (kIsWeb) {
      // 웹에서는 파일 크기 가져오기가 제한됨
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
      // 웹에서는 파일 존재 여부 확인이 제한됨
      return false;
    } else {
      final file = File(filePath);
      return await file.exists();
    }
  }
  
  @override
  Future<void> clearCache() async {
    if (kIsWeb) {
      // 웹에서는 캐시 삭제가 제한됨
      return;
    } else {
      final tempDir = await getTemporaryDirectory();
      final appCacheDir = Directory('${tempDir.path}/app_cache');
      if (await appCacheDir.exists()) {
        await appCacheDir.delete(recursive: true);
      }
    }
  }
  
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    if (kIsWeb) {
      // 웹에서는 파일 저장이 제한됨
      final uuid = const Uuid().v4();
      return '/web_storage/$uuid/$fileName';
    } else {
      final dir = directory != null 
          ? Directory(directory) 
          : await getDocumentsDirectory();
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    }
  }
  
  @override
  Future<Uint8List?> readFile(String filePath) async {
    if (kIsWeb) {
      // 웹에서는 파일 읽기가 제한됨
      return null;
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    }
  }
  
  @override
  Future<List<FileSystemEntity>> getDirectoryFiles(String directoryPath) async {
    if (kIsWeb) {
      // 웹에서는 디렉토리 내 파일 목록 가져오기가 제한됨
      return [];
    } else {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }
      
      return await directory.list().toList();
    }
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    return await _sharedPreferences.setString(key, value);
  }
  
  @override
  String? getString(String key) {
    return _sharedPreferences.getString(key);
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    return await _sharedPreferences.setInt(key, value);
  }
  
  @override
  int? getInt(String key) {
    return _sharedPreferences.getInt(key);
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    return await _sharedPreferences.setDouble(key, value);
  }
  
  @override
  double? getDouble(String key) {
    return _sharedPreferences.getDouble(key);
  }
  
  @override
  Future<bool> setBool(String key, bool value) async {
    return await _sharedPreferences.setBool(key, value);
  }
  
  @override
  bool? getBool(String key) {
    return _sharedPreferences.getBool(key);
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _sharedPreferences.setStringList(key, value);
  }
  
  @override
  List<String>? getStringList(String key) {
    return _sharedPreferences.getStringList(key);
  }
  
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }
  
  @override
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) {
      return null;
    }
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON 파싱 실패: $e');
      return null;
    }
  }
  
  @override
  Future<bool> remove(String key) async {
    return await _sharedPreferences.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return await _sharedPreferences.clear();
  }
  
  @override
  bool containsKey(String key) {
    return _sharedPreferences.containsKey(key);
  }
  
  @override
  Set<String> getKeys() {
    return _sharedPreferences.getKeys();
  }
  
  @override
  int get length => _sharedPreferences.getKeys().length;
  
  @override
  Future<bool> updateLastAccessed(String id) async {
    final key = 'last_accessed_$id';
    final now = DateTime.now().millisecondsSinceEpoch;
    return await setInt(key, now);
  }
}

/// 파이어베이스 스토리지 서비스 구현
class FirebaseStorageServiceImpl implements StorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;
  
  FirebaseStorageServiceImpl({
    required FirebaseStorage storage,
    required FirebaseAuth auth,
    required SharedPreferences prefs,
  }) : _storage = storage,
       _auth = auth,
       _prefs = prefs;
  
  // Firebase 관련 구현은 요구 사항에 따라 추가 예정
  
  @override
  Future<Directory> getTemporaryDirectory() async {
    // 구현 예정
    return Directory('/temp');
  }
  
  @override
  Future<Directory> getDocumentsDirectory() async {
    // 구현 예정
    return Directory('/documents');
  }
  
  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    // 구현 예정
  }
  
  @override
  Future<void> deleteFile(String filePath) async {
    // 구현 예정
  }
  
  @override
  Future<int> getPDFPageCount(String filePath) async {
    // 구현 예정
    return 1;
  }
  
  @override
  Future<int> getFileSize(String filePath) async {
    // 구현 예정
    return 0;
  }
  
  @override
  Future<bool> fileExists(String filePath) async {
    // 구현 예정
    return false;
  }
  
  @override
  Future<void> clearCache() async {
    // 구현 예정
  }
  
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    // 구현 예정
    return '';
  }
  
  @override
  Future<Uint8List?> readFile(String filePath) async {
    // 구현 예정
    return null;
  }
  
  @override
  Future<List<FileSystemEntity>> getDirectoryFiles(String directoryPath) async {
    // 구현 예정
    return [];
  }
  
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
    return json.decode(jsonString);
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
    final now = DateTime.now().toIso8601String();
    return await _prefs.setString('${id}_last_accessed', now);
  }
} 