import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:pdf_learner_v2/core/utils/web_stub.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/base/result.dart';
import '../../core/utils/web_storage_utils.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';
import 'pdf_local_data_source.dart';
import '../../services/storage/storage_service.dart';

/// PDF 로컬 데이터 소스 구현 클래스
/// 
/// [PDFLocalDataSource] 인터페이스의 기본 구현을 제공합니다.
@Injectable(as: PDFLocalDataSource)
class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final SharedPreferences _sharedPreferences;
  final StorageService _storageService;
  static const _documentsKey = 'pdf_documents';
  static const _bookmarksKey = 'pdf_bookmarks';
  static const _searchHistoryKey = 'pdf_search_history';
  static const _lastReadPagePrefix = 'pdf_last_read_page_';
  final _uuid = const Uuid();

  PDFLocalDataSourceImpl({
    required SharedPreferences prefs,
    required StorageService storageService,
  }) : _sharedPreferences = prefs,
       _storageService = storageService;

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final documents = _getAllDocuments();
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('문서 목록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<PDFDocument?>> getDocument(String id) async {
    try {
      final documents = _getAllDocuments();
      final document = documents.firstWhere(
        (doc) => doc.id == id,
        orElse: () => PDFDocument(
          id: '',
          title: '',
          filePath: '',
          pageCount: 0,
        ),
      );
      
      if (document.id.isEmpty) {
        return Result.success(null);
      }
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('문서를 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments() async {
    try {
      final documents = _getAllDocuments();
      
      // 마지막 접근 시간 기준으로 정렬
      documents.sort((a, b) {
        final aTime = a.lastAccessedAt ?? DateTime.now();
        final bTime = b.lastAccessedAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      // 최근 문서 제한 수 만큼만 반환
      final recentDocs = documents.take(10).toList();
      return Result.success(recentDocs);
    } catch (e) {
      return Result.failure(Exception('최근 문서 목록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final documents = _getAllDocuments();
      final favorites = documents.where((doc) => doc.isFavorite).toList();
      return Result.success(favorites);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 문서 목록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<void>> saveDocument(PDFDocument document) async {
    try {
      final documents = _getAllDocuments();
      
      // 새 문서 혹은 업데이트
      final isNew = !documents.any((doc) => doc.id == document.id);
      
      if (isNew) {
        // 새 문서이면 현재 시간으로 생성 시간 설정
        final newDoc = document.copyWith(
          createdAt: document.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );
        documents.add(newDoc);
      } else {
        // 기존 문서 업데이트
        final index = documents.indexWhere((doc) => doc.id == document.id);
        if (index >= 0) {
          documents[index] = document.copyWith(
            updatedAt: DateTime.now(),
            lastAccessedAt: DateTime.now(),
          );
        }
      }
      
      await _saveDocuments(documents);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('문서 저장에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteDocument(String id) async {
    try {
      final documents = _getAllDocuments();
      final documentToDelete = documents.firstWhere(
        (doc) => doc.id == id,
        orElse: () => PDFDocument(
          id: '',
          title: '',
          filePath: '',
          pageCount: 0,
        ),
      );
      
      if (documentToDelete.id.isEmpty) {
        return Result.success(false);
      }
      
      // 문서 파일도 삭제
      if (documentToDelete.filePath.isNotEmpty) {
        try {
          await _storageService.deleteFile(documentToDelete.filePath);
        } catch (e) {
          // 파일 삭제 실패는 로그만 남기고 계속 진행
          print('파일 삭제 실패: $e');
        }
      }
      
      // 연관된 북마크 삭제
      await _deleteDocumentBookmarks(id);
      
      // 문서 목록에서 제거
      documents.removeWhere((doc) => doc.id == id);
      await _saveDocuments(documents);
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('문서 삭제에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final documents = _getAllDocuments();
      final index = documents.indexWhere((doc) => doc.id == id);
      
      if (index < 0) {
        return Result.success(false);
      }
      
      // 즐겨찾기 상태 토글
      final doc = documents[index];
      documents[index] = doc.copyWith(
        isFavorite: !doc.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      await _saveDocuments(documents);
      return Result.success(!doc.isFavorite);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 상태 변경에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<PDFDocument>> importPDF(File file) async {
    try {
      final targetDir = await _storageService.getDocumentsDirectory();
      final fileName = path.basename(file.path);
      final title = path.basenameWithoutExtension(fileName);
      final targetPath = '${targetDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // 파일 복사
      await _storageService.copyFile(file.path, targetPath);
      
      // 페이지 수 얻기
      final pageCount = await _storageService.getPDFPageCount(targetPath);
      
      // 새 문서 생성
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: title,
        filePath: targetPath,
        pageCount: pageCount,
        fileSize: await file.length(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );
      
      // 저장
      await saveDocument(document);
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 가져오기에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      final bookmarks = _getAllBookmarks();
      final documentBookmarks = bookmarks
          .where((bookmark) => bookmark.documentId == documentId)
          .toList();
      
      return Result.success(documentBookmarks);
    } catch (e) {
      return Result.failure(Exception('북마크 목록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<PDFBookmark?>> getBookmark(String id) async {
    try {
      final bookmarks = _getAllBookmarks();
      final bookmark = bookmarks.firstWhere(
        (bookmark) => bookmark.id == id,
        orElse: () => PDFBookmark(
          id: '',
          documentId: '',
          title: '',
          page: 0,
        ),
      );
      
      if (bookmark.id.isEmpty) {
        return Result.success(null);
      }
      
      return Result.success(bookmark);
    } catch (e) {
      return Result.failure(Exception('북마크를 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<String>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final bookmarks = _getAllBookmarks();
      
      // 새 북마크 혹은 업데이트
      final isNew = !bookmarks.any((mark) => mark.id == bookmark.id);
      
      if (isNew) {
        // 새 북마크이면 현재 시간으로 생성 시간 설정
        final newBookmark = bookmark.copyWith(
          createdAt: bookmark.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        bookmarks.add(newBookmark);
      } else {
        // 기존 북마크 업데이트
        final index = bookmarks.indexWhere((mark) => mark.id == bookmark.id);
        if (index >= 0) {
          bookmarks[index] = bookmark.copyWith(
            updatedAt: DateTime.now(),
          );
        }
      }
      
      await _saveBookmarks(bookmarks);
      return Result.success(bookmark.id);
    } catch (e) {
      return Result.failure(Exception('북마크 저장에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteBookmark(String id) async {
    try {
      final bookmarks = _getAllBookmarks();
      final hasBookmark = bookmarks.any((bookmark) => bookmark.id == id);
      
      if (!hasBookmark) {
        return Result.success(false);
      }
      
      // 북마크 제거
      bookmarks.removeWhere((bookmark) => bookmark.id == id);
      await _saveBookmarks(bookmarks);
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleBookmarkFavorite(String id) async {
    try {
      final bookmarks = _getAllBookmarks();
      final index = bookmarks.indexWhere((bookmark) => bookmark.id == id);
      
      if (index < 0) {
        return Result.success(false);
      }
      
      // 즐겨찾기 상태 토글
      final bookmark = bookmarks[index];
      bookmarks[index] = bookmark.copyWith(
        isFavorite: !bookmark.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      await _saveBookmarks(bookmarks);
      return Result.success(!bookmark.isFavorite);
    } catch (e) {
      return Result.failure(Exception('북마크 즐겨찾기 상태 변경에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> saveLastReadPage(String documentId, int page) async {
    try {
      final documents = _getAllDocuments();
      final index = documents.indexWhere((doc) => doc.id == documentId);
      
      if (index < 0) {
        return Result.success(false);
      }
      
      // 마지막 읽은 페이지 및 접근 시간 업데이트
      final doc = documents[index];
      documents[index] = doc.copyWith(
        lastReadPage: page,
        lastAccessedAt: DateTime.now(),
      );
      
      await _saveDocuments(documents);
      
      // SharedPreferences에도 저장 (빠른 조회용)
      await _sharedPreferences.setInt('$_lastReadPagePrefix$documentId', page);
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 저장에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<int>> getLastReadPage(String documentId) async {
    try {
      // SharedPreferences에서 먼저 조회 (빠른 접근)
      final page = _sharedPreferences.getInt('$_lastReadPagePrefix$documentId');
      
      if (page != null) {
        return Result.success(page);
      }
      
      // 없으면 문서에서 조회
      final documents = _getAllDocuments();
      final document = documents.firstWhere(
        (doc) => doc.id == documentId,
        orElse: () => PDFDocument(
          id: '',
          title: '',
          filePath: '',
          pageCount: 0,
        ),
      );
      
      if (document.id.isEmpty) {
        return Result.success(0);
      }
      
      return Result.success(document.lastReadPage);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지를 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getSearchHistory() async {
    try {
      final history = _sharedPreferences.getStringList(_searchHistoryKey) ?? [];
      return Result.success(history);
    } catch (e) {
      return Result.failure(Exception('검색 기록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> addSearchQuery(String query) async {
    try {
      if (query.trim().isEmpty) {
        return Result.success(false);
      }
      
      final history = _sharedPreferences.getStringList(_searchHistoryKey) ?? [];
      
      // 이미 있으면 제거 후 최상단에 추가
      history.remove(query);
      history.insert(0, query);
      
      // 최대 개수 제한
      if (history.length > 20) {
        history.removeLast();
      }
      
      await _sharedPreferences.setStringList(_searchHistoryKey, history);
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('검색어 저장에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> clearSearchHistory() async {
    try {
      await _sharedPreferences.remove(_searchHistoryKey);
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('검색 기록 삭제에 실패했습니다: $e'));
    }
  }

  /// 모든 문서 데이터 가져오기
  List<PDFDocument> _getAllDocuments() {
    final documentsJson = _sharedPreferences.getString(_documentsKey);
    if (documentsJson == null || documentsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decodedList = jsonDecode(documentsJson);
      return decodedList
          .map((item) => PDFDocument.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('문서 목록 파싱 실패: $e');
      return [];
    }
  }
  
  /// 문서 목록 저장
  Future<void> _saveDocuments(List<PDFDocument> documents) async {
    final jsonData = jsonEncode(documents.map((doc) => doc.toMap()).toList());
    await _sharedPreferences.setString(_documentsKey, jsonData);
  }
  
  /// 모든 북마크 데이터 가져오기
  List<PDFBookmark> _getAllBookmarks() {
    final bookmarksJson = _sharedPreferences.getString(_bookmarksKey);
    if (bookmarksJson == null || bookmarksJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decodedList = jsonDecode(bookmarksJson);
      return decodedList
          .map((item) => PDFBookmark.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('북마크 목록 파싱 실패: $e');
      return [];
    }
  }
  
  /// 북마크 목록 저장
  Future<void> _saveBookmarks(List<PDFBookmark> bookmarks) async {
    final jsonData = jsonEncode(bookmarks.map((bookmark) => bookmark.toMap()).toList());
    await _sharedPreferences.setString(_bookmarksKey, jsonData);
  }
  
  /// 문서에 연관된 모든 북마크 삭제
  Future<void> _deleteDocumentBookmarks(String documentId) async {
    final bookmarks = _getAllBookmarks();
    bookmarks.removeWhere((bookmark) => bookmark.documentId == documentId);
    await _saveBookmarks(bookmarks);
  }

  @override
  void dispose() {
    // 리소스 정리가 필요한 경우 여기에 구현
  }

  @override
  Future<void> clearCache() async {
    try {
      await _storageService.clearCache();
    } catch (e) {
      debugPrint('캐시 정리 실패: $e');
      throw Exception('캐시 정리 실패: $e');
    }
  }

  @override
  Future<String> saveFile(String path, Uint8List bytes) async {
    try {
      return await _storageService.saveFile(bytes, path);
    } catch (e) {
      debugPrint('파일 저장 실패: $e');
      throw Exception('파일 저장 실패: $e');
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      return await _storageService.deleteFile(path);
    } catch (e) {
      debugPrint('파일 삭제 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      return await _storageService.fileExists(path);
    } catch (e) {
      debugPrint('파일 존재 확인 실패: $e');
      return false;
    }
  }

  @override
  Future<int> getFileSize(String path) async {
    try {
      return await _storageService.getFileSize(path);
    } catch (e) {
      debugPrint('파일 크기 확인 실패: $e');
      return 0;
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getAllBookmarks() async {
    try {
      final bookmarks = _getAllBookmarks();
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('모든 북마크 가져오기 실패: $e'));
    }
  }
} 