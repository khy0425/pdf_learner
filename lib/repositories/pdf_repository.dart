import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../models/pdf_document.dart';

// 플랫폼에 따라 다른 임포트
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
// 웹이 아닌 경우에만 path_provider 임포트
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';

/// PDF 문서 관련 데이터를 관리하는 Repository
class PdfRepository {
  /// 문서 로컬 저장소 경로
  late final Future<String> _documentsPath;
  
  /// UUID 생성기
  final _uuid = const Uuid();
  
  /// 생성자
  PdfRepository() {
    _initStorage();
  }
  
  /// 저장소 초기화
  Future<void> _initStorage() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 임시 경로 사용
        _documentsPath = Future.value('/web/pdf_documents');
        debugPrint('웹 환경: 가상 문서 경로 사용');
      } else {
        // 네이티브 플랫폼에서는 실제 파일 시스템 사용
        final directory = await getApplicationDocumentsDirectory();
        final documentsDir = Directory('${directory.path}/pdf_documents');
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        _documentsPath = Future.value(documentsDir.path);
        debugPrint('네이티브 환경: 문서 경로 ${await _documentsPath}');
      }
    } catch (e) {
      debugPrint('저장소 초기화 중 오류: $e');
      // 오류 발생 시 기본 경로 사용
      _documentsPath = Future.value('/pdf_documents');
    }
  }
  
  /// 모든 PDF 문서 목록 조회
  Future<List<PDFDocument>> getDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getStringList('pdf_documents') ?? [];
      
      final documents = documentsJson
          .map((json) => PDFDocument.fromJson(jsonDecode(json)))
          .toList();
      
      debugPrint('문서 ${documents.length}개 로드됨');
      return documents;
    } catch (e) {
      debugPrint('PDF 문서 목록 로드 실패: $e');
      return [];
    }
  }
  
  /// 문서 ID로 PDF 문서 조회
  Future<PDFDocument> loadDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getStringList('pdf_documents') ?? [];
      
      final documentJson = documentsJson
          .map((json) => jsonDecode(json))
          .firstWhere((json) => json['id'] == documentId, 
              orElse: () => throw Exception('문서를 찾을 수 없습니다: $documentId'));
      
      return PDFDocument.fromJson(documentJson);
    } catch (e) {
      throw Exception('문서 로드 실패: $e');
    }
  }
  
  /// URL에서 PDF 문서 로드
  Future<PDFDocument> loadDocumentFromUrl(String url) async {
    try {
      // URL에서 파일 이름 추출
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last.isNotEmpty 
          ? uri.pathSegments.last 
          : 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // 파일 다운로드
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('파일 다운로드 실패: ${response.statusCode}');
      }
      
      final fileSize = response.bodyBytes.length;
      
      // 로컬 파일로 저장
      final documentsDir = await _documentsPath;
      final filePath = '$documentsDir/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // 문서 메타데이터 생성
      final documentId = _uuid.v4();
      final document = PDFDocument(
        id: documentId,
        title: fileName.replaceAll('.pdf', ''),
        fileName: fileName,
        fileSize: fileSize,
        pageCount: 1, // TODO: PDF 페이지 수 분석 필요
        url: url,
        filePath: filePath,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );
      
      // 문서 저장
      await saveDocument(document);
      
      return document;
    } catch (e) {
      throw Exception('URL에서 문서 로드 실패: $e');
    }
  }
  
  /// 로컬 파일에서 PDF 문서 로드
  Future<PDFDocument> loadDocumentFromFile(File file) async {
    try {
      // 파일 복사
      final fileName = file.path.split('/').last;
      final documentsDir = await _documentsPath;
      final filePath = '$documentsDir/$fileName';
      
      if (file.path != filePath) {
        await file.copy(filePath);
      }
      
      final fileSize = await file.length();
      
      // 문서 메타데이터 생성
      final documentId = _uuid.v4();
      final document = PDFDocument(
        id: documentId,
        title: fileName.replaceAll('.pdf', ''),
        fileName: fileName,
        fileSize: fileSize,
        pageCount: 1, // TODO: PDF 페이지 수 분석 필요
        filePath: filePath,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );
      
      // 문서 저장
      await saveDocument(document);
      
      return document;
    } catch (e) {
      throw Exception('파일에서 문서 로드 실패: $e');
    }
  }
  
  /// PDF 문서 저장
  Future<void> saveDocument(PDFDocument document) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> documentsJson = prefs.getStringList('pdf_documents') ?? [];
      
      // 기존 문서가 있는지 확인
      final index = documentsJson
          .map((json) => jsonDecode(json))
          .toList()
          .indexWhere((json) => json['id'] == document.id);
      
      final encodedDocument = jsonEncode(document.toJson());
      
      if (index >= 0) {
        // 기존 문서 업데이트
        documentsJson[index] = encodedDocument;
      } else {
        // 새 문서 추가
        documentsJson.add(encodedDocument);
      }
      
      await prefs.setStringList('pdf_documents', documentsJson);
    } catch (e) {
      throw Exception('문서 저장 실패: $e');
    }
  }
  
  /// PDF 문서 삭제
  Future<void> deleteDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> documentsJson = prefs.getStringList('pdf_documents') ?? [];
      
      documentsJson = documentsJson
          .where((json) => jsonDecode(json)['id'] != documentId)
          .toList();
      
      await prefs.setStringList('pdf_documents', documentsJson);
    } catch (e) {
      throw Exception('문서 삭제 실패: $e');
    }
  }
  
  /// 최근 조회 문서 업데이트
  Future<void> updateRecentDocument(String documentId) async {
    try {
      final document = await loadDocument(documentId);
      
      // 조회 횟수 증가 및 최근 조회 일시 업데이트
      final updatedDocument = document.copyWith(
        accessCount: document.accessCount + 1,
        lastAccessedAt: DateTime.now(),
      );
      
      await saveDocument(updatedDocument);
    } catch (e) {
      debugPrint('최근 조회 문서 업데이트 실패: $e');
    }
  }
  
  /// 문서 검색
  Future<List<PDFDocument>> searchDocuments(String query) async {
    try {
      final documents = await getDocuments();
      
      // 제목과 파일명 기준 검색
      return documents.where((document) {
        final title = document.title.toLowerCase();
        final fileName = document.fileName.toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return title.contains(searchQuery) || fileName.contains(searchQuery);
      }).toList();
    } catch (e) {
      debugPrint('문서 검색 실패: $e');
      return [];
    }
  }
  
  /// PDF 페이지 수 가져오기
  Future<int> _getPageCount(String filePath) async {
    try {
      // 웹 환경에서는 기본값 반환
      if (kIsWeb) {
        debugPrint('웹 환경: 기본 페이지 수 1 반환');
        return 1;
      }
      
      // 실제 구현에서는 PDF 라이브러리를 사용하여 페이지 수를 계산
      // 예제 코드이므로 임의의 값을 반환
      debugPrint('네이티브 환경: 페이지 수 계산 (임시 값 10)');
      return 10;
    } catch (e) {
      debugPrint('PDF 페이지 수 계산 중 오류: $e');
      return 1;
    }
  }
  
  /// 북마크 추가
  Future<bool> addBookmark(String documentId, String title, int page) async {
    try {
      final document = await loadDocument(documentId);
      if (document == null) {
        return false;
      }
      
      // 중복 확인
      final existingBookmarkIndex = document.bookmarks
          .indexWhere((bookmark) => bookmark.pageNumber == page);
      
      if (existingBookmarkIndex >= 0) {
        // 기존 북마크가 있으면 업데이트
        final updatedBookmarks = List<PDFBookmark>.from(document.bookmarks);
        updatedBookmarks[existingBookmarkIndex] = PDFBookmark(
          id: document.bookmarks[existingBookmarkIndex].id,
          pageNumber: page,
          title: title,
          createdAt: DateTime.now(),
        );
        
        // 문서 업데이트
        final updatedDocument = document.copyWith(
          bookmarks: updatedBookmarks,
        );
        
        await saveDocument(updatedDocument);
        return true;
      } else {
        // 신규 북마크 생성
        final bookmark = PDFBookmark(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          pageNumber: page,
          title: title,
          createdAt: DateTime.now(),
        );
        
        // 문서 업데이트
        final updatedBookmarks = List<PDFBookmark>.from(document.bookmarks)
          ..add(bookmark);
        
        final updatedDocument = document.copyWith(
          bookmarks: updatedBookmarks,
        );
        
        await saveDocument(updatedDocument);
        return true;
      }
    } catch (e) {
      debugPrint('북마크 추가 중 오류: $e');
      return false;
    }
  }
  
  /// 북마크 제거
  Future<bool> removeBookmark(String documentId, String bookmarkId) async {
    try {
      final document = await loadDocument(documentId);
      if (document == null) {
        return false;
      }
      
      // 북마크 찾기
      final bookmarkIndex = document.bookmarks
          .indexWhere((bookmark) => bookmark.id == bookmarkId);
      
      if (bookmarkIndex < 0) {
        return false;
      }
      
      // 북마크 제거
      final updatedBookmarks = List<PDFBookmark>.from(document.bookmarks);
      updatedBookmarks.removeAt(bookmarkIndex);
      
      // 문서 업데이트
      final updatedDocument = document.copyWith(
        bookmarks: updatedBookmarks,
      );
      
      await saveDocument(updatedDocument);
      return true;
    } catch (e) {
      debugPrint('북마크 제거 중 오류: $e');
      return false;
    }
  }
  
  /// 주석 추가
  Future<bool> addAnnotation(String documentId, String content, AnnotationType type, int page, Rect rect) async {
    try {
      final document = await loadDocument(documentId);
      if (document == null) {
        return false;
      }
      
      // 주석 생성
      final annotation = PDFAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pageNumber: page,
        content: content,
        type: type,
        rect: rect,
        createdAt: DateTime.now(),
      );
      
      // 문서 업데이트
      final updatedAnnotations = List<PDFAnnotation>.from(document.annotations)
        ..add(annotation);
      
      final updatedDocument = document.copyWith(
        annotations: updatedAnnotations,
      );
      
      await saveDocument(updatedDocument);
      return true;
    } catch (e) {
      debugPrint('주석 추가 중 오류: $e');
      return false;
    }
  }
  
  /// 주석 제거
  Future<bool> removeAnnotation(String documentId, String annotationId) async {
    try {
      final document = await loadDocument(documentId);
      if (document == null) {
        return false;
      }
      
      // 주석 찾기
      final annotationIndex = document.annotations
          .indexWhere((annotation) => annotation.id == annotationId);
      
      if (annotationIndex < 0) {
        return false;
      }
      
      // 주석 제거
      final updatedAnnotations = List<PDFAnnotation>.from(document.annotations);
      updatedAnnotations.removeAt(annotationIndex);
      
      // 문서 업데이트
      final updatedDocument = document.copyWith(
        annotations: updatedAnnotations,
      );
      
      await saveDocument(updatedDocument);
      return true;
    } catch (e) {
      debugPrint('주석 제거 중 오류: $e');
      return false;
    }
  }
  
  /// PDF 파일 복사 (네이티브 환경 전용)
  Future<String?> copyPdfFile(String srcPath, {String? customFileName}) async {
    debugPrint('PDF 파일 복사 시도: $srcPath');
    
    if (kIsWeb) {
      // 웹 환경에서는 파일 경로를 그대로 반환
      debugPrint('웹 환경: 원본 경로 반환 - $srcPath');
      return srcPath;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      await Directory('${directory.path}/pdf_documents').create(recursive: true);
      
      final fileName = customFileName ?? path.basename(srcPath);
      final destPath = '${directory.path}/pdf_documents/$fileName';
      
      // 파일 복사
      final file = File(srcPath);
      if (await file.exists()) {
        final copiedFile = await file.copy(destPath);
        debugPrint('파일 복사 완료: ${copiedFile.path}');
        return copiedFile.path;
      } else {
        debugPrint('원본 파일이 존재하지 않음: $srcPath');
      }
      
      return null;
    } catch (e) {
      debugPrint('PDF 파일 복사 중 오류: $e');
      return null;
    }
  }
  
  /// 원격 또는 로컬 경로에서 PDF 파일 가져오기
  Future<PDFDocument?> importPdfFile({required String filePath, String? title}) async {
    try {
      debugPrint('PDF 파일 가져오기 시도: $filePath');
      
      if (kIsWeb) {
        // 웹 환경에서는 URL로 처리
        final fileName = filePath.split('/').last;
        final fileTitle = title ?? fileName.replaceAll('.pdf', '');
        
        // 문서 생성
        final document = PDFDocument(
          id: _uuid.v4(),
          title: fileTitle,
          filePath: filePath,
          fileName: fileName,
          fileSize: 0, // 웹에서는 크기를 알 수 없음
          pageCount: 1, // 기본값
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          url: filePath,
        );
        
        // 저장
        await saveDocument(document);
        debugPrint('웹에서 PDF 가져오기 완료: ${document.title}');
        return document;
      } else {
        // 네이티브 환경에서 파일 시스템 접근
        final file = File(filePath);
        
        if (!await file.exists()) {
          debugPrint('파일이 존재하지 않음: $filePath');
          return null;
        }
        
        // 파일 복사
        final copiedPath = await copyPdfFile(filePath);
        if (copiedPath == null) {
          debugPrint('파일 복사 실패: $filePath');
          return null;
        }
        
        // 파일 정보 가져오기
        final fileStats = await file.stat();
        final fileName = path.basename(filePath);
        final fileTitle = title ?? fileName.replaceAll('.pdf', '');
        
        // 문서 생성
        final document = PDFDocument(
          id: _uuid.v4(),
          title: fileTitle,
          filePath: copiedPath,
          fileName: fileName,
          fileSize: fileStats.size,
          pageCount: await _getPageCount(copiedPath),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );
        
        // 저장
        await saveDocument(document);
        debugPrint('네이티브 환경에서 PDF 가져오기 완료: ${document.title}');
        return document;
      }
    } catch (e) {
      debugPrint('PDF 파일 가져오기 중 오류: $e');
      return null;
    }
  }
  
  /// 새 PDF 파일 생성 (웹 URL에서)
  Future<PDFDocument?> createPdfFromUrl(String url) async {
    try {
      // 테스트용 URL (PDF 샘플)
      if (kIsWeb) {
        // 테스트를 위해 공개 PDF URL 사용
        url = 'https://www.africau.edu/images/default/sample.pdf';
        debugPrint('웹 환경 테스트를 위해 샘플 PDF URL로 변경: $url');
      }
      
      // URL 형식 검증
      if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('blob:')) {
        debugPrint('경고: 올바른 URL 형식이 아닙니다: $url');
        // 애셋 경로나 상대 경로인 경우 절대 URL로 변환 시도
        if (url.startsWith('assets/')) {
          // 웹에서 애셋에 접근할 수 있도록 경로 조정
          url = '$url';
          debugPrint('애셋 경로를 상대 URL로 변환: $url');
        }
      }
      
      // URL에서 파일 이름 추출 (기본값 제공)
      final fileName = url.split('/').last.contains('.')
          ? url.split('/').last
          : 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      debugPrint('URL에서 PDF 생성 시도: $url -> $fileName');
      
      if (kIsWeb) {
        // 웹 환경에서는 URL을 직접 사용
        final document = PDFDocument(
          id: _uuid.v4(),
          title: fileName.replaceAll('.pdf', ''),
          fileName: fileName,
          filePath: url, // 웹에서는 URL을 파일 경로로 사용
          fileSize: 0, // 웹에서는 크기를 알 수 없음
          pageCount: 1, // 기본값
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          url: url, // URL 필드에도 저장
        );
        
        await saveDocument(document);
        debugPrint('웹에서 PDF 생성 완료: ${document.title}, URL: ${document.url}');
        return document;
      } else {
        // 네이티브 플랫폼에서 URL에서 파일 다운로드
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('파일 다운로드 실패: ${response.statusCode}');
        }
        
        final fileSize = response.bodyBytes.length;
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$fileName';
        
        // 파일 저장
        await File(tempFilePath).writeAsBytes(response.bodyBytes);
        
        // 영구 저장소로 복사
        final documentsDir = await _documentsPath;
        final destPath = '$documentsDir/$fileName';
        await File(tempFilePath).copy(destPath);
        
        // 문서 객체 생성
        final document = PDFDocument(
          id: _uuid.v4(),
          title: fileName.replaceAll('.pdf', ''),
          fileName: fileName,
          filePath: destPath,
          fileSize: fileSize,
          pageCount: await _getPageCount(destPath),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          url: url,
        );
        
        await saveDocument(document);
        debugPrint('네이티브 환경에서 PDF 생성 완료: ${document.title}');
        return document;
      }
    } catch (e) {
      debugPrint('URL에서 PDF 생성 중 오류: $e');
      return null;
    }
  }

  /// 새 문서 생성 함수
  Future<PDFDocument> createNewDocument({
    required String filePath,
    String? title,
    String? description,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('파일이 존재하지 않습니다: $filePath');
      }
      
      final fileName = filePath.split('/').last;
      final fileSize = await file.length();
      final pageCount = await _getPageCount(filePath);
      
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title ?? fileName,
        description: description,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        pageCount: pageCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookmarks: [],
        annotations: [],
      );
      
      await saveDocument(document);
      return document;
    } catch (e) {
      debugPrint('새 문서 생성 중 오류: $e');
      rethrow;
    }
  }
} 