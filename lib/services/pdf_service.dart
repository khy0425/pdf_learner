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
} 