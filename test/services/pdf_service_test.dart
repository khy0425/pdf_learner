import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pdf_study_assistant/services/pdf_service.dart';
import 'dart:io';

void main() {
  group('PDFService Tests', () {
    late PDFService pdfService;
    late File testPdfFile;

    setUp(() {
      pdfService = PDFService();
      // 테스트용 PDF 파일 생성 또는 로드
      testPdfFile = File('test/resources/test.pdf');
    });

    test('extractText returns text from PDF', () async {
      if (await testPdfFile.exists()) {
        final text = await pdfService.extractText(testPdfFile);
        expect(text, isNotEmpty);
      } else {
        skip('테스트 PDF 파일이 없습니다.');
      }
    });

    test('extractPages returns list of pages', () async {
      if (await testPdfFile.exists()) {
        final pages = await pdfService.extractPages(testPdfFile);
        expect(pages, isA<List<String>>());
        expect(pages, isNotEmpty);
      } else {
        skip('테스트 PDF 파일이 없습니다.');
      }
    });
  });
} 