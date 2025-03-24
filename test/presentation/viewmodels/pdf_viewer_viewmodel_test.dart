import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pdf_learner_v2/domain/entities/pdf_document.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/domain/entities/pdf_bookmark.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewer_viewmodel.dart';

@GenerateMocks([PDFRepository])
import 'pdf_viewer_viewmodel_test.mocks.dart';

void main() {
  late PDFViewerViewModel viewModel;
  late MockPDFRepository mockRepository;

  setUp(() {
    mockRepository = MockPDFRepository();
    viewModel = PDFViewerViewModel(repository: mockRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('PDFViewerViewModel', () {
    test('loadDocument - 성공', () async {
      // Arrange
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test.pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        lastReadPage: 0,
        totalPages: 10,
      );
      when(mockRepository.getDocument('1')).thenAnswer((_) async => document);

      // Act
      await viewModel.loadDocument('1');

      // Assert
      expect(viewModel.currentDocument, equals(document));
      expect(viewModel.isLoading, equals(false));
      expect(viewModel.error, isNull);
      verify(mockRepository.getDocument('1')).called(1);
    });

    test('loadDocument - 실패', () async {
      // Arrange
      when(mockRepository.getDocument('1')).thenThrow(Exception('Failed to load'));

      // Act
      await viewModel.loadDocument('1');

      // Assert
      expect(viewModel.currentDocument, isNull);
      expect(viewModel.isLoading, equals(false));
      expect(viewModel.error, equals('Failed to load'));
      verify(mockRepository.getDocument('1')).called(1);
    });

    test('toggleFavorite - 성공', () async {
      // Arrange
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test.pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        lastReadPage: 0,
        totalPages: 10,
      );
      viewModel.currentDocument = document;
      when(mockRepository.updateDocument(any)).thenAnswer((_) async => true);

      // Act
      await viewModel.toggleFavorite();

      // Assert
      expect(viewModel.currentDocument?.isFavorite, equals(true));
      verify(mockRepository.updateDocument(any)).called(1);
    });

    test('addBookmark - 성공', () async {
      // Arrange
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test.pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        lastReadPage: 0,
        totalPages: 10,
      );
      viewModel.currentDocument = document;
      when(mockRepository.addBookmark(any)).thenAnswer((_) async => true);

      // Act
      await viewModel.addBookmark(1, 'Test Bookmark');

      // Assert
      expect(viewModel.bookmarks.length, equals(1));
      expect(viewModel.bookmarks.first.pageNumber, equals(1));
      expect(viewModel.bookmarks.first.title, equals('Test Bookmark'));
      verify(mockRepository.addBookmark(any)).called(1);
    });

    test('deleteBookmark - 성공', () async {
      // Arrange
      final bookmark = PDFBookmark(
        id: '1',
        documentId: '1',
        pageNumber: 1,
        title: 'Test Bookmark',
        createdAt: DateTime.now(),
      );
      viewModel.bookmarks = [bookmark];
      when(mockRepository.deleteBookmark('1')).thenAnswer((_) async => true);

      // Act
      await viewModel.deleteBookmark('1');

      // Assert
      expect(viewModel.bookmarks, isEmpty);
      verify(mockRepository.deleteBookmark('1')).called(1);
    });

    test('loadPage - 메모리 관리', () async {
      // Arrange
      final document = PDFDocument(
        id: '1',
        title: 'Test Document',
        filePath: '/test.pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        lastReadPage: 0,
        totalPages: 10,
      );
      viewModel.currentDocument = document;

      // Act
      await viewModel.loadPage(1);

      // Assert
      expect(viewModel.currentPage, equals(1));
      expect(viewModel.pageCache.length, lessThanOrEqualTo(PDFViewerViewModel.maxPageCacheSize));
    });
  });
} 