import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

/// 웹 환경에서 PDF 파일을 관리하는 서비스
class WebPdfService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 웹 환경에서 PDF 업로드
  Future<String> uploadPdfWeb(Uint8List bytes, String fileName, String userId) async {
    try {
      final ref = _storage.ref('pdfs/$userId/$fileName');
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Firestore에 메타데이터 저장
      await _firestore.collection('pdfs').add({
        'userId': userId,
        'fileName': fileName,
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'size': bytes.length,
      });
      
      return downloadUrl;
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      throw Exception('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 사용자의 PDF 목록 가져오기
  Future<List<Map<String, dynamic>>> getUserPdfs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('pdfs')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList();
    } catch (e) {
      debugPrint('PDF 목록 조회 오류: $e');
      throw Exception('PDF 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 파일 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      // Firestore에서 PDF 정보 가져오기
      final doc = await _firestore.collection('pdfs').doc(pdfId).get();
      if (!doc.exists) {
        throw Exception('PDF를 찾을 수 없습니다.');
      }
      
      final data = doc.data()!;
      if (data['userId'] != userId) {
        throw Exception('이 PDF를 삭제할 권한이 없습니다.');
      }
      
      // Storage에서 파일 삭제
      final fileName = data['fileName'];
      await _storage.ref('pdfs/$userId/$fileName').delete();
      
      // Firestore에서 문서 삭제
      await _firestore.collection('pdfs').doc(pdfId).delete();
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      throw Exception('PDF 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 다운로드 URL 가져오기
  Future<String> getPdfDownloadUrl(String pdfId) async {
    try {
      final doc = await _firestore.collection('pdfs').doc(pdfId).get();
      if (!doc.exists) {
        throw Exception('PDF를 찾을 수 없습니다.');
      }
      
      return doc.data()!['url'];
    } catch (e) {
      debugPrint('PDF URL 조회 오류: $e');
      throw Exception('PDF URL을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
} 