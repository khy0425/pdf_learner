import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/pdf_document.dart';
import 'package:url_launcher/url_launcher.dart';
// 웹에서만 사용할 js는 조건부 임포트
import 'dart:js' if (dart.library.io) '../utils/web_stub.dart' as js;

/// PDF 뷰어 서비스 클래스
class PdfViewerService {
  /// 로컬 파일로 문서 다운로드
  Future<String?> downloadPdfToLocal(String url, String documentId) async {
    if (kIsWeb) {
      // 웹에서는 URL 그대로 사용
      return url;
    }
    
    try {
      final response = await http.get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$documentId.pdf');
        await file.writeAsBytes(bytes);
        return file.path;
      } else {
        debugPrint('PDF 다운로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      return null;
    }
  }
  
  /// 문서에서 텍스트 추출 (웹 환경에서 사용)
  Future<String> extractTextFromPdf(String pdfUrl, int startPage, int endPage) async {
    try {
      // 웹 환경에서 텍스트 추출 예: API 호출
      if (kIsWeb) {
        final apiUrl = 'https://api.example.com/extract-text';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'pdfUrl': pdfUrl,
            'startPage': startPage,
            'endPage': endPage,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['text'] as String? ?? '';
        }
      }
      
      // 기본 응답
      return '';
    } catch (e) {
      debugPrint('텍스트 추출 오류: $e');
      return '';
    }
  }
  
  /// PDF 파일 공유
  Future<bool> sharePdfDocument(PDFDocument document) async {
    try {
      // 구현 예: 플랫폼별 공유 로직
      debugPrint('PDF 공유 기능 호출됨');
      return true;
    } catch (e) {
      debugPrint('PDF 공유 오류: $e');
      return false;
    }
  }
  
  /// PDF 북마크 저장
  Future<bool> saveBookmark(PDFDocument document, PDFBookmark bookmark) async {
    try {
      // 구현 예: 데이터베이스에 북마크 저장
      debugPrint('북마크 저장 기능 호출됨');
      return true;
    } catch (e) {
      debugPrint('북마크 저장 오류: $e');
      return false;
    }
  }
  
  /// PDF 북마크 삭제
  Future<bool> deleteBookmark(PDFDocument document, String bookmarkId) async {
    try {
      // 구현 예: 데이터베이스에서 북마크 삭제
      debugPrint('북마크 삭제 기능 호출됨');
      return true;
    } catch (e) {
      debugPrint('북마크 삭제 오류: $e');
      return false;
    }
  }

  /// 외부 앱으로 PDF 열기
  Future<bool> openWithExternalApp(String pdfPath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 새 창에서 열기
        final url = pdfPath.startsWith('http') ? pdfPath : 'file://$pdfPath';
        js.context.callMethod('open', [url, '_blank']);
        return true;
      } else {
        // 네이티브 환경에서 외부 앱 실행
        final url = pdfPath.startsWith('http') ? pdfPath : 'file://$pdfPath';
        if (await canLaunch(url)) {
          await launch(url);
          return true;
        } else {
          debugPrint('PDF를 열 수 있는 앱을 찾을 수 없습니다.');
          return false;
        }
      }
    } catch (e) {
      debugPrint('외부 앱으로 PDF 열기 오류: $e');
      return false;
    }
  }
} 