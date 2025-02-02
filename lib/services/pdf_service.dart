import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'dart:isolate';

class PDFService {
  Future<String> extractText(
    File pdfFile, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final pageCount = document.pages.count;
      final buffer = StringBuffer();

      // 페이지별로 나누어 처리하여 UI 블로킹 방지
      for (int i = 0; i < pageCount; i++) {
        if (onProgress != null) {
          onProgress(i + 1, pageCount);
        }
        
        // 페이지 텍스트 추출을 비동기로 처리
        final text = await compute(
          _extractPageText,
          {'document': document, 'pageIndex': i},
        );
        buffer.write(text);
        
        // UI 업데이트를 위한 짧은 딜레이
        await Future.delayed(const Duration(milliseconds: 1));
      }

      document.dispose();
      return buffer.toString();
    } catch (e) {
      throw Exception('PDF 텍스트 추출 실패: $e');
    }
  }

  Future<List<String>> extractPages(File pdfFile) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      List<String> pages = [];
      
      // 각 페이지별로 텍스트 추출
      for (int i = 0; i < document.pages.count; i++) {
        String text = extractor.extractText(startPageIndex: i);
        pages.add(text);
      }
      
      document.dispose();
      return pages;
    } catch (e) {
      throw Exception('PDF 페이지 추출 실패: $e');
    }
  }

  Future<String> extractPage(File pdfFile, int pageNumber) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      if (pageNumber < 1 || pageNumber > document.pages.count) {
        throw Exception('잘못된 페이지 번호입니다');
      }
      
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText(startPageIndex: pageNumber - 1);
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('페이지 텍스트 추출 실패: $e');
    }
  }
}

// isolate에서 실행될 함수
String _extractPageText(Map<String, dynamic> params) {
  final document = params['document'] as PdfDocument;
  final pageIndex = params['pageIndex'] as int;
  final extractor = PdfTextExtractor(document);
  return extractor.extractText(startPageIndex: pageIndex);
} 