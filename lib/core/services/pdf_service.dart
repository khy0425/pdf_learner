import 'dart:io';

/// PDF 서비스 인터페이스
/// 
/// PDF 파일의 열기, 닫기, 페이지 이동, 렌더링 등의 기능을 제공합니다.
abstract class PDFService {
  /// PDF 파일을 엽니다.
  Future<bool> openPDF(File file);

  /// 현재 열린 PDF 파일의 총 페이지 수를 반환합니다.
  Future<int> getPageCount();

  /// 현재 페이지 번호를 반환합니다.
  Future<int> getCurrentPage();

  /// 지정된 페이지로 이동합니다.
  Future<bool> goToPage(int pageNumber);

  /// 현재 페이지를 렌더링합니다.
  Future<List<int>> renderPage();

  /// 현재 페이지의 텍스트를 추출합니다.
  Future<String> extractText();

  /// PDF 파일의 메타데이터를 반환합니다.
  Future<Map<String, dynamic>> getMetadata();

  /// PDF 파일 내에서 텍스트를 검색합니다.
  Future<List<Map<String, dynamic>>> searchText(String query);

  /// PDF 파일을 닫습니다.
  Future<bool> closePDF();

  /// 리소스를 해제합니다.
  void dispose();
} 