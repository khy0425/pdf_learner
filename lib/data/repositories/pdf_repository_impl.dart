import 'dart:io' if (dart.library.html) 'package:pdf_learner_v2/core/utils/web_stub.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/base/result.dart';
import '../../core/utils/web_storage_utils.dart';
import '../../core/utils/conditional_file_picker.dart';
import '../../data/datasources/pdf_local_data_source.dart';
import '../../data/datasources/pdf_remote_data_source.dart';
import '../../services/storage/storage_service.dart';
import '../../data/models/pdf_document_model.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/firebase_service.dart';
import '../../data/models/pdf_bookmark_model.dart';

@Injectable(as: PDFRepository)
class PDFRepositoryImpl implements PDFRepository {
  final FirebaseService _firebaseService;
  final SharedPreferences _sharedPreferences;
  final PDFLocalDataSource _localDataSource;
  final PDFRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  PDFRepositoryImpl(
    this._firebaseService,
    this._sharedPreferences,
    this._localDataSource,
    this._remoteDataSource,
    this._storageService,
  );

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final documents = await _localDataSource.getDocuments();
      
      if (documents.isEmpty) {
        try {
          final remoteDocuments = await _remoteDataSource.getDocuments();
          if (remoteDocuments.isNotEmpty) {
            // 원격에서 가져온 문서 로컬에 저장
            for (final document in remoteDocuments) {
              await _localDataSource.saveDocument(document);
            }
            return Result.success(remoteDocuments);
          }
        } catch (e) {
          debugPrint('원격 문서 가져오기 오류: $e');
          // 원격 가져오기 실패 시 로컬 데이터 사용
        }
      }
      
      return Result.success(documents);
    } catch (e) {
      debugPrint('문서 목록 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<PDFDocument>> getDocument(String id) async {
    try {
      // 로컬에서 먼저 조회
      final localDocument = await _localDataSource.getDocument(id);
      
      if (localDocument != null) {
        return Result.success(localDocument);
      }
      
      // 로컬에 없으면, 원격에서 조회
      try {
        final remoteDocument = await _remoteDataSource.getDocument(id);
        
        if (remoteDocument != null) {
          // 로컬에 저장
          await _localDataSource.saveDocument(remoteDocument);
          return Result.success(remoteDocument);
        } else {
          return Result.failure(Exception('문서를 찾을 수 없습니다.'));
        }
      } catch (e) {
        return Result.failure(Exception(e.toString()));
      }
    } catch (e) {
      debugPrint('문서 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<PDFDocument>> saveDocument(PDFDocument document) async {
    try {
      // 로컬 저장
      await _localDataSource.saveDocument(document);
      
      // 원격 저장 시도
      try {
        await _remoteDataSource.saveDocument(document);
      } catch (e) {
        debugPrint('원격 저장 실패: $e');
        // 원격 저장 실패해도 로컬 저장은 성공으로 처리
      }
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    try {
      // 로컬에 저장
      await _localDataSource.saveDocument(document);

      // 원격에 저장
      try {
        await _remoteDataSource.updateDocument(document);
      } catch (e) {
        debugPrint('원격 문서 업데이트 오류: $e');
        // 원격 저장 실패해도 로컬 저장은 성공으로 처리
      }
      
      return Result.success(document);
    } catch (e) {
      debugPrint('문서 업데이트 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<bool>> deleteDocument(String documentId) async {
    try {
      // 로컬에서 먼저 삭제
      await _localDataSource.deleteDocument(documentId);
      
      // 원격에서 삭제 시도
      try {
        await _remoteDataSource.deleteDocument(documentId);
      } catch (e) {
        debugPrint('원격 문서 삭제 오류: $e');
        // 원격 삭제 실패해도 로컬 삭제는 성공으로 처리
      }
      
      return Result.success(true);
    } catch (e) {
      debugPrint('문서 삭제 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      // 로컬에서 북마크 목록 조회
      final bookmarks = await _localDataSource.getBookmarks(documentId);
      
      // 로컬에 북마크가 없으면 원격에서 조회 시도
      if (bookmarks.isEmpty) {
        try {
          final remoteBookmarks = await _remoteDataSource.getBookmarks(documentId);
          
          if (remoteBookmarks.isNotEmpty) {
            // 원격에서 가져온 북마크 로컬에 저장
            for (final bookmark in remoteBookmarks) {
              await _localDataSource.saveBookmark(bookmark);
            }
            
            return Result.success(remoteBookmarks);
          }
        } catch (e) {
          debugPrint('원격 북마크 가져오기 오류: $e');
          // 원격 가져오기 실패 시 로컬 데이터 사용
        }
      }
      
      return Result.success(bookmarks);
    } catch (e) {
      debugPrint('북마크 목록 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<Uint8List>> downloadPdf(String url) async {
    try {
      // 웹 환경에서는 WebStorageUtils 사용
      if (kIsWeb) {
        // 로컬 스토리지에 저장된 PDF인지 확인
        if (url.startsWith('web_')) {
          final pdfBytes = await WebStorageUtils.instance.getBytesFromIndexedDB(url);
          if (pdfBytes != null) {
            return Result.success(pdfBytes);
          }
        }
        
        // URL이 실제 웹 주소인 경우 HTTP 요청
        if (url.startsWith('http')) {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            // 웹 환경에서는 다운로드한 PDF를 WebStorage에 저장
            final bytes = response.bodyBytes;
            final fileId = 'web_${DateTime.now().millisecondsSinceEpoch}';
            await WebStorageUtils.instance.saveBytesToIndexedDB(fileId, bytes);
            return Result.success(bytes);
          } else {
            return Result.failure(Exception('PDF 다운로드 실패: HTTP ${response.statusCode}'));
          }
        }
      } else {
        // 네이티브 환경에서는 파일 시스템 사용
        if (url.startsWith('http')) {
          // URL에서 다운로드
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            return Result.success(response.bodyBytes);
          } else {
            return Result.failure(Exception('PDF 다운로드 실패: HTTP ${response.statusCode}'));
          }
        } else if (await File(url).exists()) {
          // 로컬 파일 경로인 경우
          return Result.success(await File(url).readAsBytes());
        }
      }
      
      return Result.failure(Exception('PDF를 다운로드할 수 없는 형식: $url'));
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<String>> savePdfFile(Uint8List bytes, String fileName) async {
    try {
      // 웹 환경에서는 다른 로직을 사용
      if (kIsWeb) {
        // 웹에서는 메모리에 저장
        // 웹 환경에서는 임시 URL을 생성하여 반환할 수 있음
        return Result.success('memory://temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      
      final tempPath = await _storageService.getTempFilePath(fileName);
      
      // 파일 저장
      final savedPath = await _storageService.saveFile(bytes, tempPath);
      
      if (savedPath.isNotEmpty) {
        return Result.success(tempPath);
      } else {
        return Result.failure(Exception('PDF 파일 저장 실패'));
      }
    } catch (e) {
      debugPrint('PDF 파일 저장 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PDFDocument>>> searchDocuments(String query) async {
    try {
      final allDocuments = await _localDataSource.getDocuments();
      
      // 검색어가 비어있으면 모든 문서 반환
      if (query.trim().isEmpty) {
        final documents = allDocuments.map((model) => model.toDomain()).toList();
        return Result.success(documents);
      }
      
      // 제목, 설명, 태그 등을 기준으로 검색
      final filteredDocuments = allDocuments.where((doc) {
        final title = doc.title.toLowerCase();
        final description = doc.description.toLowerCase();
        final queryLower = query.toLowerCase();
        
        // 제목 또는 설명에 검색어 포함
        if (title.contains(queryLower) || description.contains(queryLower)) {
          return true;
        }
        
        // 태그에 검색어 포함
        for (final tag in doc.tags) {
          if (tag.toLowerCase().contains(queryLower)) {
            return true;
          }
        }
        
        return false;
      }).toList();
      
      // 변환 후 반환
      final documents = filteredDocuments.map((model) => model.toDomain()).toList();
      return Result.success(documents);
    } catch (e) {
      debugPrint('문서 검색 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments(int limit) async {
    try {
      final allDocuments = await _localDataSource.getDocuments();
      
      // 최근 문서 정렬 (updatedAt 기준 내림차순)
      final sortedDocuments = List<PDFDocumentModel>.from(allDocuments);
      
      // 날짜 비교 시 null 안전하게 처리
      sortedDocuments.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1; // null은 마지막으로
        if (bDate == null) return -1;
        
        return bDate.compareTo(aDate); // 최신순
      });
      
      // 개수 제한
      final recentDocuments = sortedDocuments.take(limit).toList();
      
      // 도메인 객체로 변환
      final documents = recentDocuments.map((model) => model.toDomain()).toList();
      return Result.success(documents);
    } catch (e) {
      debugPrint('최근 문서 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final allDocuments = await _localDataSource.getDocuments();
      
      // 즐겨찾기된 문서만 필터링
      final favoriteDocuments = allDocuments.where((doc) => doc.isFavorite).toList();
      
      // 도메인 객체로 변환
      final documents = favoriteDocuments.map((model) => model.toDomain()).toList();
      return Result.success(documents);
    } catch (e) {
      debugPrint('즐겨찾기 문서 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<String>> uploadPDFFile(Uint8List file) async {
    try {
      final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // 웹 환경에서는 로컬 스토리지에 저장
      if (kIsWeb) {
        final webFileName = 'web_$fileName';
        
        // 웹 환경에서는 IndexedDB 또는 localStorage에 바이트 데이터 저장 (예시 코드)
        final prefs = await SharedPreferences.getInstance();
        final base64Data = base64Encode(file);
        await prefs.setString(webFileName, base64Data);
        
        // 웹 환경에서는 메모리 경로 반환
        return Result.success(webFileName);
      }
      
      // 네이티브 환경에서는 Firebase Storage에 업로드
      final path = await _firebaseService.uploadBytes(file, 'pdfs/$fileName');
      return Result.success(path);
    } catch (e) {
      debugPrint('PDF 파일 업로드 중 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> deletePDFFile(String filePath) async {
    try {
      await _firebaseService.deleteFile(filePath);
      return Result.success(null);
    } catch (e) {
      debugPrint('PDF 파일 삭제 중 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<int>> getPageCount(String filePath) async {
    try {
      // 네트워크 파일
      if (filePath.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(filePath));
          if (response.statusCode == 200) {
            final document = PdfDocument(inputBytes: response.bodyBytes);
            final count = document.pages.count;
            document.dispose();
            return Result.success(count);
          } else {
            return Result.failure(Exception('PDF 파일을 다운로드할 수 없습니다.'));
          }
        } catch (e) {
          debugPrint('네트워크 PDF 페이지 수 오류: $e');
          return Result.failure(Exception('페이지 수 계산 오류: $e'));
        }
      }
      
      // 메모리 파일 (웹 환경)
      if (kIsWeb || filePath.startsWith('memory://')) {
        return Result.success(1); // 웹 환경에서는 기본값 반환
      }
      
      // 로컬 파일 (모바일/데스크톱)
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final count = document.pages.count;
        document.dispose();
        return Result.success(count);
      } else {
        return Result.failure(Exception('파일을 찾을 수 없습니다.'));
      }
    } catch (e) {
      debugPrint('페이지 수 계산 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<String>> extractText(String filePath, int pageNumber) async {
    Uint8List? bytes;
    
    try {
      // 네트워크 파일
      if (filePath.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(filePath));
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
          } else {
            return Result.failure(Exception('PDF 파일을 다운로드할 수 없습니다.'));
          }
        } catch (e) {
          return Result.failure(Exception('PDF 다운로드 오류: $e'));
        }
      } 
      // 웹 환경 또는 메모리 파일
      else if (kIsWeb || filePath.startsWith('memory://')) {
        return Result.success('웹 환경에서는 텍스트 추출이 지원되지 않습니다.');
      }
      // 로컬 파일 (모바일/데스크톱)
      else {
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          return Result.failure(Exception('파일을 찾을 수 없습니다.'));
        }
      }
      
      if (bytes != null) {
        final document = PdfDocument(inputBytes: bytes);
        
        if (pageNumber < 1 || pageNumber > document.pages.count) {
          document.dispose();
          return Result.failure(Exception('유효하지 않은 페이지 번호입니다.'));
        }
        
        final page = document.pages[pageNumber - 1];
        final text = PdfTextExtractor(document).extractText(startPageIndex: pageNumber - 1, endPageIndex: pageNumber - 1);
        document.dispose();
        
        return Result.success(text);
      } else {
        return Result.failure(Exception('PDF 데이터를 로드할 수 없습니다.'));
      }
    } catch (e) {
      debugPrint('텍스트 추출 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getMetadata(String filePath) async {
    Uint8List? bytes;
    
    try {
      // 네트워크 파일
      if (filePath.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(filePath));
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
          } else {
            return Result.failure(Exception('PDF 파일을 다운로드할 수 없습니다.'));
          }
        } catch (e) {
          return Result.failure(Exception('PDF 다운로드 오류: $e'));
        }
      } 
      // 웹 환경 또는 메모리 파일
      else if (kIsWeb || filePath.startsWith('memory://')) {
        // 웹 환경에서는 기본 메타데이터 반환
        return Result.success({
          'title': '문서',
          'author': '알 수 없음',
          'creator': '알 수 없음',
          'keywords': '',
          'producer': '',
          'subject': '',
          'creationDate': DateTime.now().toString(),
          'modificationDate': DateTime.now().toString(),
        });
      }
      // 로컬 파일 (모바일/데스크톱)
      else {
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          return Result.failure(Exception('파일을 찾을 수 없습니다.'));
        }
      }
      
      if (bytes != null) {
        final document = PdfDocument(inputBytes: bytes);
        final Map<String, dynamic> metadata = {};
        
        metadata['pageCount'] = document.pages.count;
        
        if (document.documentInformation != null) {
          final info = document.documentInformation!;
          metadata['title'] = info.title ?? '문서';
          metadata['author'] = info.author ?? '알 수 없음';
          metadata['creator'] = info.creator ?? '알 수 없음';
          metadata['keywords'] = info.keywords ?? '';
          metadata['producer'] = info.producer ?? '';
          metadata['subject'] = info.subject ?? '';
          metadata['creationDate'] = info.creationDate?.toString() ?? '';
          metadata['modificationDate'] = info.modificationDate?.toString() ?? '';
        }
        
        document.dispose();
        return Result.success(metadata);
      } else {
        return Result.failure(Exception('PDF 데이터를 로드할 수 없습니다.'));
      }
    } catch (e) {
      debugPrint('메타데이터 추출 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  void dispose() {
    // 리소스 정리
  }

  @override
  Future<Result<PDFDocument?>> pickAndUploadPDF() async {
    try {
      Uint8List? bytes;
      String? fileName;
      
      // 파일 선택
      final result = await ConditionalFilePicker.pickFiles(
        type: FilePickerType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return Result.failure(Exception('파일이 선택되지 않았습니다.'));
      }
      
      final file = result.files.first;
      
      // 파일 이름 정리
      fileName = file.name;
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }
      
      // 웹 환경
      if (kIsWeb) {
        bytes = file.bytes;
        if (bytes == null) {
          return Result.failure(Exception('파일 데이터를 읽을 수 없습니다.'));
        }
      } 
      // 모바일/데스크톱 환경
      else {
        if (file.path == null) {
          return Result.failure(Exception('파일 경로가 유효하지 않습니다.'));
        }
        
        final pdfFile = File(file.path!);
        bytes = await pdfFile.readAsBytes();
      }
      
      if (bytes == null) {
        return Result.failure(Exception('파일 데이터를 읽을 수 없습니다.'));
      }
      
      // 파일 크기 체크
      if (bytes.length > 10 * 1024 * 1024) { // 10MB 제한
        return Result.failure(Exception('파일 크기가 10MB를 초과합니다.'));
      }
      
      // 파일 업로드 및 문서 생성
      final uploadResult = await uploadPDFFile(bytes);
      
      final filePath = await uploadResult.when(
        success: (path) => path,
        failure: (error) => throw error,
      );
      
      // 문서 모델 생성
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: fileName.replaceAll('.pdf', ''),
        description: '',
        filePath: filePath,
        thumbnailUrl: '',
        pageCount: 0,
        currentPage: 1,
        readingProgress: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        isSelected: false,
        tags: [],
        fileSize: bytes.length,
      );
      
      // 문서 저장
      final saveResult = await saveDocument(document);
      
      return saveResult.when(
        success: (doc) => Result.success(doc),
        failure: (error) => Result.failure(error),
      );
    } catch (e) {
      debugPrint('PDF 가져오기 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<PDFDocument>> createDocument(PDFDocument document) async {
    try {
      // 로컬에 저장
      final documentModel = PDFDocumentModel.fromDomain(document);
      await _localDataSource.saveDocument(documentModel);
      
      // 원격에 저장
      try {
        final remoteResult = await _remoteDataSource.createDocument(documentModel);
        
        if (remoteResult.isFailure) {
          debugPrint('원격 문서 생성 실패: ${remoteResult.error}');
          // 원격 저장 실패해도 로컬 저장은 성공으로 처리
        }
      } catch (e) {
        debugPrint('원격 문서 생성 오류: $e');
        // 원격 저장 실패해도 로컬 저장은 성공으로 처리
      }
      
      return Result.success(document);
    } catch (e) {
      debugPrint('문서 생성 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarksForDocument(String documentId) async {
    try {
      final result = await _firebaseService.getBookmarksForDocument(documentId);
      return result;
    } catch (e) {
      return Result.failure(Exception('문서 북마크 목록 조회 실패: $e'));
    }
  }
  
  @override
  Future<Result<int>> saveLastReadPage(String documentId, int page) async {
    try {
      await _localDataSource.saveLastReadPage(documentId, page);
      
      try {
        // 원격 저장소에도 저장 시도 (선택적)
        await _remoteDataSource.saveLastReadPage(documentId, page);
      } catch (e) {
        debugPrint('원격 마지막 읽은 페이지 저장 오류: $e');
        // 원격 저장 실패해도 로컬 저장은 성공으로 처리
      }
      
      return Result.success(page);
    } catch (e) {
      debugPrint('마지막 읽은 페이지 저장 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<int>> getLastReadPage(String documentId) async {
    try {
      final lastPage = await _localDataSource.getLastReadPage(documentId);
      return Result.success(lastPage);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 조회 실패: $e'));
    }
  }
  
  @override
  Future<Result<List<PDFDocument>>> sortDocuments(
    List<PDFDocument> documents,
    String sortBy,
    bool ascending,
  ) async {
    try {
      final sortedDocuments = List<PDFDocument>.from(documents);
      
      switch (sortBy) {
        case 'title':
          sortedDocuments.sort((a, b) => 
            ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title)
          );
          break;
        
        case 'createdAt':
          sortedDocuments.sort((a, b) {
            final aDate = a.createdAt;
            final bDate = b.createdAt;
            
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return ascending ? -1 : 1; 
            if (bDate == null) return ascending ? 1 : -1;
            
            return ascending 
              ? aDate.compareTo(bDate) 
              : bDate.compareTo(aDate);
          });
          break;
        
        case 'updatedAt':
          sortedDocuments.sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt;
            final bDate = b.updatedAt ?? b.createdAt;
            
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return ascending ? -1 : 1; 
            if (bDate == null) return ascending ? 1 : -1;
            
            return ascending 
              ? aDate.compareTo(bDate) 
              : bDate.compareTo(aDate);
          });
          break;
        
        case 'size':
          sortedDocuments.sort((a, b) => 
            ascending ? a.size.compareTo(b.size) : b.size.compareTo(a.size)
          );
          break;
          
        case 'importance':
          sortedDocuments.sort((a, b) => 
            ascending 
              ? a.importance.index.compareTo(b.importance.index) 
              : b.importance.index.compareTo(a.importance.index)
          );
          break;
          
        default:
          // 기본 정렬은 제목 (오름차순)
          sortedDocuments.sort((a, b) => a.title.compareTo(b.title));
      }
      
      return Result.success(sortedDocuments);
    } catch (e) {
      debugPrint('문서 정렬 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<PDFBookmark>> getBookmark(String id) async {
    try {
      // 로컬에서 먼저 조회
      final bookmark = await _localDataSource.getBookmark(id);
      
      if (bookmark != null) {
        return Result.success(bookmark.toDomain());
      }
      
      // 로컬에 없으면 원격에서 조회
      try {
        final remoteResult = await _remoteDataSource.getBookmark(id);
        
        if (remoteResult.isSuccess && remoteResult.data != null) {
          // 로컬에 저장
          await _localDataSource.saveBookmark(remoteResult.data!);
          return Result.success(remoteResult.data!.toDomain());
        } else {
          return Result.failure(Exception('북마크를 찾을 수 없습니다.'));
        }
      } catch (e) {
        return Result.failure(Exception(e.toString()));
      }
    } catch (e) {
      return Result.failure(Exception(e.toString()));
    }
  }

  @override
  Future<Uint8List?> loadSamplePdf() async {
    try {
      final asset = 'assets/sample.pdf';
      final data = await rootBundle.load(asset);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('샘플 PDF 로드 오류: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> loadLocalPdf(String filePath) async {
    try {
      // 웹 환경 또는 메모리 파일
      if (kIsWeb || filePath.startsWith('memory://') || filePath.startsWith('http')) {
        debugPrint('웹 환경에서는 로컬 PDF 로드가 지원되지 않습니다.');
        return null;
      }
      
      // 로컬 파일 (모바일/데스크톱)
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('로컬 PDF 로드 오류: $e');
      return null;
    }
  }

  @override
  Future<Result<Uint8List>> getPDFData(String url) async {
    try {
      // URL이 http로 시작하면 네트워크에서 가져오기
      if (url.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            return Result.success(response.bodyBytes);
          } else {
            return Result.failure(Exception('PDF 데이터를 가져오는데 실패했습니다. 상태 코드: ${response.statusCode}'));
          }
        } catch (e) {
          debugPrint('네트워크 PDF 다운로드 오류: $e');
          return Result.failure(Exception('PDF 다운로드 오류: $e'));
        }
      }
      
      // 웹 환경에서 로컬 파일 접근 시 예외처리
      if (kIsWeb) {
        return Result.failure(Exception('웹 환경에서는 로컬 파일 접근이 불가능합니다.'));
      }
      
      // 로컬 파일인 경우
      final file = File(url);
      if (await file.exists()) {
        return Result.success(await file.readAsBytes());
      } else {
        return Result.failure(Exception('파일을 찾을 수 없습니다: $url'));
      }
    } catch (e) {
      debugPrint('PDF 데이터 로드 오류: $e');
      return Result.failure(Exception('PDF 다운로드 오류: $e'));
    }
  }
} 