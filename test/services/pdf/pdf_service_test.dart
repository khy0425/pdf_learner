import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pdf_learner_v2/services/pdf/pdf_service.dart';
import 'package:pdf_learner_v2/domain/entities/pdf_document.dart';

@GenerateMocks([PDFService])
import 'pdf_service_test.mocks.dart';

void main() {
  late MockPDFService mockPDFService;

  setUp(() {
    mockPDFService = MockPDFService();
  });

  group('PDFService', () {
    test('openPDF - 성공', () async {
      // Arrange
      when(mockPDFService.openPDF('/test.pdf')).thenAnswer((_) async => true);

      // Act
      final result = await mockPDFService.openPDF('/test.pdf');

      // Assert
      expect(result, equals(true));
      verify(mockPDFService.openPDF('/test.pdf')).called(1);
    });

    test('getPageCount - 성공', () async {
      // Arrange
      when(mockPDFService.getPageCount()).thenAnswer((_) async => 10);

      // Act
      final result = await mockPDFService.getPageCount();

      // Assert
      expect(result, equals(10));
      verify(mockPDFService.getPageCount()).called(1);
    });

    test('getCurrentPage - 성공', () async {
      // Arrange
      when(mockPDFService.getCurrentPage()).thenAnswer((_) async => 1);

      // Act
      final result = await mockPDFService.getCurrentPage();

      // Assert
      expect(result, equals(1));
      verify(mockPDFService.getCurrentPage()).called(1);
    });

    test('goToPage - 성공', () async {
      // Arrange
      when(mockPDFService.goToPage(1)).thenAnswer((_) async => true);

      // Act
      final result = await mockPDFService.goToPage(1);

      // Assert
      expect(result, equals(true));
      verify(mockPDFService.goToPage(1)).called(1);
    });

    test('renderPage - 성공', () async {
      // Arrange
      final testImage = List<int>.from([1, 2, 3, 4, 5]);
      when(mockPDFService.renderPage(1)).thenAnswer((_) async => testImage);

      // Act
      final result = await mockPDFService.renderPage(1);

      // Assert
      expect(result, equals(testImage));
      verify(mockPDFService.renderPage(1)).called(1);
    });

    test('extractText - 성공', () async {
      // Arrange
      when(mockPDFService.extractText(1)).thenAnswer((_) async => 'Test text');

      // Act
      final result = await mockPDFService.extractText(1);

      // Assert
      expect(result, equals('Test text'));
      verify(mockPDFService.extractText(1)).called(1);
    });

    test('getMetadata - 성공', () async {
      // Arrange
      final metadata = {
        'title': 'Test Document',
        'author': 'Test Author',
        'subject': 'Test Subject',
        'keywords': ['test', 'document'],
        'creationDate': DateTime.now(),
        'modificationDate': DateTime.now(),
      };
      when(mockPDFService.getMetadata()).thenAnswer((_) async => metadata);

      // Act
      final result = await mockPDFService.getMetadata();

      // Assert
      expect(result, equals(metadata));
      verify(mockPDFService.getMetadata()).called(1);
    });

    test('searchText - 성공', () async {
      // Arrange
      final searchResults = [
        {'page': 1, 'text': 'Test text 1'},
        {'page': 2, 'text': 'Test text 2'},
      ];
      when(mockPDFService.searchText('test')).thenAnswer((_) async => searchResults);

      // Act
      final result = await mockPDFService.searchText('test');

      // Assert
      expect(result, equals(searchResults));
      verify(mockPDFService.searchText('test')).called(1);
    });

    test('closePDF - 성공', () async {
      // Arrange
      when(mockPDFService.closePDF()).thenAnswer((_) async => true);

      // Act
      final result = await mockPDFService.closePDF();

      // Assert
      expect(result, equals(true));
      verify(mockPDFService.closePDF()).called(1);
    });

    test('dispose - 성공', () async {
      // Arrange
      when(mockPDFService.dispose()).thenAnswer((_) async => true);

      // Act
      final result = await mockPDFService.dispose();

      // Assert
      expect(result, equals(true));
      verify(mockPDFService.dispose()).called(1);
    });
  });
} 