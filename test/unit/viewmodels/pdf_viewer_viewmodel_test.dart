import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/core/services/pdf_service.dart';
import 'package:pdf_learner_v2/data/datasources/pdf_local_datasource.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewer_viewmodel.dart';

@GenerateMocks([PDFRepository, PDFService, PDFLocalDataSource])
void main() {
  late PDFViewerViewModel viewModel;
  late MockPDFRepository mockRepository;
  late MockPDFService mockPdfService;
  late MockPDFLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRepository = MockPDFRepository();
    mockPdfService = MockPDFService();
    mockLocalDataSource = MockPDFLocalDataSource();

    viewModel = PDFViewerViewModel(
      repository: mockRepository,
      pdfService: mockPdfService,
      localDataSource: mockLocalDataSource,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('PDFViewerViewModel', () {
    test('초기 상태가 올바르게 설정되어야 합니다', () {
      expect(viewModel.state, PDFViewerState.initial);
      expect(viewModel.error, PDFViewerError.none);
      expect(viewModel.errorMessage, '');
      expect(viewModel.document, null);
      expect(viewModel.currentPage, 1);
      expect(viewModel.totalPages, 0);
      expect(viewModel.isLoading, false);
      expect(viewModel.bookmarks, isEmpty);
    });

    test('문서 로드 성공 시 상태가 올바르게 업데이트되어야 합니다', () async {
      // Arrange
      final testDocument = PDFDocument(
        id: 'test_id',
        title: 'Test Document',
        filePath: 'test_path',
        thumbnailPath: 'test_thumbnail',
        totalPages: 10,
        currentPage: 1,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookmarks: [],
      );

      when(mockRepository.getDocument('test_id')).thenAnswer((_) async => testDocument);

      // Act
      await viewModel.loadDocument('test_id');

      // Assert
      expect(viewModel.state, PDFViewerState.loaded);
      expect(viewModel.document, testDocument);
      expect(viewModel.totalPages, 10);
      expect(viewModel.currentPage, 1);
      expect(viewModel.error, PDFViewerError.none);
    });

    test('문서 로드 실패 시 에러 상태가 설정되어야 합니다', () async {
      // Arrange
      when(mockRepository.getDocument('test_id')).thenThrow(Exception('Load failed'));

      // Act
      await viewModel.loadDocument('test_id');

      // Assert
      expect(viewModel.state, PDFViewerState.error);
      expect(viewModel.error, PDFViewerError.loadFailed);
      expect(viewModel.errorMessage, contains('Load failed'));
    });

    test('페이지 변경이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      when(mockPdfService.goToPage(2)).thenAnswer((_) async => true);

      // Act
      await viewModel.changePage(2);

      // Assert
      expect(viewModel.currentPage, 2);
      verify(mockPdfService.goToPage(2)).called(1);
    });

    test('북마크 추가가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testDocument = PDFDocument(
        id: 'test_id',
        title: 'Test Document',
        filePath: 'test_path',
        thumbnailPath: 'test_thumbnail',
        totalPages: 10,
        currentPage: 1,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookmarks: [],
      );

      when(mockLocalDataSource.saveBookmark(any, any)).thenAnswer((_) async => true);

      // Act
      await viewModel.loadDocument('test_id');
      await viewModel.addBookmark(note: 'Test bookmark');

      // Assert
      expect(viewModel.bookmarks.length, 1);
      expect(viewModel.bookmarks.first.note, 'Test bookmark');
      verify(mockLocalDataSource.saveBookmark(any, any)).called(1);
    });

    test('북마크 삭제가 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testBookmark = PDFBookmark(
        id: 'bookmark_id',
        documentId: 'test_id',
        pageNumber: 1,
        note: 'Test bookmark',
        createdAt: DateTime.now(),
      );

      when(mockLocalDataSource.deleteBookmark(any, any)).thenAnswer((_) async => true);
      viewModel._bookmarks.add(testBookmark);

      // Act
      await viewModel.deleteBookmark('bookmark_id');

      // Assert
      expect(viewModel.bookmarks, isEmpty);
      verify(mockLocalDataSource.deleteBookmark(any, any)).called(1);
    });

    test('즐겨찾기 토글이 성공적으로 이루어져야 합니다', () async {
      // Arrange
      final testDocument = PDFDocument(
        id: 'test_id',
        title: 'Test Document',
        filePath: 'test_path',
        thumbnailPath: 'test_thumbnail',
        totalPages: 10,
        currentPage: 1,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookmarks: [],
      );

      when(mockLocalDataSource.updateDocument(any)).thenAnswer((_) async => true);

      // Act
      await viewModel.loadDocument('test_id');
      await viewModel.toggleFavorite();

      // Assert
      expect(viewModel.document?.isFavorite, true);
      verify(mockLocalDataSource.updateDocument(any)).called(1);
    });
  });
} 