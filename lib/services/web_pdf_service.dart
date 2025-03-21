import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../utils/non_web_stub.dart' if (dart.library.html) 'dart:html' as html;

/// 웹 환경에서 PDF 파일을 관리하는 서비스
class WebPdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 웹 환경에서 PDF 업로드
  Future<String> uploadPdfWeb(Uint8List bytes, String fileName, String userId) async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹 환경에서만 사용할 수 있습니다.');
    }
    
    try {
      debugPrint('PDF 업로드 시작: 파일명=$fileName, 사용자ID=$userId, 크기=${bytes.length}바이트');
      
      // 파일명에서 특수문자 제거 및 타임스탬프 추가
      final sanitizedFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${timestamp}_$sanitizedFileName';
      
      debugPrint('저장소 파일명: $storageFileName');
      
      // 업로드 전에 파일 크기 확인
      if (bytes.length > 5 * 1024 * 1024) { // 5MB 제한 (Firestore 문서 크기 제한)
        throw Exception('파일 크기가 너무 큽니다. 5MB 이하의 파일만 업로드할 수 있습니다.');
      }
      
      // CORS 문제를 우회하기 위해 Firebase Storage 대신 Firestore에 직접 저장
      debugPrint('Firestore에 PDF 데이터 저장 시작');
      
      // Base64로 인코딩하여 Firestore에 저장
      final base64Data = base64Encode(bytes);
      
      // Firestore에 메타데이터와 PDF 데이터 저장
      final docRef = await _firestore.collection('pdfs').add({
        'userId': userId,
        'fileName': fileName,
        'storageFileName': storageFileName,
        'pdfData': base64Data, // Base64로 인코딩된 PDF 데이터
        'createdAt': FieldValue.serverTimestamp(),
        'size': bytes.length,
        'contentType': 'application/pdf',
        'uploadTimestamp': timestamp,
      });
      
      // 문서 ID를 식별자로 사용 (가상 URL 대신 문서 ID만 저장)
      final docId = docRef.id;
      
      debugPrint('PDF 업로드 완료: 문서ID=$docId');
      
      return docId;
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      rethrow; // 오류를 다시 던져서 호출자가 처리할 수 있도록 함
    }
  }
  
  /// 웹 다운로드 메서드 - PDF 바이트 가져오기
  Future<Uint8List> getPdfBytes(String docId) async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹 환경에서만 사용할 수 있습니다.');
    }
    
    try {
      debugPrint('PDF 다운로드 시작: docId=$docId');
      
      // Firestore에서 문서 가져오기
      final docSnap = await _firestore.collection('pdfs').doc(docId).get();
      
      if (!docSnap.exists) {
        throw Exception('PDF 문서를 찾을 수 없습니다. (ID: $docId)');
      }
      
      final data = docSnap.data() as Map<String, dynamic>;
      
      // Base64 인코딩된 데이터 가져오기
      final base64Data = data['pdfData'] as String?;
      
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('PDF 데이터가 없습니다.');
      }
      
      debugPrint('PDF 데이터 크기: ${base64Data.length}자');
      
      // Base64 디코딩하여 바이트 배열로 변환
      final bytes = base64Decode(base64Data);
      
      debugPrint('PDF 다운로드 완료: ${bytes.length}바이트');
      
      return bytes;
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      rethrow;
    }
  }
  
  /// 웹 환경에서 PDF 저장 (다운로드)
  Future<void> savePdfToDevice(String docId, String fileName) async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹 환경에서만 사용할 수 있습니다.');
    }
    
    try {
      debugPrint('PDF 저장 시작: docId=$docId, fileName=$fileName');
      
      // PDF 바이트 가져오기
      final bytes = await getPdfBytes(docId);
      
      // 웹 환경에서 파일 다운로드
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // 다운로드 링크 생성
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        
        // URL 해제
        html.Url.revokeObjectUrl(url);
      }
      
      debugPrint('PDF 저장 완료');
    } catch (e) {
      debugPrint('PDF 저장 오류: $e');
      rethrow;
    }
  }
  
  /// PDF 문서 삭제
  Future<bool> deletePdf(String docId, String userId) async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹 환경에서만 사용할 수 있습니다.');
    }
    
    try {
      debugPrint('PDF 삭제 시작: docId=$docId, userId=$userId');
      
      // 문서 가져오기
      final docSnap = await _firestore.collection('pdfs').doc(docId).get();
      
      if (!docSnap.exists) {
        debugPrint('PDF 문서를 찾을 수 없습니다. (ID: $docId)');
        return false;
      }
      
      final data = docSnap.data() as Map<String, dynamic>;
      final docUserId = data['userId'] as String?;
      
      // 소유자 권한 확인
      if (docUserId != userId) {
        debugPrint('권한이 없습니다. 문서 소유자($docUserId)와 요청자($userId)가 다릅니다.');
        return false;
      }
      
      // 문서 삭제
      await _firestore.collection('pdfs').doc(docId).delete();
      
      debugPrint('PDF 삭제 완료');
      return true;
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      return false;
    }
  }
  
  /// PDF 미리보기 URL 생성
  Future<String?> generatePdfPreviewUrl(String docId) async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹 환경에서만 사용할 수 있습니다.');
    }
    
    try {
      debugPrint('PDF 미리보기 URL 생성 시작: docId=$docId');
      
      // PDF 바이트 가져오기
      final bytes = await getPdfBytes(docId);
      
      // 바이트 -> Blob -> URL
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // URL 반환
        return url;
      }
      
      return null;
    } catch (e) {
      debugPrint('PDF 미리보기 URL 생성 오류: $e');
      return null;
    }
  }
  
  /// 파일명 정리 (특수문자 제거)
  String _sanitizeFileName(String fileName) {
    // 특수문자 제거
    var sanitized = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    
    // 연속된 밑줄이나 공백 제거
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // 앞뒤 공백 제거
    sanitized = sanitized.trim();
    
    // 파일명이 너무 길면 잘라냄
    if (sanitized.length > 100) {
      final extension = sanitized.contains('.') ? 
        sanitized.substring(sanitized.lastIndexOf('.')) : '';
      sanitized = sanitized.substring(0, 95 - extension.length) + extension;
    }
    
    return sanitized;
  }
  
  /// Firestore에서 PDF 데이터를 가져오는 메서드
  Future<Uint8List> getPdfDataFromFirestore(String docId) async {
    try {
      debugPrint('Firestore에서 PDF 데이터 가져오기: $docId');
      
      final docSnapshot = await _firestore.collection('pdfs').doc(docId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('PDF 데이터를 찾을 수 없습니다. ID: $docId');
      }
      
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('pdfData')) {
        throw Exception('PDF 데이터가 없습니다.');
      }
      
      // Base64로 인코딩된 데이터를 디코딩
      final String base64Data = data['pdfData'];
      final Uint8List bytes = base64Decode(base64Data);
      
      debugPrint('PDF 데이터 가져오기 성공: ${bytes.length} 바이트');
      return bytes;
    } catch (e) {
      debugPrint('PDF 데이터 가져오기 오류: $e');
      rethrow;
    }
  }
} 