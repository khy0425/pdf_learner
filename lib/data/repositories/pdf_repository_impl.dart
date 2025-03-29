import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/base/result.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/storage/storage_service.dart';
import '../../core/utils/web_utils.dart';
import '../datasources/pdf_local_data_source.dart';
import '../datasources/pdf_remote_data_source.dart';

/// PDF 저장소 구현체
@Injectable(as: PDFRepository)
class PDFRepositoryImpl implements PDFRepository {
  final PDFLocalDataSource _localDataSource;
  final PDFRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final FirebaseService _firebaseService;
  final SharedPreferences _sharedPreferences;
  final WebUtils _webUtils;

  PDFRepositoryImpl({
    required PDFLocalDataSource localDataSource,
    required PDFRemoteDataSource remoteDataSource,
    required StorageService storageService,
    required FirebaseService firebaseService,
    required SharedPreferences sharedPreferences,
    required WebUtils webUtils,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _storageService = storageService,
       _firebaseService = firebaseService,
       _sharedPreferences = sharedPreferences,
       _webUtils = webUtils;

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final result = await _localDataSource.getDocuments();
      if (result.isFailure) {
        return result;
      }
      return Result.success(result.data ?? []);
    } catch (e) {
      return Result.failure(Exception('문서 목록을 가져오는 중 오류: $e'));
    }
  }

  @override
  Future<Result<PDFDocument?>> getDocument(String id) async {
    try {
      final result = await _localDataSource.getDocument(id);
      if (result.isFailure) {
        return result;
      }
      return Result.success(result.data);
    } catch (e) {
      return Result.failure(Exception('문서를 가져오는 중 오류: $e'));
    }
  }

  @override
  Future<Result<PDFDocument>> saveDocument(PDFDocument document) async {
    try {
      final result = await _localDataSource.saveDocument(document);
      if (result.isFailure) {
        return Result.failure(result.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _syncDocumentToCloud(document);
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('문서 저장 중 오류: $e'));
    }
  }

  Future<void> _syncDocumentToCloud(PDFDocument document) async {
    try {
      await _remoteDataSource.addDocument(document);
    } catch (e) {
      debugPrint('문서 클라우드 동기화 실패: $e');
    }
  }

  @override
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    try {
      final result = await _localDataSource.saveDocument(document);
      if (result.isFailure) {
        return Result.failure(result.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _syncDocumentToCloud(document);
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('문서 업데이트 중 오류: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteDocument(String id) async {
    try {
      final result = await _localDataSource.deleteDocument(id);
      if (result.isFailure) {
        return Result.failure(result.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _deleteDocumentFromCloud(id);
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('문서 삭제 중 오류: $e'));
    }
  }

  Future<void> _deleteDocumentFromCloud(String id) async {
    try {
      await _remoteDataSource.deleteDocument(id);
    } catch (e) {
      debugPrint('문서 클라우드 삭제 실패: $e');
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      final result = await _localDataSource.getBookmarks(documentId);
      if (result.isFailure) {
        return result;
      }
      return Result.success(result.data ?? []);
    } catch (e) {
      return Result.failure(Exception('북마크 목록을 가져오는 중 오류: $e'));
    }
  }

  @override
  Future<Result<PDFBookmark?>> getBookmark(String id) async {
    try {
      final result = await _localDataSource.getBookmark(id);
      if (result.isFailure) {
        return result;
      }
      return Result.success(result.data);
    } catch (e) {
      return Result.failure(Exception('북마크를 가져오는 중 오류: $e'));
    }
  }

  @override
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final result = await _localDataSource.saveBookmark(bookmark);
      if (result.isFailure) {
        return Result.failure(result.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _syncBookmarkToCloud(bookmark);
      
      return Result.success(bookmark);
    } catch (e) {
      return Result.failure(Exception('북마크 저장 중 오류: $e'));
    }
  }

  Future<void> _syncBookmarkToCloud(PDFBookmark bookmark) async {
    try {
      await _remoteDataSource.addBookmark(bookmark);
    } catch (e) {
      debugPrint('북마크 클라우드 동기화 실패: $e');
    }
  }

  @override
  Future<Result<bool>> deleteBookmark(String id) async {
    try {
      final result = await _localDataSource.deleteBookmark(id);
      if (result.isFailure) {
        return Result.failure(result.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _deleteBookmarkFromCloud(id);
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제 중 오류: $e'));
    }
  }

  Future<void> _deleteBookmarkFromCloud(String id) async {
    try {
      // 북마크에서 문서 ID 가져오기
      final bookmarkResult = await _localDataSource.getBookmark(id);
      
      if (bookmarkResult.isSuccess && bookmarkResult.data != null) {
        final documentId = bookmarkResult.data!.documentId;
        await _remoteDataSource.deleteBookmark(documentId, id);
      } else {
        debugPrint('북마크를 찾을 수 없습니다: $id');
      }
    } catch (e) {
      debugPrint('북마크 클라우드 삭제 실패: $e');
    }
  }

  @override
  Future<Result<int>> getLastReadPage(String documentId) async {
    try {
      return await _localDataSource.getLastReadPage(documentId);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<void>> saveLastReadPage(String documentId, int page) async {
    try {
      return await _localDataSource.saveLastReadPage(documentId, page);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 저장 실패: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final documentResult = await _localDataSource.getDocument(id);
      if (documentResult.isFailure) {
        return Result.failure(documentResult.error);
      }
      
      final document = documentResult.data;
      if (document == null) {
        return Result.failure(Exception('문서를 찾을 수 없습니다'));
      }
      
      final updatedDocument = document.copyWith(
        isFavorite: !document.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      final saveResult = await _localDataSource.saveDocument(updatedDocument);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.error);
      }
      
      // 클라우드 동기화 (백그라운드)
      _syncDocumentToCloud(updatedDocument);
      
      return Result.success(updatedDocument.isFavorite);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 토글 중 오류: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final documentsResult = await _localDataSource.getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data ?? [];
      final favoriteDocuments = documents.where((doc) => doc.isFavorite).toList();
      
      return Result.success(favoriteDocuments);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 문서 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments([int limit = 10]) async {
    try {
      final documentsResult = await _localDataSource.getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data ?? [];
      // 마지막 접근 시간 기준으로 정렬 (최신순)
      documents.sort((a, b) {
        final dateA = a.lastAccessedAt ?? a.createdAt ?? DateTime(1970);
        final dateB = b.lastAccessedAt ?? b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      // 지정된 개수만큼 반환
      final recentDocuments = documents.take(limit).toList();
      
      return Result.success(recentDocuments);
    } catch (e) {
      return Result.failure(Exception('최근 문서 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getSearchHistory() async {
    try {
      // 검색 기록 가져오기
      final searchHistoryJson = _sharedPreferences.getStringList('search_history') ?? [];
      return Result.success(searchHistoryJson);
    } catch (e) {
      return Result.failure(Exception('검색 기록 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<void>> addSearchQuery(String query) async {
    try {
      // 중복 제거 및 최신 검색어를 앞으로
      final currentHistory = _sharedPreferences.getStringList('search_history') ?? [];
      final newHistory = [
        query,
        ...currentHistory.where((item) => item != query),
      ];
      
      // 최대 20개까지만 유지
      final trimmedHistory = newHistory.take(20).toList();
      
      // 저장
      await _sharedPreferences.setStringList('search_history', trimmedHistory);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('검색 쿼리 추가 실패: $e'));
    }
  }

  @override
  Future<Result<void>> clearSearchHistory() async {
    try {
      await _sharedPreferences.remove('search_history');
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('검색 기록 삭제 실패: $e'));
    }
  }

  @override
  Future<Result<void>> syncWithRemote() async {
    try {
      final localDocsResult = await _localDataSource.getDocuments();
      if (localDocsResult.isFailure) {
        return Result.failure(localDocsResult.error);
      }
      
      final localDocs = localDocsResult.data ?? [];
      
      // 북마크도 동기화
      final localBookmarksResult = await _localDataSource.getAllBookmarks();
      if (localBookmarksResult.isFailure) {
        return Result.failure(localBookmarksResult.error);
      }
      
      final localBookmarks = localBookmarksResult.data ?? [];
      
      // 원격 동기화 수행
      final syncResult = await _remoteDataSource.syncWithRemote(localDocs, localBookmarks);
      if (syncResult.isFailure) {
        return Result.failure(syncResult.error);
      }
      
      // 동기화된 문서 로컬에 저장
      final syncedDocs = syncResult.data ?? [];
      for (final doc in syncedDocs) {
        await _localDataSource.saveDocument(doc);
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('원격 동기화 중 오류: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> downloadPdf(PDFDocument document) async {
    try {
      if (document.downloadUrl.isEmpty) {
        return Result.failure(Exception('다운로드 URL이 없습니다'));
      }
      
      // 이미 로컬에 파일이 있는지 확인
      final existsResult = await fileExists(document.filePath);
      if (existsResult.isSuccess && existsResult.data) {
        // 로컬 파일이 있으면 그대로 반환
        return getPdfBytes(document.filePath);
      }
      
      // 로컬에 없으면 다운로드
      final response = await http.get(Uri.parse(document.downloadUrl));
      
      if (response.statusCode == 200) {
        // 파일 저장
        final fileName = path.basename(document.downloadUrl);
        final directory = await getTemporaryDirectory();
        final filePath = path.join(directory.path, fileName);
        
        final file = io.File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        return Result.success(response.bodyBytes);
      } else {
        return Result.failure(
          Exception('다운로드 실패: HTTP 상태 코드 ${response.statusCode}')
        );
      }
    } catch (e) {
      return Result.failure(Exception('PDF 다운로드 중 오류: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> downloadPdfFromUrl(String url) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서의 처리
        try {
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            // 웹 저장소에 저장
            final fileId = 'web_${DateTime.now().millisecondsSinceEpoch}';
            await _webUtils.saveBytesToIndexedDB(fileId, response.bodyBytes);
            
            return Result.success(response.bodyBytes);
          } else {
            return Result.failure(
              Exception('다운로드 실패: HTTP 상태 코드 ${response.statusCode}')
            );
          }
        } catch (e) {
          return Result.failure(Exception('URL에서 PDF 다운로드 중 오류: $e'));
        }
      } else {
        // 네이티브 환경에서의 처리
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          return Result.success(response.bodyBytes);
        } else {
          return Result.failure(
            Exception('다운로드 실패: HTTP 상태 코드 ${response.statusCode}')
          );
        }
      }
    } catch (e) {
      return Result.failure(Exception('URL에서 PDF 다운로드 중 오류: $e'));
    }
  }

  @override
  Future<Result<String>> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    try {
      final io.Directory appDocDir = await getApplicationDocumentsDirectory();
      final String targetDir = directory ?? path.join(appDocDir.path, 'pdfs');
      
      // 디렉토리 생성
      final dir = io.Directory(targetDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // 파일 저장
      final filePath = path.join(targetDir, fileName);
      final file = io.File(filePath);
      await file.writeAsBytes(bytes);
      
      return Result.success(filePath);
    } catch (e) {
      return Result.failure(Exception('파일 저장 중 오류: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteFile(String path) async {
    try {
      final file = io.File(path);
      if (await file.exists()) {
        await file.delete();
        return Result.success(true);
      }
      return Result.success(false);
    } catch (e) {
      return Result.failure(Exception('파일 삭제 중 오류: $e'));
    }
  }

  @override
  Future<Result<bool>> fileExists(String path) async {
    try {
      final file = io.File(path);
      final exists = await file.exists();
      return Result.success(exists);
    } catch (e) {
      return Result.failure(Exception('파일 존재 여부 확인 중 오류: $e'));
    }
  }

  @override
  Future<Result<int>> getFileSize(String path) async {
    try {
      final file = io.File(path);
      if (!await file.exists()) {
        return Result.failure(Exception('파일이 존재하지 않습니다'));
      }
      
      final fileSize = await file.length();
      return Result.success(fileSize);
    } catch (e) {
      return Result.failure(Exception('파일 크기 조회 중 오류: $e'));
    }
  }

  @override
  Future<Result<void>> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      
      // 디렉토리 삭제 후 재생성
      final directory = io.Directory(cacheDir.path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('캐시 초기화 중 오류: $e'));
    }
  }

  @override
  Future<Result<PDFDocument>> importPDF(io.File file) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 다른 방식으로 처리 필요
        final fileName = path.basename(file.path);
        final fileId = const Uuid().v4();
        
        try {
          final bytes = await file.readAsBytes();
          
          // 웹 스토리지에 저장
          await _webUtils.saveBytesToIndexedDB(fileId, bytes);
          
          // 문서 메타데이터 생성
          final document = PDFDocument(
            id: fileId,
            title: fileName.replaceAll('.pdf', ''),
            filePath: fileId, // 웹에서는 ID를 경로로 사용
            fileSize: bytes.length,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // 문서 저장
          await _localDataSource.saveDocument(document);
          
          return Result.success(document);
        } catch (e) {
          return Result.failure(Exception('웹 환경에서 PDF 가져오기 실패: $e'));
        }
      } else {
        return await _localDataSource.importPDF(file);
      }
    } catch (e) {
      return Result.failure(Exception('PDF 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> loadSamplePdf() async {
    try {
      final asset = 'assets/sample.pdf';
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      return Result.success(bytes);
    } catch (e) {
      return Result.failure(Exception('샘플 PDF 로드 중 오류: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> getPdfBytes(String filePath) async {
    try {
      // 웹 URL 처리
      if (filePath.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(filePath));
          
          if (response.statusCode == 200) {
            return Result.success(response.bodyBytes);
          } else {
            return Result.failure(
              Exception('PDF 다운로드 실패: HTTP 상태 코드 ${response.statusCode}')
            );
          }
        } catch (e) {
          return Result.failure(Exception('URL에서 PDF 다운로드 중 오류: $e'));
        }
      }
      
      // 로컬 파일 처리
      final file = io.File(filePath);
      
      if (!await file.exists()) {
        return Result.failure(Exception('파일이 존재하지 않습니다: $filePath'));
      }
      
      final bytes = await file.readAsBytes();
      return Result.success(bytes);
    } catch (e) {
      return Result.failure(Exception('PDF 파일 읽기 중 오류: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> searchDocuments(String query) async {
    try {
      final documentsResult = await _localDataSource.getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data ?? [];
      final lowercaseQuery = query.toLowerCase();
      
      // 제목, 설명 등에서 검색
      final filteredDocuments = documents.where((doc) {
        return doc.title.toLowerCase().contains(lowercaseQuery) ||
               (doc.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               (doc.author?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               doc.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
      
      // 검색 기록 저장
      final addResult = await addSearchQuery(query);
      if (addResult.isFailure) {
        debugPrint('검색 기록 저장 실패: ${addResult.error}');
      }
      
      return Result.success(filteredDocuments);
    } catch (e) {
      return Result.failure(Exception('문서 검색 중 오류: $e'));
    }
  }
} 