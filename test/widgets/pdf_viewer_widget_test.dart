import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewer_viewmodel.dart';
import 'package:pdf_learner_v2/presentation/widgets/pdf_viewer.dart';

void main() {
  group('PDF 뷰어 위젯 테스트', () {
    late PDFViewerViewModel viewModel;

    setUp(() {
      viewModel = PDFViewerViewModel(
        pdfService: null, // 실제 서비스 대신 null 사용
        pdfLocalDataSource: null, // 실제 데이터소스 대신 null 사용
      );
    });

    testWidgets('기본 UI 요소 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const PDFViewer(),
          ),
        ),
      );

      // 기본 UI 요소 확인
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('로딩 상태 표시 테스트', (WidgetTester tester) async {
      // 로딩 상태로 설정
      viewModel.setLoading(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const PDFViewer(),
          ),
        ),
      );

      // 로딩 인디케이터 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('에러 상태 표시 테스트', (WidgetTester tester) async {
      // 에러 상태로 설정
      viewModel.setError(PDFViewerError.loadFailed);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const PDFViewer(),
          ),
        ),
      );

      // 에러 메시지 확인
      expect(find.text('문서를 불러오는데 실패했습니다.'), findsOneWidget);
    });

    testWidgets('페이지 네비게이션 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const PDFViewer(),
          ),
        ),
      );

      // 이전/다음 페이지 버튼 확인
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });
} 