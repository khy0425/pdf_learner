import 'dart:typed_data';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';

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
} 