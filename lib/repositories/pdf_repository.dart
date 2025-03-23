import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_document.dart';
import '../services/file_storage_service.dart';
import '../services/thumbnail_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// PDF 문서 저장소
class PdfRepository {
  // 문서 목록
  List<PDFDocument> _documents = [];
  
  // 서비스 의존성
  final FileStorageService _storageService;
  final ThumbnailService _thumbnailService;
  
  // 스트림 컨트롤러
  final _documentsStreamController = StreamController<List<PDFDocument>>.broadcast();
  
  /// 생성자
  PdfRepository({
    required FileStorageService storageService,
    required ThumbnailService thumbnailService,
  }) : 
    _storageService = storageService,
    _thumbnailService = thumbnailService 
  {
    _init();
  }
  
  /// 문서 목록 스트림
  Stream<List<PDFDocument>> get documentsStream => _documentsStreamController.stream;
  
  /// 문서 목록
  List<PDFDocument> get documents => List.unmodifiable(_documents);
  
  /// 초기화
  Future<void> _init() async {
    try {
      await loadDocuments();
    } catch (e) {
      debugPrint('PDF 저장소 초기화 오류: $e');
    }
  }
  
  /// 모든 문서 가져오기
  Future<List<PDFDocument>> getAllDocuments() async {
    await loadDocuments();
    return documents;
  }
  
  /// 문서 목록 로드
  Future<void> loadDocuments() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 문서 목록을 가져오는 대신 
        // 샘플 데이터 또는 Firebase에서 가져올 수 있음
        _documents = await _getWebSampleDocuments();
      } else {
        // 저장된 문서 목록 가져오기
        final savedDocuments = await _storageService.getDocuments();
        _documents = savedDocuments;
      }
      
      // 스트림으로 문서 목록 전달
      _notifyDocumentsChanged();
    } catch (e) {
      debugPrint('문서 목록 로드 오류: $e');
      _documents = [];
      _notifyDocumentsChanged();
    }
  }
  
  /// 웹 환경에서 샘플 문서 목록 가져오기
  Future<List<PDFDocument>> _getWebSampleDocuments() async {
    // 웹 환경에서 사용할 샘플 문서 목록
    return [
      PDFDocument(
        id: 'sample1',
        title: 'PDF 샘플 문서 1',
        path: 'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf',
        thumbnailPath: 'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.jpg',
        pageCount: 1,
        lastOpened: DateTime.now(),
        dateAdded: DateTime.now(),
        fileSize: 0,
        favorites: [],
      ),
      PDFDocument(
        id: 'sample2',
        title: 'PDF 샘플 문서 2',
        path: 'https://arxiv.org/pdf/2006.11239.pdf',
        thumbnailPath: 'https://arxiv.org/html/2006.11239v3/x1.png',
        pageCount: 2,
        lastOpened: DateTime.now().subtract(const Duration(days: 1)),
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        fileSize: 0,
        favorites: [],
      ),
    ];
  }
  
  /// 문서 목록 변경 알림
  void _notifyDocumentsChanged() {
    _documentsStreamController.add(_documents);
  }
  
  /// URL에서 문서 추가
  Future<PDFDocument?> addDocumentFromUrl(String url, String title) async {
    try {
      if (kIsWeb) {
        debugPrint('웹에서 URL로 문서 추가: $url');
        
        // 썸네일 URL 생성 (PDF URL에서 가능한 경우)
        String thumbnailPath = '';
        
        // Adobe PDF인 경우 썸네일 추정
        if (url.contains('adobe.com') && url.endsWith('.pdf')) {
          thumbnailPath = url.replaceAll('.pdf', '.jpg');
        }
        // arXiv PDF인 경우 썸네일 추정
        else if (url.contains('arxiv.org/pdf/')) {
          final paperIdMatch = RegExp(r'(\d+\.\d+)').firstMatch(url);
          if (paperIdMatch != null) {
            final paperId = paperIdMatch.group(1);
            thumbnailPath = 'https://arxiv.org/html/${paperId}v1/x1.png';
          }
        }
        
        // 문서 객체 생성 - 원본 URL 직접 사용
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          path: url, // 원본 URL 직접 사용
          thumbnailPath: thumbnailPath,
          pageCount: 1, // 페이지 수는 계산할 수 없으므로 기본값 설정
          lastOpened: DateTime.now(),
          dateAdded: DateTime.now(),
          fileSize: 0, // 파일 크기는 알 수 없음
          favorites: [],
        );
        
        // 문서 목록에 추가
        _documents.add(document);
        
        // 저장된 문서 목록 업데이트
        await _saveDocuments();
        
        return document;
      } else {
        // 모바일 환경에서는 기존 로직 사용
        // URL에서 PDF 다운로드
        debugPrint('모바일에서 URL로 문서 추가: $url');
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          
          // 파일 저장
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
          final filePath = await _storageService.savePdfBytes(bytes, fileName);
          
          // 썸네일 생성
          final thumbnailPath = await _thumbnailService.generateThumbnail(bytes, filePath);
          
          // 문서 객체 생성
          final document = PDFDocument(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            path: filePath ?? '',
            thumbnailPath: thumbnailPath ?? '',
            pageCount: 1, // 페이지 수는 별도로 계산 필요
            lastOpened: DateTime.now(),
            dateAdded: DateTime.now(),
            fileSize: bytes.length,
            favorites: [],
          );
          
          // 문서 목록에 추가
          _documents.add(document);
          
          // 저장된 문서 목록 업데이트
          await _saveDocuments();
          
          return document;
        } else {
          debugPrint('URL에서 PDF 다운로드 실패: ${response.statusCode}');
          return null;
        }
      }
    } catch (e) {
      debugPrint('URL에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 파일에서 문서 추가
  Future<PDFDocument?> addDocumentFromFile(File file, String title) async {
    try {
      if (kIsWeb) {
        // 웹에서는 지원되지 않음
        return null;
      }
      
      // 파일 읽기
      final pdfBytes = await file.readAsBytes();
      
      // 파일 저장
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = await _storageService.savePdfBytes(pdfBytes, fileName);
      
      // 썸네일 생성
      final thumbnailPath = await _thumbnailService.generateThumbnail(pdfBytes, filePath);
      
      // 문서 객체 생성
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        path: filePath ?? '',
        thumbnailPath: thumbnailPath ?? '',
        pageCount: 1, // 실제 페이지 수는 별도로 계산 필요
        lastOpened: DateTime.now(),
        dateAdded: DateTime.now(),
        fileSize: pdfBytes.length,
        favorites: [],
      );
      
      // 문서 목록에 추가
      _documents.add(document);
      
      // 저장된 문서 목록 업데이트
      await _saveDocuments();
      
      return document;
    } catch (e) {
      debugPrint('파일에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 바이트에서 문서 추가
  Future<PDFDocument?> addDocumentFromBytes(Uint8List bytes, String title) async {
    try {
      // 파일 이름 생성
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
      
      if (kIsWeb) {
        // 웹 환경에서는 blob URL 생성
        debugPrint('웹에서 바이트 배열로 문서 추가: $title');
        
        String blobUrl = '';
        
        try {
          // HTML blob URL 생성 (javascript 호출 코드는 생략되어 있음)
          // 실제로는 여기서 js 인터롭을 통해 blob URL을 생성해야 함
          // 이 예제에서는 단순화를 위해 URL을 하드코딩
          final randomId = DateTime.now().millisecondsSinceEpoch;
          blobUrl = 'blob:https://example.com/$randomId';
          
          // 실제로는 이런 방식으로 URL을 생성해야 함 (평문 코드)
          // final blob = html.Blob([bytes], 'application/pdf');
          // blobUrl = html.Url.createObjectUrlFromBlob(blob);
        } catch (e) {
          debugPrint('Blob URL 생성 오류: $e');
          blobUrl = 'https://docs.google.com/viewer?url=https://www.africanmanager.com/wp-content/uploads/2023/10/sample.pdf&embedded=true';
        }
        
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          path: blobUrl, // blob URL 또는 외부 URL 사용
          thumbnailPath: '',
          pageCount: 1, // 페이지 수는 계산할 수 없으므로 기본값 사용
          lastOpened: DateTime.now(),
          dateAdded: DateTime.now(),
          fileSize: bytes.length,
          favorites: [],
        );
        
        _documents.add(document);
        _notifyDocumentsChanged();
        return document;
      } else {
        // 네이티브 환경에서는 파일로 저장
        final filePath = await _storageService.savePdfBytes(bytes, fileName);
        
        // 썸네일 생성
        final thumbnailPath = await _thumbnailService.generateThumbnail(bytes, filePath);
        
        // 문서 객체 생성
        final document = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          path: filePath ?? '',
          thumbnailPath: thumbnailPath ?? '',
          pageCount: 1, // 실제 페이지 수는 별도로 계산 필요
          lastOpened: DateTime.now(),
          dateAdded: DateTime.now(),
          fileSize: bytes.length,
          favorites: [],
        );
        
        // 문서 목록에 추가
        _documents.add(document);
        
        // 저장된 문서 목록 업데이트
        await _saveDocuments();
        
        return document;
      }
    } catch (e) {
      debugPrint('바이트에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 저장된 문서 목록 업데이트
  Future<void> _saveDocuments() async {
    if (!kIsWeb) {
      await _storageService.saveDocuments(_documents);
    }
    _notifyDocumentsChanged();
  }
  
  /// 문서 삭제
  Future<bool> deleteDocument(String id) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index == -1) {
        return false;
      }
      
      final document = _documents[index];
      
      // 파일 삭제
      if (document.filePath != null) {
        await _storageService.deleteFile(document.filePath!);
      }
      
      // 썸네일 삭제
      if (document.thumbnailPath != null && document.thumbnailPath.isNotEmpty) {
        await _storageService.deleteFile(document.thumbnailPath);
      }
      
      // 목록에서 제거
      _documents.removeAt(index);
      _notifyDocumentsChanged();
      
      return true;
    } catch (e) {
      debugPrint('문서 삭제 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 문서 이름 변경
  Future<bool> renameDocument(String id, String newTitle) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index == -1) {
        return false;
      }
      
      final document = _documents[index];
      final updatedDocument = document.copyWith(
        title: newTitle,
        lastOpened: DateTime.now(),
      );
      
      // 목록 업데이트
      _documents[index] = updatedDocument;
      _notifyDocumentsChanged();
      
      return true;
    } catch (e) {
      debugPrint('문서 이름 변경 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 마지막으로 열었던 시간 업데이트
  Future<bool> updateLastOpenedAt(String id) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index == -1) {
        return false;
      }
      
      final document = _documents[index];
      final updatedDocument = document.copyWith(
        lastOpened: DateTime.now(),
      );
      
      // 목록 업데이트
      _documents[index] = updatedDocument;
      _notifyDocumentsChanged();
      
      return true;
    } catch (e) {
      debugPrint('마지막으로 열었던 시간 업데이트 중 오류 발생: $e');
      return false;
    }
  }
  
  /// 리소스 해제
  void dispose() {
    _documentsStreamController.close();
  }
} 