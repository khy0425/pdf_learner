import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pdf_learner_v2/core/services/pdf_service.dart';
import 'pdf_service_test.mocks.dart';

@GenerateMocks([PDFService])
void main() {
  late PDFService pdfService;

  setUp(() {
    pdfService = MockPDFService();
  });

  tearDown(() {
    pdfService.dispose();
  });

  group('PDFService', () {
    test('PDF 파일 열기가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testFile = File('test.pdf');
      when(pdfService.openPDF(testFile)).thenAnswer((_) async => true);

      // Act
      final result = await pdfService.openPDF(testFile);

      // Assert
      expect(result, true);
      verify(pdfService.openPDF(testFile)).called(1);
    });

    test('페이지 수 가져오기가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      when(pdfService.getPageCount()).thenAnswer((_) async => 10);

      // Act
      final pageCount = await pdfService.getPageCount();

      // Assert
      expect(pageCount, 10);
      verify(pdfService.getPageCount()).called(1);
    });

    test('현재 페이지 가져오기가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      when(pdfService.getCurrentPage()).thenAnswer((_) async => 5);

      // Act
      final currentPage = await pdfService.getCurrentPage();

      // Assert
      expect(currentPage, 5);
      verify(pdfService.getCurrentPage()).called(1);
    });

    test('페이지 이동이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      when(pdfService.goToPage(3)).thenAnswer((_) async => true);

      // Act
      final result = await pdfService.goToPage(3);

      // Assert
      expect(result, true);
      verify(pdfService.goToPage(3)).called(1);
    });

    test('페이지 렌더링이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testPageData = List<int>.generate(100, (i) => i);
      when(pdfService.renderPage()).thenAnswer((_) async => testPageData);

      // Act
      final pageData = await pdfService.renderPage();

      // Assert
      expect(pageData, testPageData);
      expect(pageData.length, 100);
      verify(pdfService.renderPage()).called(1);
    });

    test('텍스트 추출이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testText = 'Test PDF content';
      when(pdfService.extractText()).thenAnswer((_) async => testText);

      // Act
      final extractedText = await pdfService.extractText();

      // Assert
      expect(extractedText, testText);
      verify(pdfService.extractText()).called(1);
    });

    test('메타데이터 가져오기가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testMetadata = {
        'title': 'Test PDF',
        'author': 'Test Author',
        'subject': 'Test Subject',
        'keywords': ['test', 'pdf'],
        'creationDate': DateTime.now(),
        'modificationDate': DateTime.now(),
      };

      when(pdfService.getMetadata()).thenAnswer((_) async => testMetadata);

      // Act
      final metadata = await pdfService.getMetadata();

      // Assert
      expect(metadata, testMetadata);
      expect(metadata['title'], 'Test PDF');
      expect(metadata['author'], 'Test Author');
      verify(pdfService.getMetadata()).called(1);
    });

    test('텍스트 검색이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testSearchResults = [
        {'page': 1, 'text': 'Test result 1'},
        {'page': 2, 'text': 'Test result 2'},
      ];

      when(pdfService.searchText('test')).thenAnswer((_) async => testSearchResults);

      // Act
      final results = await pdfService.searchText('test');

      // Assert
      expect(results, testSearchResults);
      expect(results.length, 2);
      expect(results[0]['page'], 1);
      expect(results[1]['page'], 2);
      verify(pdfService.searchText('test')).called(1);
    });

    test('PDF 파일 닫기가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      when(pdfService.closePDF()).thenAnswer((_) async => true);

      // Act
      final result = await pdfService.closePDF();

      // Assert
      expect(result, true);
      verify(pdfService.closePDF()).called(1);
    });
  });
} 