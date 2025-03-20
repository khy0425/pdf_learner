import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/pdf_file_info.dart';

/// PDF 데이터 액세스를 담당하는 Repository 클래스
class PdfRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'pdfs';
  final Uuid _uuid = const Uuid();
  
  /// 사용자의 PDF 파일 목록 가져오기
  Future<List<PdfFileInfo>> getPdfFiles(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PdfFileInfo.fromMap({...doc.data(), 'firestoreId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('PDF 목록 가져오기 오류: $e');
      return [];
    }
  }
  
  /// 특정 PDF 가져오기
  Future<PdfFileInfo?> getPdfFile(String pdfId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(pdfId).get();
      if (!doc.exists) {
        return null;
      }
      
      return PdfFileInfo.fromMap({...doc.data()!, 'firestoreId': doc.id});
    } catch (e) {
      debugPrint('PDF 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 로컬 파일에서 PDF 업로드
  Future<PdfFileInfo> uploadPdfFile(File file, String fileName, int fileSize, String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('유효하지 않은 사용자 ID입니다.');
      }
      
      if (!await file.exists()) {
        throw Exception('파일이 존재하지 않습니다.');
      }
      
      // 스토리지에 파일 업로드
      final fileId = _uuid.v4();
      final storagePath = 'pdfs/$userId/$fileId.pdf';
      final storageRef = _storage.ref().child(storagePath);
      
      // 파일 데이터 읽기
      Uint8List fileBytes;
      try {
        fileBytes = await file.readAsBytes();
      } catch (e) {
        debugPrint('파일 읽기 오류: $e');
        throw Exception('파일을 읽을 수 없습니다: $e');
      }
      
      if (fileBytes.isEmpty) {
        throw Exception('파일 데이터가 비어 있습니다');
      }
      
      // 웹에서는 putData, 네이티브에서는 putFile 사용
      UploadTask uploadTask;
      try {
        if (kIsWeb) {
          uploadTask = storageRef.putData(
            fileBytes, 
            SettableMetadata(contentType: 'application/pdf')
          );
        } else {
          uploadTask = storageRef.putFile(file);
        }
      } catch (e) {
        debugPrint('업로드 작업 생성 오류: $e');
        throw Exception('파일 업로드를 위한 작업을 생성할 수 없습니다: $e');
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Firestore에 메타데이터 저장
      final pdfData = {
        'id': fileId,
        'fileName': fileName,
        'url': downloadUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'fileSize': fileSize,
        'userId': userId,
      };
      
      final docRef = await _firestore.collection(_collection).add(pdfData);
      
      // PdfFileInfo 객체 생성 및 반환
      return PdfFileInfo.fromMap({
        ...pdfData,
        'firestoreId': docRef.id,
      });
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      rethrow;
    }
  }
  
  /// URL에서 PDF 업로드
  Future<PdfFileInfo> uploadPdfFromUrl(String url, String userId) async {
    try {
      // URL에서 파일 다운로드
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('URL에서 PDF 다운로드 실패: ${response.statusCode}');
      }
      
      final bytes = response.bodyBytes;
      final fileName = url.split('/').last;
      final fileSize = bytes.length;
      
      // 스토리지에 파일 업로드
      final fileId = _uuid.v4();
      final storagePath = 'pdfs/$userId/$fileId.pdf';
      final storageRef = _storage.ref().child(storagePath);
      
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Firestore에 메타데이터 저장
      final pdfData = {
        'id': fileId,
        'fileName': fileName,
        'url': downloadUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'fileSize': fileSize,
        'userId': userId,
      };
      
      final docRef = await _firestore.collection(_collection).add(pdfData);
      
      // PdfFileInfo 객체 생성 및 반환
      return PdfFileInfo.fromMap({
        ...pdfData,
        'firestoreId': docRef.id,
      });
    } catch (e) {
      debugPrint('URL에서 PDF 업로드 오류: $e');
      rethrow;
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      // Firestore에서 문서 조회
      final snapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: pdfId)
          .where('userId', isEqualTo: userId)
          .get();
      
      if (snapshot.docs.isEmpty) {
        throw Exception('삭제할 PDF를 찾을 수 없습니다');
      }
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      
      // 스토리지에서 파일 삭제
      if (data['url'] != null) {
        final storageRef = _storage.refFromURL(data['url']);
        await storageRef.delete();
      }
      
      // Firestore에서 문서 삭제
      await _firestore.collection(_collection).doc(doc.id).delete();
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      rethrow;
    }
  }
} 