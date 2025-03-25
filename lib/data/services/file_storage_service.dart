import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

@injectable
class FileStorageService {
  final FirebaseStorage _storage;

  FileStorageService(this._storage);

  Future<Reference> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return ref;
    } catch (e) {
      throw Exception('파일 업로드 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      throw Exception('파일 삭제 중 오류가 발생했습니다: $e');
    }
  }

  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      throw Exception('파일 다운로드 URL을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> updateFile(File file, String path) async {
    try {
      await deleteFile(path);
      await uploadFile(file, path);
    } catch (e) {
      throw Exception('파일 업데이트 중 오류가 발생했습니다: $e');
    }
  }
} 