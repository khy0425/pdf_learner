import 'package:pdf_learner_v2/domain/models/pdf_document.dart';

/// PDF 서비스 인터페이스
abstract class PDFService {
  /// PDF 문서를 열어서 읽습니다.
  Future<PDFDocument> openDocument(String filePath);
  
  /// PDF 문서를 닫습니다.
  Future<void> closeDocument(String id);
  
  /// PDF 문서의 페이지를 렌더링합니다.
  Future<List<int>> renderPage(String id, int pageNumber);
  
  /// PDF 문서의 썸네일을 생성합니다.
  Future<List<int>> generateThumbnail(String id);
  
  /// PDF 문서의 텍스트를 추출합니다.
  Future<String> extractText(String id, int pageNumber);
  
  /// PDF 문서의 메타데이터를 추출합니다.
  Future<Map<String, dynamic>> extractMetadata(String id);
  
  /// PDF 문서를 암호화합니다.
  Future<void> encryptDocument(String id, String password);
  
  /// PDF 문서를 복호화합니다.
  Future<void> decryptDocument(String id, String password);
  
  /// PDF 문서를 병합합니다.
  Future<PDFDocument> mergeDocuments(List<String> documentIds);
  
  /// PDF 문서를 분할합니다.
  Future<List<PDFDocument>> splitDocument(String id, List<int> pageNumbers);
  
  /// PDF 문서를 회전합니다.
  Future<void> rotateDocument(String id, int rotation);
  
  /// PDF 문서의 페이지를 회전합니다.
  Future<void> rotatePage(String id, int pageNumber, int rotation);
  
  /// PDF 문서의 페이지를 삭제합니다.
  Future<void> deletePage(String id, int pageNumber);
  
  /// PDF 문서의 페이지를 이동합니다.
  Future<void> movePage(String id, int fromPage, int toPage);
} 