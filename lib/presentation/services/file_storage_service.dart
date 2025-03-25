import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';

/// 파일 저장소 서비스 클래스
@singleton
class FileStorageService {
  final FirebaseStorage _storage;

  FileStorageService(this._storage);

  /// 임시 디렉토리 경로 가져오기
  Future<String> getTemporaryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// 앱 문서 디렉토리 경로 가져오기
  Future<String> getApplicationDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 파일 저장
  Future<File> saveFile(String fileName, List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 파일 읽기
  Future<List<int>> readFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    return await file.readAsBytes();
  }

  /// 파일 삭제
  Future<void> deleteFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 파일 존재 여부 확인
  Future<bool> fileExists(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    return await file.exists();
  }

  /// 디렉토리 내 모든 파일 목록 가져오기
  Future<List<String>> listFiles(String directoryName) async {
    final directory = await getApplicationDocumentsDirectory();
    final dirPath = path.join(directory.path, directoryName);
    final dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      return [];
    }

    final List<String> files = [];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(path.basename(entity.path));
      }
    }
    return files;
  }

  /// 디렉토리 생성
  Future<void> createDirectory(String directoryName) async {
    final directory = await getApplicationDocumentsDirectory();
    final dirPath = path.join(directory.path, directoryName);
    final dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 디렉토리 삭제
  Future<void> deleteDirectory(String directoryName) async {
    final directory = await getApplicationDocumentsDirectory();
    final dirPath = path.join(directory.path, directoryName);
    final dir = Directory(dirPath);
    
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 파일 크기 가져오기
  Future<int> getFileSize(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 파일 수정 시간 가져오기
  Future<DateTime?> getFileModifiedTime(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      return await file.lastModified();
    }
    return null;
  }

  /// 파일 업로드
  Future<String> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('파일 업로드에 실패했습니다: $e');
    }
  }

  /// 파일 다운로드
  Future<File> downloadFile(String path, String localPath) async {
    try {
      final ref = _storage.ref().child(path);
      final file = File(localPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw Exception('파일 다운로드에 실패했습니다: $e');
    }
  }

  /// 파일 삭제
  Future<void> deleteFromStorage(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      throw Exception('파일 삭제에 실패했습니다: $e');
    }
  }

  /// 파일 URL 가져오기
  Future<String> getFileUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('파일 URL 조회에 실패했습니다: $e');
    }
  }

  /// 파일 목록 가져오기
  Future<List<String>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      return result.items.map((item) => item.fullPath).toList();
    } catch (e) {
      throw Exception('파일 목록 조회에 실패했습니다: $e');
    }
  }
} 