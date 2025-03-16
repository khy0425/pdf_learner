import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
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
      final snapshot = await _firestore
          .collection('pdfs')
          .where('id', isEqualTo: pdfId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        throw Exception('PDF를 찾을 수 없습니다');
      }
      
      final pdf = PdfModel.fromMap(snapshot.docs.first.data());
      
      if (pdf.url != null) {
        // URL에서 PDF 데이터 가져오기
        final response = await http.get(Uri.parse(pdf.url!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('PDF 다운로드 실패: ${response.statusCode}');
        }
      } else if (pdf.localPath != null) {
        // 로컬 파일에서 PDF 데이터 가져오기
        final file = File(pdf.localPath!);
        return await file.readAsBytes();
      } else {
        throw Exception('PDF 데이터를 찾을 수 없습니다');
      }
    } catch (e) {
      debugPrint('PDF 데이터 가져오기 오류: $e');
      rethrow;
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      // PDF 정보 가져오기
      final snapshot = await _firestore
          .collection('pdfs')
          .where('id', isEqualTo: pdfId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        throw Exception('PDF를 찾을 수 없습니다');
      }
      
      final pdf = PdfModel.fromMap(snapshot.docs.first.data());
      
      // Firebase Storage에서 삭제
      if (pdf.url != null && pdf.url!.contains('firebasestorage.googleapis.com')) {
        final storageRef = _storage.refFromURL(pdf.url!);
        await storageRef.delete();
      }
      
      // Firestore에서 삭제
      await _firestore.collection('pdfs').doc(pdfId).delete();
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      rethrow;
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
  
  /// 파일에서 PDF 업로드
  Future<PdfModel> uploadPdfFromFile(File file, String userId) async {
    try {
      final fileName = path.basename(file.path);
      final fileSize = await file.length();
      final bytes = await file.readAsBytes();
      
      // Firebase Storage에 업로드
      final storageRef = _storage.ref().child('pdfs/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // PDF 모델 생성
      final pdf = PdfModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: fileName,
        size: fileSize,
        pageCount: 1, // 실제 구현에서는 PDF 페이지 수 계산 필요
        textLength: 0, // 실제 구현에서는 PDF 텍스트 길이 계산 필요
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        accessCount: 0,
        url: downloadUrl,
        localPath: null,
      );
      
      // Firestore에 저장
      await _firestore.collection('pdfs').doc(pdf.id).set(pdf.toMap());
      
      return pdf;
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      rethrow;
    }
  }
  
  /// URL에서 PDF 업로드
  Future<PdfModel> uploadPdfFromUrl(String url, String userId) async {
    try {
      // URL에서 PDF 다운로드
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      }
      
      final bytes = response.bodyBytes;
      final fileName = url.split('/').last;
      
      // Firebase Storage에 업로드
      final storageRef = _storage.ref().child('pdfs/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // PDF 모델 생성
      final pdf = PdfModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: fileName,
        size: bytes.length,
        pageCount: 1, // 실제 구현에서는 PDF 페이지 수 계산 필요
        textLength: 0, // 실제 구현에서는 PDF 텍스트 길이 계산 필요
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        accessCount: 0,
        url: downloadUrl,
        localPath: null,
      );
      
      // Firestore에 저장
      await _firestore.collection('pdfs').doc(pdf.id).set(pdf.toMap());
      
      return pdf;
    } catch (e) {
      debugPrint('URL에서 PDF 업로드 오류: $e');
      rethrow;
    }
  }
} 