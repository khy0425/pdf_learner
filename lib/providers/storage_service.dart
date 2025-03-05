import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// PDF 파일을 Firebase Storage에 업로드합니다.
  Future<String> uploadPDF(String userId, File file) async {
    try {
      final fileName = path.basename(file.path);
      final destination = 'pdfs/$userId/$fileName';
      
      final ref = _storage.ref(destination);
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      throw Exception('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 웹 환경에서 PDF 파일을 Firebase Storage에 업로드합니다.
  Future<String> uploadPDFWeb(String userId, Uint8List fileBytes, String fileName) async {
    try {
      final destination = 'pdfs/$userId/$fileName';
      
      final ref = _storage.ref(destination);
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('웹 PDF 업로드 오류: $e');
      throw Exception('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 사용자의 프로필 이미지를 업로드합니다.
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      final extension = path.extension(file.path);
      final destination = 'profiles/$userId$extension';
      
      final ref = _storage.ref(destination);
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('프로필 이미지 업로드 오류: $e');
      throw Exception('프로필 이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 웹 환경에서 사용자의 프로필 이미지를 업로드합니다.
  Future<String> uploadProfileImageWeb(String userId, Uint8List fileBytes, String extension) async {
    try {
      final destination = 'profiles/$userId$extension';
      
      final ref = _storage.ref(destination);
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('웹 프로필 이미지 업로드 오류: $e');
      throw Exception('프로필 이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// Firebase Storage에서 파일을 삭제합니다.
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('파일 삭제 오류: $e');
      throw Exception('파일 삭제 중 오류가 발생했습니다: $e');
    }
  }
} 