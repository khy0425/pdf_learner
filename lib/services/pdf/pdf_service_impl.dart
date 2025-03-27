import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:pdf_learner_v2/core/models/result.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'pdf_service.dart';

/// PDFService 구현체
@Injectable(as: PDFService)
class PDFServiceImpl implements PDFService {
  // PDF 문서 캐싱을 위한 맵
  final Map<String, PDFDocument> _documentCache = {};
  
  // 현재 로드된 파일 정보
  String? _currentFilePath;
  int _pageCount = 0;
  int _currentPage = 0;
  
  // UUID 생성
  final _uuid = const Uuid();
  
  @override
  Future<PDFDocument> openDocument(String filePath) async {
    try {
      if (_documentCache.containsKey(filePath)) {
        return _documentCache[filePath]!;
      }
      
      final tempPdfPath = filePath;
      Uint8List? bytes;
      
      if (filePath.startsWith('http')) {
        // URL인 경우 다운로드
        final uri = Uri.parse(filePath);
        final response = await http.get(uri);
        
        if (response.statusCode != 200) {
          throw Exception('PDF 다운로드 실패: ${response.statusCode}');
        }
        
        bytes = response.bodyBytes;
        
        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${path.basename(filePath)}');
        await tempFile.writeAsBytes(bytes);
        
        tempPdfPath = tempFile.path;
      } else {
        // 로컬 파일 읽기
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('파일을 찾을 수 없습니다: $filePath');
        }
        
        bytes = await file.readAsBytes();
      }
      
      // PDF 문서 열기
      final pdfDoc = PdfDocument(inputBytes: bytes);
      final pageCount = pdfDoc.pages.count;
      
      // PDFDocument 객체 생성
      final uuid = const Uuid();
      final pdfDocument = PDFDocument(
        id: uuid.v4(),
        title: path.basename(tempPdfPath),
        description: path.basename(tempPdfPath),
        filePath: tempPdfPath,
        downloadUrl: '',
        pageCount: pageCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PDFDocumentStatus.downloaded,
      );
      
      _documentCache[filePath] = pdfDocument;
      _currentFilePath = filePath;
      _pageCount = pageCount;
      _currentPage = 0;
      
      return pdfDocument;
    } catch (e) {
      debugPrint('PDF 문서 열기 오류: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> closeDocument(String id) async {
    _documentCache.removeWhere((key, document) => document.id == id);
    
    if (_documentCache.isEmpty) {
      _currentFilePath = null;
      _pageCount = 0;
      _currentPage = 0;
    }
  }
  
  @override
  Future<Uint8List> renderPage(String id, int pageNumber, {int width = 800, int height = 1200}) async {
    // 실제 구현은 프로젝트 요구사항에 따라 달라질 수 있습니다.
    throw UnimplementedError('아직 구현되지 않은 기능입니다.');
  }
  
  @override
  Future<Uint8List> generateThumbnail(String id) async {
    // 실제 구현은 프로젝트 요구사항에 따라 달라질 수 있습니다.
    throw UnimplementedError('아직 구현되지 않은 기능입니다.');
  }
  
  @override
  Future<String> extractText(String id, int pageNumber) async {
    try {
      final document = _getDocumentById(id);
      if (document == null) {
        throw Exception('문서를 찾을 수 없습니다: $id');
      }
      
      final pdfDoc = await _loadPdfDocument(document.filePath);
      if (pageNumber < 0 || pageNumber >= pdfDoc.pages.count) {
        throw Exception('유효하지 않은 페이지 번호: $pageNumber');
      }
      
      final textExtractor = PdfTextExtractor(pdfDoc);
      final text = textExtractor.extractText(startPageIndex: pageNumber);
      return text;
    } catch (e) {
      debugPrint('텍스트 추출 오류: $e');
      return '';
    }
  }
  
  @override
  Future<Map<String, dynamic>> extractMetadata(String id) async {
    try {
      final document = _getDocumentById(id);
      if (document == null) {
        throw Exception('문서를 찾을 수 없습니다: $id');
      }
      
      final pdfDoc = await _loadPdfDocument(document.filePath);
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
      debugPrint('메타데이터 추출 오류: $e');
      return {};
    }
  }
  
  @override
  Future<int> getPageCount(String id) async {
    try {
      // id가 파일 경로인 경우 (직접 호출)
      if (id.endsWith('.pdf') || id.startsWith('http')) {
        final file = File(id);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final pdfDoc = PdfDocument(inputBytes: bytes);
          return pdfDoc.pages.count;
        } else if (id.startsWith('http')) {
          final result = await downloadPdf(id);
          if (result.isSuccess) {
            final filePath = result.getOrNull();
            if (filePath != null) {
              final file = File(filePath);
              final bytes = await file.readAsBytes();
              final pdfDoc = PdfDocument(inputBytes: bytes);
              return pdfDoc.pages.count;
            }
          }
        }
      }
      
      // 캐시에서 문서 찾기
      final document = _getDocumentById(id);
      if (document == null) {
        throw Exception('문서를 찾을 수 없습니다: $id');
      }
      
      final pdfDoc = await _loadPdfDocument(document.filePath);
      return pdfDoc.pages.count;
    } catch (e) {
      debugPrint('페이지 수 확인 오류: $e');
      return 0;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchText(String id, String query) async {
    try {
      final document = _getDocumentById(id);
      if (document == null) {
        throw Exception('문서를 찾을 수 없습니다: $id');
      }
      
      final pdfDoc = await _loadPdfDocument(document.filePath);
      final pageCount = pdfDoc.pages.count;
      final results = <Map<String, dynamic>>[];
      
      for (var i = 0; i < pageCount; i++) {
        final textExtractor = PdfTextExtractor(pdfDoc);
        final text = textExtractor.extractText(startPageIndex: i);
        
        if (text.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'page': i,
            'text': text,
          });
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('텍스트 검색 오류: $e');
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
  
  @override
  Future<Result<String>> downloadPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      
      if (response.statusCode != 200) {
        return Result.failure(Exception('PDF 다운로드 실패: ${response.statusCode}'));
      }
      
      final bytes = response.bodyBytes;
      
      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final fileName = '${_uuid.v4()}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return Result.success(filePath);
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      return Result.failure(e);
    }
  }
  
  // 헬퍼 메서드
  
  /// ID로 문서 찾기
  PDFDocument? _getDocumentById(String id) {
    for (final document in _documentCache.values) {
      if (document.id == id) {
        return document;
      }
    }
    return null;
  }
  
  /// PDF 문서 로드
  Future<PdfDocument> _loadPdfDocument(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('파일을 찾을 수 없습니다: $filePath');
    }
    
    final bytes = await file.readAsBytes();
    return PdfDocument(inputBytes: bytes);
  }
} 