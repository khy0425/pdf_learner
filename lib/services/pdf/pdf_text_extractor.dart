import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_learner_v2/models/ai_summary.dart';
import 'package:pdf_learner_v2/models/document.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

/// PDF 텍스트 추출을 담당하는 서비스 클래스
class PdfTextExtractor {
  /// 웹 환경에서 PDF 텍스트 추출
  static Future<PdfTextExtraction> extractTextFromWeb(Document document) async {
    try {
      // Blob URL인 경우 데이터를 직접 가져옴
      if (document.path.startsWith('blob:')) {
        final fetchResult = await _fetchBlobContent(document.path);
        return _extractFromBytes(document.id, fetchResult);
      } 
      // HTTP URL인 경우 다운로드
      else if (document.path.startsWith('http')) {
        final response = await http.get(Uri.parse(document.path));
        
        if (response.statusCode == 200) {
          return _extractFromBytes(document.id, response.bodyBytes);
        } else {
          throw Exception('PDF 다운로드 실패: ${response.statusCode}');
        }
      } else {
        throw Exception('지원되지 않는 URL 형식: ${document.path}');
      }
    } catch (e) {
      debugPrint('웹 PDF 텍스트 추출 오류: $e');
      // 빈 결과 반환
      return PdfTextExtraction(
        documentId: document.id, 
        pageTexts: {},
      );
    }
  }
  
  /// 모바일/데스크톱 환경에서 PDF 텍스트 추출
  static Future<PdfTextExtraction> extractTextFromFile(Document document) async {
    try {
      final ByteData data = await rootBundle.load(document.path);
      final Uint8List bytes = data.buffer.asUint8List();
      return _extractFromBytes(document.id, bytes);
    } catch (e) {
      debugPrint('파일 PDF 텍스트 추출 오류: $e');
      // 빈 결과 반환
      return PdfTextExtraction(
        documentId: document.id, 
        pageTexts: {},
      );
    }
  }
  
  /// 바이트 데이터에서 텍스트 추출 (공통 로직)
  static Future<PdfTextExtraction> _extractFromBytes(String documentId, Uint8List bytes) async {
    try {
      // PDF 문서 로드
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // 페이지별 텍스트 추출
      final Map<int, String> pageTexts = {};
      
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfTextExtractor extractor = PdfTextExtractor(page);
        final String text = extractor.extractText();
        
        if (text.isNotEmpty) {
          pageTexts[i + 1] = text; // 1부터 시작하는 페이지 번호 사용
        }
      }
      
      // 문서 닫기
      document.dispose();
      
      return PdfTextExtraction(
        documentId: documentId,
        pageTexts: pageTexts,
      );
    } catch (e) {
      debugPrint('PDF 텍스트 추출 처리 오류: $e');
      // 빈 결과 반환
      return PdfTextExtraction(
        documentId: documentId, 
        pageTexts: {},
      );
    }
  }
  
  /// 웹에서 Blob URL 콘텐츠 가져오기
  static Future<Uint8List> _fetchBlobContent(String blobUrl) async {
    if (kIsWeb) {
      final completer = Completer<Uint8List>();
      
      // JavaScript를 통해 Blob URL에서 데이터 가져오기
      final xhr = html.HttpRequest();
      xhr.open('GET', blobUrl);
      xhr.responseType = 'arraybuffer';
      
      xhr.onLoad.listen((_) {
        final Uint8List bytes = Uint8List.fromList(xhr.response as List<int>);
        completer.complete(bytes);
      });
      
      xhr.onError.listen((_) {
        completer.completeError('Blob URL에서 데이터 가져오기 실패');
      });
      
      xhr.send();
      return completer.future;
    } else {
      throw Exception('Blob URL은 웹 환경에서만 지원됩니다');
    }
  }
} 