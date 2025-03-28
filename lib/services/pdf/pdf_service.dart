import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../core/base/result.dart';

/// PDF 서비스 인터페이스
/// 
/// PDF 문서의 렌더링, 탐색, 텍스트 추출 등의 기능을 제공하는 서비스입니다.
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

/// PDF 서비스 기본 구현체
@Injectable(as: PDFService)
class PDFServiceImpl implements PDFService {
  // PDF 문서를 캐시하기 위한 맵
  final Map<String, PDFDocument> _documentCache = {};
  String? _currentFilePath;
  int _pageCount = 0;
  int _currentPage = 0;
  
  @override
  Future<PDFDocument> openDocument(String filePath) async {
    try {
      if (_documentCache.containsKey(filePath)) {
        return _documentCache[filePath]!;
      }
      
      final document = await _loadDocument(filePath);
      _documentCache[filePath] = document;
      _currentFilePath = filePath;
      _pageCount = await getPageCount(filePath);
      _currentPage = 1;
      return document;
    } catch (e) {
      debugPrint('PDF 문서 열기 실패: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> closeDocument(String id) async {
    _documentCache.remove(id);
  }
  
  @override
  Future<Uint8List> renderPage(String id, int pageNumber, {int width = 800, int height = 1200}) async {
    // 실제 구현은 프로젝트의 요구 사항에 따라 다를 수 있습니다.
    throw UnimplementedError('이 기능은 아직 구현되지 않았습니다.');
  }
  
  @override
  Future<Uint8List> generateThumbnail(String id) async {
    // 실제 구현은 프로젝트의 요구 사항에 따라 다를 수 있습니다.
    throw UnimplementedError('이 기능은 아직 구현되지 않았습니다.');
  }
  
  @override
  Future<String> extractText(String id, int pageNumber) async {
    try {
      final pdfDoc = await _getPdfDocument(id);
      if (pdfDoc == null) {
        throw Exception('PDF 문서를 찾을 수 없습니다.');
      }
      
      if (pageNumber < 0 || pageNumber >= pdfDoc.pages.count) {
        throw Exception('유효하지 않은 페이지 번호입니다.');
      }
      
      final pdfTextExtractor = PdfTextExtractor(pdfDoc);
      final text = pdfTextExtractor.extractText(startPageIndex: pageNumber);
      return text;
    } catch (e) {
      debugPrint('PDF 텍스트 추출 중 오류: $e');
      return '';
    }
  }
  
  @override
  Future<Map<String, dynamic>> extractMetadata(String id) async {
    try {
      final pdfDoc = await _getPdfDocument(id);
      if (pdfDoc == null) {
        throw Exception('PDF 문서를 찾을 수 없습니다.');
      }
      
      final metadata = <String, dynamic>{
        'pageCount': pdfDoc.pages.count,
        'isEncrypted': pdfDoc.security.userPassword.isNotEmpty,
      };
      
      // 문서 정보 추출
      if (pdfDoc.documentInformation != null) {
        final info = pdfDoc.documentInformation;
        metadata['title'] = info.title;
        metadata['author'] = info.author;
        metadata['subject'] = info.subject;
        metadata['keywords'] = info.keywords;
        metadata['creator'] = info.creator;
        metadata['producer'] = info.producer;
        metadata['creationDate'] = info.creationDate?.toString();
        metadata['modificationDate'] = info.modificationDate?.toString();
      }
      
      return metadata;
    } catch (e) {
      debugPrint('PDF 메타데이터 가져오기 중 오류: $e');
      return {};
    }
  }
  
  @override
  Future<int> getPageCount(String id) async {
    try {
      final pdfDoc = await _getPdfDocument(id);
      if (pdfDoc == null) {
        throw Exception('PDF 문서를 찾을 수 없습니다.');
      }
      
      return pdfDoc.pages.count;
    } catch (e) {
      debugPrint('PDF 페이지 수 가져오기 중 오류: $e');
      return 0;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchText(String id, String query) async {
    try {
      final pdfDoc = await _getPdfDocument(id);
      if (pdfDoc == null) {
        throw Exception('PDF 문서를 찾을 수 없습니다.');
      }
      
      final pageCount = pdfDoc.pages.count;
      final results = <Map<String, dynamic>>[];
      
      for (var i = 0; i < pageCount; i++) {
        final extractor = PdfTextExtractor(pdfDoc);
        final text = extractor.extractText(startPageIndex: i);
        
        if (text.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'page': i,
            'text': text,
          });
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('PDF 텍스트 검색 중 오류: $e');
      return [];
    }
  }
  
  @override
  void dispose() {
    _documentCache.clear();
    _currentFilePath = null;
    _pageCount = 0;
    _currentPage = 0;
  }
  
  /// 문서 로드 헬퍼 메서드
  Future<PDFDocument> _loadDocument(String filePath) async {
    try {
      Uint8List? bytes;
      
      if (filePath.startsWith('http')) {
        // URL인 경우 다운로드
        final response = await HttpClient().getUrl(Uri.parse(filePath));
        final HttpClientResponse httpResponse = await response.close();
        final bytesList = await httpResponse.toList();
        bytes = Uint8List.fromList(bytesList.expand((x) => x).toList());
      } else {
        // 로컬 파일인 경우
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          throw Exception('파일을 찾을 수 없습니다.');
        }
      }
      
      if (bytes == null) {
        throw Exception('PDF 파일을 읽을 수 없습니다.');
      }
      
      // Syncfusion PDF 라이브러리로 PDF 문서 열기
      final pdfDoc = PdfDocument(inputBytes: bytes);
      
      // PDFDocument 객체 생성
      final pdfDocument = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: path.basename(filePath),
        description: path.basename(filePath),
        filePath: filePath,
        downloadUrl: '',
        pageCount: pdfDoc.pages.count,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PDFDocumentStatus.downloaded,
      );
      
      return pdfDocument;
    } catch (e) {
      debugPrint('PDF 문서 로드 중 오류: $e');
      rethrow;
    }
  }
  
  /// PdfDocument 인스턴스 가져오기
  Future<PdfDocument?> _getPdfDocument(String id) async {
    if (!_documentCache.containsKey(id)) {
      return null;
    }
    
    final document = _documentCache[id]!;
    final filePath = document.filePath;
    
    try {
      Uint8List? bytes;
      
      if (filePath.startsWith('http')) {
        // URL인 경우 다운로드
        final response = await HttpClient().getUrl(Uri.parse(filePath));
        final HttpClientResponse httpResponse = await response.close();
        final bytesList = await httpResponse.toList();
        bytes = Uint8List.fromList(bytesList.expand((x) => x).toList());
      } else {
        // 로컬 파일인 경우
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          throw Exception('파일을 찾을 수 없습니다.');
        }
      }
      
      if (bytes == null) {
        throw Exception('PDF 파일을 읽을 수 없습니다.');
      }
      
      return PdfDocument(inputBytes: bytes);
    } catch (e) {
      debugPrint('PdfDocument 가져오기 중 오류: $e');
      return null;
    }
  }

  @override
  Future<Result<String>> downloadPdf(String url) async {
    if (url.isEmpty) {
      return Result.failure(Exception('다운로드 URL이 비어 있습니다'));
    }
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        return Result.failure(Exception('PDF 다운로드 실패: 상태 코드 ${response.statusCode}'));
      }
      
      final bytes = response.bodyBytes;
      final fileName = const Uuid().v4() + '.pdf';
      
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return Result.success(filePath);
    } catch (e) {
      return Result.failure(Exception('PDF 다운로드 실패: $e'));
    }
  }
} 