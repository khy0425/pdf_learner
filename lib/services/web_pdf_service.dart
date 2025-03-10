import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;

/// 웹 환경에서 PDF 파일을 관리하는 서비스
class WebPdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 웹 환경에서 PDF 업로드
  Future<String> uploadPdfWeb(Uint8List bytes, String fileName, String userId) async {
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
    } catch (e, stackTrace) {
      debugPrint('PDF 업로드 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 오류 유형에 따른 구체적인 메시지 제공
      if (e is FirebaseException) {
        if (e.code == 'unauthorized') {
          throw Exception('PDF 업로드 권한이 없습니다. 로그인 상태를 확인해주세요.');
        } else if (e.code == 'canceled') {
          throw Exception('PDF 업로드가 취소되었습니다.');
        } else {
          throw Exception('Firebase 오류: ${e.code} - ${e.message}');
        }
      } else {
        throw Exception('PDF 업로드 중 오류가 발생했습니다: $e');
      }
    }
  }
  
  /// 파일명 정리 (특수문자 제거)
  String _sanitizeFileName(String fileName) {
    // 공백을 언더스코어로 변경하고 특수문자 제거
    return fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w\s\.-]'), '')
        .toLowerCase();
  }
  
  /// 사용자의 PDF 목록 가져오기
  Future<List<Map<String, dynamic>>> getUserPdfs(String userId) async {
    try {
      debugPrint('사용자 PDF 목록 조회 시작: 사용자ID=$userId');
      
      // 복합 인덱스가 필요한 쿼리 대신 간단한 쿼리 사용
      final snapshot = await _firestore
          .collection('pdfs')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('PDF 문서 수: ${snapshot.docs.length}');
      
      // 결과를 날짜 기준으로 정렬 (클라이언트 측에서 정렬)
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime); // 내림차순 정렬
      });
      
      return docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        
        // pdfData 필드는 제외하고 반환 (데이터 크기 줄이기)
        if (data.containsKey('pdfData')) {
          data.remove('pdfData');
        }
        
        // URL 필드 설정 (문서 ID만 저장)
        data['url'] = doc.id;
        
        return data;
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('PDF 목록 조회 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 빈 목록 반환하고 오류 로깅
      debugPrint('오류로 인해 빈 PDF 목록 반환');
      return [];
    }
  }
  
  /// PDF 파일 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      debugPrint('PDF 삭제 시작: 문서ID=$pdfId, 사용자ID=$userId');
      
      // Firestore에서 PDF 정보 가져오기
      final doc = await _firestore.collection('pdfs').doc(pdfId).get();
      if (!doc.exists) {
        debugPrint('PDF 문서를 찾을 수 없음: $pdfId');
        throw Exception('PDF를 찾을 수 없습니다.');
      }
      
      final data = doc.data()!;
      if (data['userId'] != userId) {
        debugPrint('PDF 삭제 권한 없음: 문서 소유자=${data['userId']}, 요청자=$userId');
        throw Exception('이 PDF를 삭제할 권한이 없습니다.');
      }
      
      // Firestore에서 문서 삭제
      debugPrint('Firestore 문서 삭제 시작');
      await _firestore.collection('pdfs').doc(pdfId).delete();
      debugPrint('PDF 삭제 완료');
    } catch (e, stackTrace) {
      debugPrint('PDF 삭제 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      if (e is FirebaseException) {
        throw Exception('Firebase 오류: ${e.code} - ${e.message}');
      } else {
        throw Exception('PDF 삭제 중 오류가 발생했습니다: $e');
      }
    }
  }
  
  /// PDF 다운로드 URL 가져오기 (브라우저에서 사용 가능한 데이터 URL 생성)
  Future<String> getPdfDownloadUrl(String pdfId) async {
    try {
      debugPrint('PDF URL 조회 시작: 문서ID=$pdfId');
      
      // Firestore에서 PDF 데이터 가져오기
      final bytes = await getPdfDataFromFirestore(pdfId);
      if (bytes == null) {
        throw Exception('PDF 데이터를 가져올 수 없습니다');
      }
      
      // 데이터 URL 생성 (브라우저에서 직접 사용 가능)
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      debugPrint('PDF 데이터 URL 생성 완료: $url');
      return url;
    } catch (e, stackTrace) {
      debugPrint('PDF URL 조회 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 오류 발생 시 빈 문자열 반환
      return '';
    }
  }
  
  /// Firestore 문서 ID로부터 PDF 데이터 가져오기
  Future<Uint8List?> getPdfDataFromFirestore(String docId) async {
    try {
      debugPrint('Firestore에서 PDF 데이터 가져오기 시작: 문서ID=$docId');
      
      final doc = await _firestore.collection('pdfs').doc(docId).get();
      if (!doc.exists) {
        debugPrint('PDF 문서를 찾을 수 없음: $docId');
        return null;
      }
      
      final data = doc.data();
      if (data == null || !data.containsKey('pdfData')) {
        debugPrint('PDF 데이터 필드가 없음');
        return null;
      }
      
      // Base64 디코딩
      final base64Data = data['pdfData'] as String;
      final bytes = base64Decode(base64Data);
      
      debugPrint('PDF 데이터 가져오기 성공: ${bytes.length} 바이트');
      return bytes;
    } catch (e) {
      debugPrint('PDF 데이터 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 브라우저에서 PDF 데이터를 직접 열기
  void openPdfInBrowser(Uint8List pdfData) {
    try {
      // Blob 생성
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // 새 탭에서 PDF 열기
      html.window.open(url, '_blank');
      
      // 메모리 누수 방지를 위해 URL 해제 예약
      Future.delayed(const Duration(minutes: 5), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      debugPrint('PDF를 브라우저에서 열지 못했습니다: $e');
    }
  }
} 