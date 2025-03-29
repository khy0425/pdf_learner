import 'dart:typed_data';
import '../models/pdf_document.dart';
import '../../core/base/result.dart';

/// PDF 서비스 인터페이스
abstract class PDFService {
  /// PDF 문서를 열어서 읽습니다.
  Future<PDFDocument> openDocument(String filePath);
  
  /// PDF 문서를 닫습니다.
  Future<void> closeDocument(String id);
  
  /// PDF 문서의 페이지를 렌더링합니다.
  Future<Uint8List> renderPage(String id, int pageNumber, {int width = 800, int height = 1200});
  
  /// PDF 문서의 썸네일을 생성합니다.
  Future<Uint8List> generateThumbnail(String id);
  
  /// PDF 문서의 텍스트를 추출합니다.
  Future<String> extractText(String id, int pageNumber);
  
  /// PDF 문서의 메타데이터를 추출합니다.
  Future<Map<String, dynamic>> extractMetadata(String id);
  
  /// PDF 문서의 총 페이지 수를 가져옵니다.
  Future<int> getPageCount(String id);
  
  /// 문서에서 텍스트를 검색합니다.
  Future<List<Map<String, dynamic>>> searchText(String id, String query);
  
  /// 리소스를 정리합니다.
  void dispose();
  
  /// PDF 파일을 다운로드합니다.
  /// 
  /// [url]에 지정된 URL에서 PDF 파일을 다운로드하여 로컬에 저장합니다.
  /// 성공 시 파일 경로를 포함한 [Result.success]를 반환하고,
  /// 실패 시 오류를 포함한 [Result.failure]를 반환합니다.
  Future<Result<String>> downloadPdf(String url);
} 