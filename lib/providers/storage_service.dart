import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPDF(File file, String userId) async {
    try {
      final ref = _storage.ref('pdfs/$userId/${DateTime.now()}.pdf');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('PDF 업로드 실패: $e');
      rethrow;
    }
  }

  Future<void> deletePDF(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('PDF 삭제 실패: $e');
      rethrow;
    }
  }
} 