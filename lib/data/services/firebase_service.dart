import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';

@injectable
class FirebaseService {
  final FirebaseFirestore _firestore;

  FirebaseService(this._firestore);

  Future<void> setPDFDocument(PDFDocument document) async {
    try {
      await _firestore
          .collection('pdfs')
          .doc(document.id)
          .set(document.toJson());
    } catch (e) {
      throw Exception('Firestore에 PDF 문서 저장 중 오류가 발생했습니다: $e');
    }
  }

  Future<List<PDFDocument>> getPDFDocuments() async {
    try {
      final snapshot = await _firestore.collection('pdfs').get();
      return snapshot.docs
          .map((doc) => PDFDocument.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Firestore에서 PDF 문서 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> deletePDFDocument(String documentId) async {
    try {
      await _firestore.collection('pdfs').doc(documentId).delete();
    } catch (e) {
      throw Exception('Firestore에서 PDF 문서 삭제 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> updatePDFDocument(PDFDocument document) async {
    try {
      await _firestore
          .collection('pdfs')
          .doc(document.id)
          .update(document.toJson());
    } catch (e) {
      throw Exception('Firestore에서 PDF 문서 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  Future<PDFDocument?> getPDFDocument(String documentId) async {
    try {
      final doc = await _firestore.collection('pdfs').doc(documentId).get();
      if (!doc.exists) return null;
      return PDFDocument.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Firestore에서 PDF 문서를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
} 