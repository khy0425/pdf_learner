import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // PDF 업로드
  Future<String> uploadPDF(File file, String userId) async {
    final ref = _storage.ref('pdfs/$userId/${DateTime.now()}.pdf');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // 메타데이터 저장
  Future<void> savePDFMetadata({
    required String userId,
    required String fileUrl,
    required Map<String, dynamic> metadata,
  }) {
    return _db.collection('pdfs').add({
      'userId': userId,
      'fileUrl': fileUrl,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // 사용자별 학습 데이터 저장
  Future<void> saveUserProgress({
    required String userId,
    required String fileId,
    required Map<String, dynamic> progress,
  });
} 