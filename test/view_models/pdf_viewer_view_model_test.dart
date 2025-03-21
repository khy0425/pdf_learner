import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/pdf_viewer_view_model_mock.dart';
import '../mocks/home_view_model_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late MockPdfViewerViewModel pdfViewerViewModel;
  late PdfFileModel testPdfFile;
  
  setUp(() {
    // 테스트용 PDF 파일 생성
    testPdfFile = PdfFileModel(
      id: 'test-pdf-1',
      name: '테스트용 PDF.pdf',
      path: '/path/to/test.pdf',
      size: 1024 * 1024, // 1MB
      createdAt: DateTime.now(),
      pageCount: 15,
    );
    
    pdfViewerViewModel = MockPdfViewerViewModel(pdfFile: testPdfFile);
  });
  
  group('PDF 뷰어 초기화 테스트', () {
    test('초기 상태 확인', () async {
      // 비동기 초기화 완료 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      expect(pdfViewerViewModel.isLoading, isFalse);
      expect(pdfViewerViewModel.error, isNull);
      expect(pdfViewerViewModel.currentPage, 1);
      expect(pdfViewerViewModel.pageCount, 15);
      expect(pdfViewerViewModel.isTextExtractionComplete, isTrue);
      expect(pdfViewerViewModel.pages, isNotEmpty);
      expect(pdfViewerViewModel.zoomLevel, 1.0);
    });
  });
  
  group('페이지 탐색 테스트', () {
    test('페이지 직접 이동', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 초기 페이지 확인
      expect(pdfViewerViewModel.currentPage, 1);
      
      // 특정 페이지로 이동
      pdfViewerViewModel.goToPage(5);
      expect(pdfViewerViewModel.currentPage, 5);
      
      // 범위를 벗어난 페이지 요청 (처리되지 않아야 함)
      pdfViewerViewModel.goToPage(100);
      expect(pdfViewerViewModel.currentPage, 5, reason: '범위를 벗어난 페이지 요청은 무시되어야 함');
      
      pdfViewerViewModel.goToPage(0);
      expect(pdfViewerViewModel.currentPage, 5, reason: '범위를 벗어난 페이지 요청은 무시되어야 함');
    });
    
    test('다음/이전 페이지 이동', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 초기 페이지 확인
      expect(pdfViewerViewModel.currentPage, 1);
      
      // 다음 페이지로 이동
      pdfViewerViewModel.nextPage();
      expect(pdfViewerViewModel.currentPage, 2);
      
      // 다시 다음 페이지로 이동
      pdfViewerViewModel.nextPage();
      expect(pdfViewerViewModel.currentPage, 3);
      
      // 이전 페이지로 이동
      pdfViewerViewModel.previousPage();
      expect(pdfViewerViewModel.currentPage, 2);
      
      // 처음 페이지로 이동
      pdfViewerViewModel.goToPage(1);
      
      // 이전 페이지 시도 (범위를 벗어남)
      pdfViewerViewModel.previousPage();
      expect(pdfViewerViewModel.currentPage, 1, reason: '첫 페이지에서 이전 페이지 요청은 무시되어야 함');
      
      // 마지막 페이지로 이동
      pdfViewerViewModel.goToPage(15);
      
      // 다음 페이지 시도 (범위를 벗어남)
      pdfViewerViewModel.nextPage();
      expect(pdfViewerViewModel.currentPage, 15, reason: '마지막 페이지에서 다음 페이지 요청은 무시되어야 함');
    });
  });
  
  group('북마크 및 주석 테스트', () {
    test('북마크 토글', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 6번째 페이지는 북마크가 초기에 이미 되어 있음을 확인 (인덱스는 5)
      expect(pdfViewerViewModel.pages[6 - 1].isBookmarked, isTrue);
      
      // 6번째 페이지 북마크 토글 (해제)
      await pdfViewerViewModel.toggleBookmark(6);
      
      // 토글 후 북마크 비활성화 확인
      expect(pdfViewerViewModel.pages[6 - 1].isBookmarked, isFalse);
      
      // 다시 토글하여 북마크 활성화
      await pdfViewerViewModel.toggleBookmark(6);
      expect(pdfViewerViewModel.pages[6 - 1].isBookmarked, isTrue);
      
      // 7번째 페이지는 북마크가 되어 있지 않아야 함
      expect(pdfViewerViewModel.pages[7 - 1].isBookmarked, isFalse);
      
      // 범위를 벗어난 페이지 토글 시도
      final bookmarkedPagesBeforeInvalidToggle = pdfViewerViewModel.pages
          .where((page) => page.isBookmarked)
          .length;
      
      await pdfViewerViewModel.toggleBookmark(100);
      
      final bookmarkedPagesAfterInvalidToggle = pdfViewerViewModel.pages
          .where((page) => page.isBookmarked)
          .length;
      
      expect(bookmarkedPagesAfterInvalidToggle, equals(bookmarkedPagesBeforeInvalidToggle),
          reason: '범위를 벗어난 페이지 북마크 요청은 무시되어야 함');
    });
    
    test('주석 추가', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 3번째 페이지 주석 확인
      final initialAnnotationCount = pdfViewerViewModel.pages[3 - 1].annotations.length;
      
      // 주석 추가
      await pdfViewerViewModel.addAnnotation(3, '새로운 주석입니다.');
      
      // 추가 후 확인
      expect(pdfViewerViewModel.pages[3 - 1].annotations.length, initialAnnotationCount + 1);
      expect(pdfViewerViewModel.pages[3 - 1].annotations.last, equals('새로운 주석입니다.'));
    });
    
    test('하이라이트 추가', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 4번째 페이지 하이라이트 확인
      final initialHighlightCount = pdfViewerViewModel.pages[4 - 1].highlights.length;
      
      // 하이라이트 추가
      await pdfViewerViewModel.addHighlight(4, '중요한 내용입니다.');
      
      // 추가 후 확인
      expect(pdfViewerViewModel.pages[4 - 1].highlights.length, initialHighlightCount + 1);
      expect(pdfViewerViewModel.pages[4 - 1].highlights.last, equals('중요한 내용입니다.'));
    });
  });
  
  group('요약 생성 테스트', () {
    test('요약 생성', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 초기 요약 상태 확인
      expect(pdfViewerViewModel.summary, isNull);
      
      // 요약 생성
      await pdfViewerViewModel.generateSummary();
      
      // 생성 후 확인
      expect(pdfViewerViewModel.summary, isNotNull);
      expect(pdfViewerViewModel.summary!.content, contains('테스트용 PDF.pdf'));
      expect(pdfViewerViewModel.summary!.content, contains('15 페이지'));
      expect(pdfViewerViewModel.summary!.apiModel, equals('gemini-pro'));
    });
  });
  
  group('확대/축소 테스트', () {
    test('확대/축소 레벨 설정', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 초기 확대 레벨 확인
      expect(pdfViewerViewModel.zoomLevel, 1.0);
      
      // 확대
      pdfViewerViewModel.setZoomLevel(1.5);
      expect(pdfViewerViewModel.zoomLevel, 1.5);
      
      // 축소
      pdfViewerViewModel.setZoomLevel(0.8);
      expect(pdfViewerViewModel.zoomLevel, 0.8);
      
      // 범위를 벗어난 값 (최소값 제한)
      pdfViewerViewModel.setZoomLevel(0.3);
      expect(pdfViewerViewModel.zoomLevel, 0.8, reason: '최소 확대 레벨(0.5) 미만은 무시되어야 함');
      
      // 범위를 벗어난 값 (최대값 제한)
      pdfViewerViewModel.setZoomLevel(3.5);
      expect(pdfViewerViewModel.zoomLevel, 0.8, reason: '최대 확대 레벨(3.0) 초과는 무시되어야 함');
    });
  });
  
  group('오류 처리 테스트', () {
    test('오류 설정 및 초기화', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 350));
      
      // 초기 오류 상태 확인
      expect(pdfViewerViewModel.error, isNull);
      
      // 오류 설정
      pdfViewerViewModel.setError('PDF 로딩 중 오류가 발생했습니다.');
      expect(pdfViewerViewModel.error, equals('PDF 로딩 중 오류가 발생했습니다.'));
      
      // 오류 초기화
      pdfViewerViewModel.clearError();
      expect(pdfViewerViewModel.error, isNull);
    });
  });
} 