import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/pdf_model.dart';

/// PDF 데이터 액세스를 담당하는 Repository 클래스
class PdfRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'pdfs';
  
  /// 사용자의 PDF 목록 가져오기
  Future<List<PdfModel>> getPdfs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PdfModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('PDF 목록 가져오기 오류: $e');
      return [];
    }
  }
  
  /// 특정 PDF 가져오기
  Future<PdfModel?> getPdf(String pdfId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(pdfId).get();
      if (!doc.exists) {
        return null;
      }
      
      return PdfModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('PDF 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 오늘 업로드한 PDF 목록 가져오기
  Future<List<PdfModel>> getTodayPdfs(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => PdfModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('오늘 업로드한 PDF 목록 가져오기 오류: $e');
      return [];
    }
  }
  
  /// PDF 저장
  Future<void> savePdf(PdfModel pdf, Uint8List pdfData) async {
    try {
      // Firestore에 PDF 메타데이터 저장
      await _firestore.collection(_collection).doc(pdf.id).set(pdf.toMap());
      
      // Storage에 PDF 파일 저장
      await _storage.ref('pdfs/${pdf.userId}/${pdf.id}.pdf').putData(pdfData);
    } catch (e) {
      debugPrint('PDF 저장 오류: $e');
      throw Exception('PDF를 저장할 수 없습니다.');
    }
  }
  
  /// PDF 데이터 가져오기
  Future<Uint8List?> getPdfData(String pdfId) async {
    try {
      final pdf = await getPdf(pdfId);
      if (pdf == null) {
        return null;
      }
      
      final ref = _storage.ref('pdfs/${pdf.userId}/${pdf.id}.pdf');
      return await ref.getData();
    } catch (e) {
      debugPrint('PDF 데이터 가져오기 오류: $e');
      return null;
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(String pdfId) async {
    try {
      final pdf = await getPdf(pdfId);
      if (pdf == null) {
        return;
      }
      
      // Firestore에서 PDF 메타데이터 삭제
      await _firestore.collection(_collection).doc(pdfId).delete();
      
      // Storage에서 PDF 파일 삭제
      await _storage.ref('pdfs/${pdf.userId}/${pdf.id}.pdf').delete();
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      throw Exception('PDF를 삭제할 수 없습니다.');
    }
  }
  
  /// PDF 접근 횟수 업데이트
  Future<void> updatePdfAccess(String pdfId) async {
    try {
      final pdf = await getPdf(pdfId);
      if (pdf == null) {
        return;
      }
      
      await _firestore.collection(_collection).doc(pdfId).update({
        'accessCount': FieldValue.increment(1),
        'lastAccessedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('PDF 접근 횟수 업데이트 오류: $e');
    }
  }
} 