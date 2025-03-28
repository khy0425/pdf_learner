import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';
import '../../core/base/result.dart';
import '../../data/datasources/pdf_local_data_source.dart';
import '../../data/datasources/pdf_remote_data_source.dart';
import '../../services/firebase_service.dart';
import '../../services/storage/storage_service.dart';

/// PDF 레포지토리 인터페이스
abstract class PDFRepository {
  /// 모든 PDF 문서 목록을 가져옵니다.
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// ID로 특정 PDF 문서를 가져옵니다.
  Future<Result<PDFDocument?>> getDocument(String id);
  
  /// PDF 문서를 저장합니다.
  Future<Result<PDFDocument>> saveDocument(PDFDocument document);
  
  /// PDF 문서를 업데이트합니다.
  Future<Result<PDFDocument>> updateDocument(PDFDocument document);
  
  /// PDF 문서를 삭제합니다.
  Future<Result<bool>> deleteDocument(String id);
  
  /// PDF 문서의 북마크 목록을 가져옵니다.
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// URL로부터 PDF 파일을 다운로드합니다.
  Future<Result<String>> downloadPdf(PDFDocument document);
  
  Future<Result<bool>> toggleFavorite(String id);
  
  Future<Result<PDFBookmark?>> getBookmark(String id);
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark);
  Future<Result<bool>> deleteBookmark(String id);
  
  Future<Result<int>> getLastReadPage(String documentId);
  Future<Result<void>> saveLastReadPage(String documentId, int page);
  
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  Future<Result<List<PDFDocument>>> getRecentDocuments();
  
  Future<Result<List<String>>> getSearchHistory();
  Future<Result<void>> addSearchQuery(String query);
  Future<Result<void>> clearSearchHistory();
  
  Future<Result<void>> syncWithRemote();
  Future<Result<String>> saveFile(Uint8List bytes, String fileName, {String? directory});
  Future<Result<bool>> deleteFile(String path);
  Future<Result<bool>> fileExists(String path);
  Future<Result<int>> getFileSize(String path);
  Future<Result<void>> clearCache();
  
  /// 로컬 파일로부터 PDF를 가져옵니다.
  Future<Result<PDFDocument>> importPDF(File file);
  
  /// 샘플 PDF 파일을 로드합니다.
  Future<Result<Uint8List>> loadSamplePdf();
}

@Injectable(as: PDFRepository)
class PDFRepositoryImpl implements PDFRepository {
  final PDFLocalDataSource _localDataSource;
  final PDFRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final FirebaseService _firebaseService;
  final SharedPreferences _sharedPreferences;

  PDFRepositoryImpl({
    required PDFLocalDataSource localDataSource,
    required PDFRemoteDataSource remoteDataSource,
    required StorageService storageService,
    required FirebaseService firebaseService,
    required SharedPreferences sharedPreferences,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _storageService = storageService,
       _firebaseService = firebaseService,
       _sharedPreferences = sharedPreferences;

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    return await _localDataSource.getDocuments();
  }

  @override
  Future<Result<PDFDocument?>> getDocument(String id) async {
    return await _localDataSource.getDocument(id);
  }

  @override
  Future<Result<PDFDocument>> saveDocument(PDFDocument document) async {
    final saveResult = await _localDataSource.saveDocument(document);
    if (saveResult.isFailure) {
      return Result.failure(saveResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _syncDocumentToCloud(document);
    
    return Result.success(document);
  }
  
  @override
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    final saveResult = await _localDataSource.saveDocument(document);
    if (saveResult.isFailure) {
      return Result.failure(saveResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _syncDocumentToCloud(document);
    
    return Result.success(document);
  }

  Future<void> _syncDocumentToCloud(PDFDocument document) async {
    try {
      await _remoteDataSource.addDocument(document);
    } catch (e) {
      debugPrint('문서 클라우드 동기화 실패: $e');
    }
  }

  @override
  Future<Result<bool>> deleteDocument(String id) async {
    final deleteResult = await _localDataSource.deleteDocument(id);
    if (deleteResult.isFailure) {
      return Result.failure(deleteResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _deleteDocumentFromCloud(id);
    
    return Result.success(true);
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
    return await _localDataSource.getBookmarks(documentId);
  }

  @override
  Future<Result<PDFBookmark?>> getBookmark(String id) async {
    return await _localDataSource.getBookmark(id);
  }

  @override
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark) async {
    final saveResult = await _localDataSource.saveBookmark(bookmark);
    if (saveResult.isFailure) {
      return Result.failure(saveResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _syncBookmarkToCloud(bookmark);
    
    return Result.success(bookmark);
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
    final deleteResult = await _localDataSource.deleteBookmark(id);
    if (deleteResult.isFailure) {
      return Result.failure(deleteResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _deleteBookmarkFromCloud(id);
    
    return Result.success(true);
  }

  Future<void> _deleteBookmarkFromCloud(String id) async {
    try {
      await _remoteDataSource.deleteBookmark(id);
    } catch (e) {
      debugPrint('북마크 클라우드 삭제 실패: $e');
    }
  }

  @override
  Future<Result<int>> getLastReadPage(String documentId) async {
    return await _localDataSource.getLastReadPage(documentId);
  }

  @override
  Future<Result<void>> saveLastReadPage(String documentId, int page) async {
    final saveResult = await _localDataSource.saveLastReadPage(documentId, page);
    if (saveResult.isFailure) {
      return saveResult;
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _syncLastReadPageToCloud(documentId, page);
    
    return Result.success(null);
  }

  Future<void> _syncLastReadPageToCloud(String documentId, int page) async {
    try {
      await _remoteDataSource.saveLastReadPage(documentId, page);
    } catch (e) {
      debugPrint('마지막 읽은 페이지 클라우드 동기화 실패: $e');
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    final documentResult = await _localDataSource.getDocument(id);
    if (documentResult.isFailure) {
      return Result.failure(documentResult.error!);
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
      return Result.failure(saveResult.error!);
    }
    
    // 클라우드 동기화 (백그라운드에서 수행)
    _syncDocumentToCloud(updatedDocument);
    
    return Result.success(updatedDocument.isFavorite);
  }

  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    return await _localDataSource.getFavoriteDocuments();
  }

  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments() async {
    final documentsResult = await _localDataSource.getDocuments();
    if (documentsResult.isFailure) {
      return documentsResult;
    }
    
    final documents = documentsResult.data!;
    // lastOpenedAt 기준으로 정렬 (최신순)
    documents.sort((a, b) => b.lastOpenedAt?.compareTo(a.lastOpenedAt ?? DateTime(1970)) ?? 0);
    // 최대 10개만 반환
    final recentDocuments = documents.take(10).toList();
    
    return Result.success(recentDocuments);
  }

  @override
  Future<Result<List<String>>> getSearchHistory() async {
    return await _localDataSource.getSearchHistory();
  }

  @override
  Future<Result<void>> addSearchQuery(String query) async {
    return await _localDataSource.addSearchQuery(query);
  }

  @override
  Future<Result<void>> clearSearchHistory() async {
    return await _localDataSource.clearSearchHistory();
  }

  @override
  Future<Result<void>> syncWithRemote() async {
    final documentsResult = await _localDataSource.getDocuments();
    if (documentsResult.isFailure) {
      return Result.failure(documentsResult.error!);
    }
    
    final bookmarksResult = await _localDataSource.getAllBookmarks();
    if (bookmarksResult.isFailure) {
      return Result.failure(bookmarksResult.error!);
    }
    
    // 원격 동기화
    try {
      final syncResult = await _remoteDataSource.syncWithRemote(
        documentsResult.data!, 
        bookmarksResult.data!
      );
      
      if (syncResult.isSuccess) {
        // 원격에서 업데이트된 문서들을 로컬에도 업데이트
        final updatedDocuments = syncResult.data!;
        for (final doc in updatedDocuments) {
          await _localDataSource.saveDocument(doc);
        }
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('동기화 실패: $e'));
    }
  }

  @override
  Future<Result<String>> saveFile(Uint8List bytes, String fileName, {String? directory}) async {
    try {
      final result = await _storageService.saveFile(bytes, fileName, directory: directory);
      return Result.success(result);
    } catch (e) {
      return Result.failure(Exception('파일 저장 중 오류 발생: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return Result.success(true);
      }
      return Result.success(false); // 파일이 존재하지 않음
    } catch (e) {
      return Result.failure(Exception('파일 삭제 중 오류 발생: $e'));
    }
  }

  @override
  Future<Result<bool>> fileExists(String path) async {
    try {
      final file = File(path);
      final exists = await file.exists();
      return Result.success(exists);
    } catch (e) {
      return Result.failure(Exception('파일 존재 확인 중 오류 발생: $e'));
    }
  }

  @override
  Future<Result<int>> getFileSize(String path) async {
    return await _localDataSource.getFileSize(path);
  }

  @override
  Future<Result<void>> clearCache() async {
    return await _localDataSource.clearCache();
  }
  
  @override
  Future<Result<String>> downloadPdf(PDFDocument document) async {
    try {
      // 원격 데이터소스에서 파일 다운로드
      final downloadResult = await _remoteDataSource.downloadPdf(document.id);
      
      if (downloadResult.isFailure) {
        return Result.failure(downloadResult.error!);
      }
      
      final bytes = downloadResult.data!;
      
      // 파일명 생성 (문서 ID + .pdf)
      final fileName = '${document.id}.pdf';
      
      // 로컬에 파일 저장
      final saveResult = await saveFile(bytes, fileName);
      
      if (saveResult.isFailure) {
        return Result.failure(saveResult.error!);
      }
      
      // 문서 상태 업데이트 (다운로드됨으로 표시)
      final updatedDocument = document.copyWith(
        status: PDFDocumentStatus.downloaded,
        localPath: saveResult.data,
      );
      
      // 업데이트된 문서 저장
      await _localDataSource.saveDocument(updatedDocument);
      
      return Result.success(saveResult.data!);
    } catch (e) {
      return Result.failure(Exception('PDF 다운로드 중 오류 발생: $e'));
    }
  }
  
  @override
  Future<Result<PDFDocument>> importPDF(File file) async {
    return await _localDataSource.importPDF(file);
  }

  @override
  Future<Result<Uint8List>> loadSamplePdf() async {
    try {
      // 애셋에서 샘플 PDF 파일 로드(일반적으로 다른 방식으로 구현해야 함)
      final assetPath = 'assets/sample.pdf';
      // 실제 구현은 플랫폼 및 프로젝트 설정에 따라 달라질 수 있음
      // 여기서는 기본 구현만 제공
      if (kIsWeb) {
        // 웹용 구현
        final response = await http.get(Uri.parse(assetPath));
        if (response.statusCode == 200) {
          return Result.success(response.bodyBytes);
        } else {
          return Result.failure(Exception('샘플 PDF 로드 실패: ${response.statusCode}'));
        }
      } else {
        // 모바일용 구현
        try {
          final file = File(assetPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            return Result.success(bytes);
          }
        } catch (e) {
          // 파일 접근 실패 시 무시하고 다음 방식 시도
        }
        
        // 마지막 수단으로 빈 PDF 반환
        return Result.failure(Exception('샘플 PDF를 찾을 수 없습니다'));
      }
    } catch (e) {
      return Result.failure(Exception('샘플 PDF 로드 중 오류: $e'));
    }
  }
} 