import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_learner_v2/presentation/widgets/pdf_viewer/pdf_viewer.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewer_viewmodel.dart';

@GenerateMocks([PDFViewerViewModel])
void main() {
  late MockPDFViewerViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockPDFViewerViewModel();
  });

  testWidgets('PDFViewer shows loading indicator when loading',
      (WidgetTester tester) async {
    when(mockViewModel.isLoading).thenReturn(true);
    when(mockViewModel.error).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        home: PDFViewer(
          viewModel: mockViewModel,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('PDFViewer shows error message when error occurs',
      (WidgetTester tester) async {
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.error).thenReturn('Test error');

    await tester.pumpWidget(
      MaterialApp(
        home: PDFViewer(
          viewModel: mockViewModel,
        ),
      ),
    );

    expect(find.text('Test error'), findsOneWidget);
  });

  testWidgets('PDFViewer shows PDF content when loaded',
      (WidgetTester tester) async {
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.error).thenReturn(null);
    when(mockViewModel.currentPage).thenReturn(1);
    when(mockViewModel.totalPages).thenReturn(10);

    await tester.pumpWidget(
      MaterialApp(
        home: PDFViewer(
          viewModel: mockViewModel,
        ),
      ),
    );

    expect(find.text('1 / 10'), findsOneWidget);
  });

  testWidgets('PDFViewer navigation buttons work correctly',
      (WidgetTester tester) async {
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.error).thenReturn(null);
    when(mockViewModel.currentPage).thenReturn(2);
    when(mockViewModel.totalPages).thenReturn(10);

    await tester.pumpWidget(
      MaterialApp(
        home: PDFViewer(
          viewModel: mockViewModel,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    verify(mockViewModel.previousPage()).called(1);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    verify(mockViewModel.nextPage()).called(1);
  });
} 