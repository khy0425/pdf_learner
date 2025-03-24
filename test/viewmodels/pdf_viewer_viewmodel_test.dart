import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_learner_v2/models/pdf_document.dart';
import 'package:pdf_learner_v2/models/pdf_bookmark.dart' as bookmark;
import 'package:pdf_learner_v2/viewmodels/pdf_viewer_viewmodel.dart';

@GenerateMocks([PDFViewController])
void main() {
  late PdfViewerViewModel viewModel;
  late MockPDFViewController mockController;

  setUp(() {
    mockController = MockPDFViewController();
    viewModel = PdfViewerViewModel();
  });

  group('PdfViewerViewModel Tests', () {
    test('Initial state', () {
      expect(viewModel.currentPage, equals(0));
      expect(viewModel.totalPages, equals(0));
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.controller, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('Set controller', () {
      viewModel.setController(mockController);
      expect(viewModel.controller, equals(mockController));
      expect(viewModel.isLoading, isFalse);
    });

    test('Set error', () {
      const testError = 'Test error message';
      viewModel.setError(testError);
      expect(viewModel.errorMessage, equals(testError));
      expect(viewModel.isLoading, isFalse);
    });

    test('Page navigation', () async {
      viewModel.setController(mockController);
      viewModel.setTotalPages(10);
      
      when(mockController.setPage(4)).thenAnswer((_) => Future.value());
      await viewModel.goToPage(5);
      verify(mockController.setPage(4)).called(1);
      expect(viewModel.currentPage, equals(5));
    });

    test('Zoom controls', () async {
      viewModel.setController(mockController);
      
      when(mockController.setZoomRatio(1.1)).thenAnswer((_) => Future.value());
      await viewModel.zoomIn();
      verify(mockController.setZoomRatio(1.1)).called(1);
      
      when(mockController.setZoomRatio(0.9)).thenAnswer((_) => Future.value());
      await viewModel.zoomOut();
      verify(mockController.setZoomRatio(0.9)).called(1);
      
      when(mockController.setZoomRatio(1.0)).thenAnswer((_) => Future.value());
      await viewModel.resetZoom();
      verify(mockController.setZoomRatio(1.0)).called(1);
    });

    test('Bookmark management', () async {
      const testTitle = 'Test Bookmark';
      const testPage = 1;
      const testYOffset = 100.0;
      
      final bookmarkId = await viewModel.addBookmark(testTitle, testPage, testYOffset);
      expect(bookmarkId, isNotNull);
      expect(viewModel.bookmarks.length, equals(1));
      expect(viewModel.bookmarks.first.title, equals(testTitle));
      expect(viewModel.bookmarks.first.page, equals(testPage));
      expect(viewModel.bookmarks.first.yOffset, equals(testYOffset));
      
      await viewModel.removeBookmark(bookmarkId!);
      expect(viewModel.bookmarks.length, equals(0));
    });
  });
} 