import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/data/repositories/pdf_repository_impl.dart';

import 'pdf_repository_test.mocks.dart';

@GenerateMocks([PDFRepository])
void main() {
  late PDFRepositoryImpl repository;
  late MockPDFRepository mockRepository;

  setUp(() {
    mockRepository = MockPDFRepository();
    repository = PDFRepositoryImpl(mockRepository);
  });

  group('PDFRepositoryImpl', () {
    test('getDocuments returns list of documents', () async {
      final documents = [
        PDFDocument(
          id: '1',
          title: 'Test Document',
          filePath: '/test/path',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          totalPages: 10,
        ),
      ];

      when(mockRepository.getDocuments()).thenAnswer((_) async => documents);

      final result = await repository.getDocuments();

      expect(result, documents);
      verify(mockRepository.getDocuments()).called(1);
    });

    test('getDocument returns single document', () async {
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test/path',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalPages: 10,
      );

      when(mockRepository.getDocument('1')).thenAnswer((_) async => document);

      final result = await repository.getDocument('1');

      expect(result, document);
      verify(mockRepository.getDocument('1')).called(1);
    });

    test('addDocument adds new document', () async {
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test/path',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalPages: 10,
      );

      when(mockRepository.addDocument(document)).thenAnswer((_) async => document);

      final result = await repository.addDocument(document);

      expect(result, document);
      verify(mockRepository.addDocument(document)).called(1);
    });

    test('updateDocument updates existing document', () async {
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test/path',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalPages: 10,
      );

      when(mockRepository.updateDocument(document)).thenAnswer((_) async => document);

      final result = await repository.updateDocument(document);

      expect(result, document);
      verify(mockRepository.updateDocument(document)).called(1);
    });

    test('deleteDocument deletes document', () async {
      when(mockRepository.deleteDocument('1')).thenAnswer((_) async => true);

      final result = await repository.deleteDocument('1');

      expect(result, true);
      verify(mockRepository.deleteDocument('1')).called(1);
    });
  });
} 