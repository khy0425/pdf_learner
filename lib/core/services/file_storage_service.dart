import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';
import 'package:firebase_storage/firebase_storage.dart';

@injectable
class FileStorageService {
  final FirebaseStorage _storage;

  FileStorageService({
    required FirebaseStorage storage,
  }) : _storage = storage;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  Future<bool> saveFile(String path, List<int> bytes) async {
    try {
      final file = await _localFile(path);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('파일 저장 실패: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      final file = await _localFile(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('파일 삭제 실패: $e');
      return false;
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      final file = await _localFile(path);
      return await file.exists();
    } catch (e) {
      print('파일 존재 확인 실패: $e');
      return false;
    }
  }

  Future<int> getFileSize(String path) async {
    try {
      final file = await _localFile(path);
      return await file.length();
    } catch (e) {
      print('파일 크기 확인 실패: $e');
      return 0;
    }
  }

  Future<bool> clearCache() async {
    try {
      final directory = await getTemporaryDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
        return true;
      }
      return false;
    } catch (e) {
      print('캐시 정리 실패: $e');
      return false;
    }
  }

  Future<void> uploadFile(String filePath, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.putData(await File(filePath).readAsBytes());
    } catch (e) {
      throw Exception('파일 업로드 중 오류가 발생했습니다: $e');
    }
  }

  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('다운로드 URL을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<File> downloadFile(String url, String localPath) async {
    try {
      final ref = _storage.refFromURL(url);
      final file = File(localPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw Exception('파일 다운로드 실패: $e');
    }
  }

  Future<bool> exists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = await ref.getMetadata();
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdTime': metadata.timeCreated,
        'updatedTime': metadata.updated,
      };
    } catch (e) {
      throw Exception('메타데이터 가져오기 실패: $e');
    }
  }
} 