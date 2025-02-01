import 'package:pdf_text/pdf_text.dart';
import 'dart:io';

class PDFService {
  Future<String> extractText(File pdfFile) async {
    try {
      PDFDoc doc = await PDFDoc.fromFile(pdfFile);
      String text = await doc.text;
      return text;
    } catch (e) {
      throw Exception('PDF 텍스트 추출 실패: $e');
    }
  }

  Future<List<String>> extractPages(File pdfFile) async {
    try {
      PDFDoc doc = await PDFDoc.fromFile(pdfFile);
      List<String> pages = [];
      
      for (var i = 0; i < doc.length; i++) {
        PDFPage page = await doc.pageAt(i);
        String text = await page.text;
        pages.add(text);
      }
      
      return pages;
    } catch (e) {
      throw Exception('PDF 페이지 추출 실패: $e');
    }
  }
} 