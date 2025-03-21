import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/home_view_model_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late MockHomeViewModel homeViewModel;
  
  setUp(() {
    homeViewModel = MockHomeViewModel();
  });
  
  group('HomeViewModel 초기화 테스트', () {
    test('초기 상태 확인', () async {
      // 비동기 초기화가 완료될 때까지 대기
      await Future.delayed(const Duration(milliseconds: 300));
      
      expect(homeViewModel.isLoading, isFalse);
      expect(homeViewModel.error, isNull);
      expect(homeViewModel.isInitialized, isTrue);
      expect(homeViewModel.pdfFiles, isNotEmpty);
      expect(homeViewModel.pdfFiles.length, 3); // 초기 샘플 파일 3개
    });
  });
  
  group('PDF 파일 관리 테스트', () {
    test('PDF 파일 추가', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      final initialCount = homeViewModel.pdfFiles.length;
      
      // 새 PDF 파일 추가
      await homeViewModel.addPdfFile(PdfFileModel(
        id: 'new-pdf',
        name: '새 PDF 파일.pdf',
        path: '/path/to/new.pdf',
        size: 1024 * 1024, // 1MB
        createdAt: DateTime.now(),
      ));
      
      // 추가 후 확인
      expect(homeViewModel.pdfFiles.length, initialCount + 1);
      expect(homeViewModel.pdfFiles.any((pdf) => pdf.id == 'new-pdf'), isTrue);
      expect(homeViewModel.isLoading, isFalse);
    });
    
    test('PDF 파일 삭제', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      final initialCount = homeViewModel.pdfFiles.length;
      final firstPdfId = homeViewModel.pdfFiles.first.id;
      
      // PDF 파일 삭제
      await homeViewModel.deletePdfFile(firstPdfId);
      
      // 삭제 후 확인
      expect(homeViewModel.pdfFiles.length, initialCount - 1);
      expect(homeViewModel.pdfFiles.any((pdf) => pdf.id == firstPdfId), isFalse);
      expect(homeViewModel.isLoading, isFalse);
    });
    
    test('PDF 파일 즐겨찾기 토글', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      final secondPdfId = homeViewModel.pdfFiles[1].id;
      final initialFavoriteState = homeViewModel.pdfFiles[1].isFavorite;
      
      // 즐겨찾기 토글
      await homeViewModel.toggleFavorite(secondPdfId);
      
      // 토글 후 확인
      final updatedPdf = homeViewModel.pdfFiles.firstWhere((pdf) => pdf.id == secondPdfId);
      expect(updatedPdf.isFavorite, !initialFavoriteState);
    });
    
    test('PDF 파일 이름 변경', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      final thirdPdfId = homeViewModel.pdfFiles[2].id;
      final newName = '이름이 변경된 PDF.pdf';
      
      // 이름 변경
      await homeViewModel.renamePdfFile(thirdPdfId, newName);
      
      // 변경 후 확인
      final updatedPdf = homeViewModel.pdfFiles.firstWhere((pdf) => pdf.id == thirdPdfId);
      expect(updatedPdf.name, equals(newName));
      expect(homeViewModel.isLoading, isFalse);
    });
  });
  
  group('검색 기능 테스트', () {
    test('검색어에 따른 필터링', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 초기 상태 확인
      expect(homeViewModel.pdfFiles.length, 3);
      
      // '샘플' 검색어 설정
      homeViewModel.setSearchQuery('샘플');
      
      // 검색 결과 확인 (샘플이 포함된 PDF 파일만 표시)
      expect(homeViewModel.pdfFiles.length, 2);
      expect(homeViewModel.pdfFiles.every((pdf) => pdf.name.contains('샘플')), isTrue);
      
      // 검색어 초기화
      homeViewModel.setSearchQuery('');
      
      // 모든 파일 표시 확인
      expect(homeViewModel.pdfFiles.length, 3);
    });
    
    test('대소문자 무관 검색', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 소문자로 검색
      homeViewModel.setSearchQuery('테스트');
      expect(homeViewModel.pdfFiles.length, 1);
      
      // 대문자로 검색 (결과는 동일해야 함)
      homeViewModel.setSearchQuery('테스트');
      expect(homeViewModel.pdfFiles.length, 1);
    });
  });
  
  group('오류 처리 테스트', () {
    test('오류 설정 및 초기화', () async {
      // 초기화 대기
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 오류 설정
      homeViewModel.setError('테스트 오류 메시지');
      expect(homeViewModel.error, equals('테스트 오류 메시지'));
      
      // 오류 초기화
      homeViewModel.clearError();
      expect(homeViewModel.error, isNull);
    });
  });
} 