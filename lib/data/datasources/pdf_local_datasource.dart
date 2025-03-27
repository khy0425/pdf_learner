import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf_learner_v2/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf_learner_v2/core/utils/result.dart';

/// PDF 로컬 데이터 소스 인터페이스
/// 
/// PDF 문서와 북마크의 로컬 저장소 액세스를 담당합니다.
abstract class PDFLocalDataSource {
  /// 문서 목록 가져오기
  Future<List<PDFDocumentModel>> getDocuments();
  
  /// 특정 문서 가져오기
  Future<PDFDocumentModel?> getDocument(String id);
  
  /// 문서 저장하기
  Future<void> saveDocument(PDFDocumentModel document);
  
  /// 문서 삭제하기
  Future<void> deleteDocument(String id);
  
  /// 문서의 북마크 목록 가져오기
  Future<List<PDFBookmarkModel>> getBookmarks(String documentId);
  
  /// 특정 북마크 가져오기
  Future<PDFBookmarkModel?> getBookmark(String id);
  
  /// 북마크 저장하기
  Future<void> saveBookmark(PDFBookmarkModel bookmark);
  
  /// 북마크 삭제하기
  Future<void> deleteBookmark(String id);
  
  /// 마지막으로 읽은 페이지 저장하기
  Future<int> getLastReadPage(String documentId);
  
  /// 마지막으로 읽은 페이지 가져오기
  Future<void> saveLastReadPage(String documentId, int page);
  
  /// 즐겨찾기 문서 목록 가져오기
  Future<List<PDFDocumentModel>> getFavoriteDocuments();
  
  /// 검색 기록 저장하기
  Future<void> addSearchQuery(String query);
  
  /// 검색 기록 가져오기
  Future<List<String>> getSearchHistory();
  
  /// 검색 기록 삭제하기
  Future<void> clearSearchHistory();
  
  /// 로컬 캐시 정리
  Future<bool> clearCache();
  
  /// 파일 저장하기
  Future<bool> saveFile(String path, List<int> bytes);
  
  /// 파일 삭제하기
  Future<bool> deleteFile(String path);
  
  /// 파일 존재 확인하기
  Future<bool> fileExists(String path);
  
  /// 파일 크기 확인하기
  Future<int> getFileSize(String path);
}

/// PDF 로컬 데이터 소스 구현 클래스
/// 
/// [PDFLocalDataSource] 인터페이스의 기본 구현을 제공합니다.
@Injectable(as: PDFLocalDataSource)
class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final StorageService _storageService;
  final SharedPreferences _prefs;
  
  // 문서를 저장하는 키
  static const String _documentPrefix = 'document_';
  static const String _documentsListKey = 'documents_list';
  
  // 북마크를 저장하는 키 접두사
  static const String _bookmarkPrefix = 'bookmark_';
  static const String _bookmarksListPrefix = 'bookmarks_list_';
  
  // 마지막 읽은 페이지를 저장하는 키 접두사
  static const String _lastReadPagePrefix = 'last_read_page_';
  
  // 검색 기록을 저장하는 키
  static const String _searchHistoryKey = 'search_history';

  PDFLocalDataSourceImpl(this._storageService, this._prefs);

  @override
  Future<List<PDFDocumentModel>> getDocuments() async {
    try {
      final documentIds = _prefs.getStringList(_documentsListKey) ?? [];
      final documents = <PDFDocumentModel>[];
      
      for (final id in documentIds) {
        final documentJson = _prefs.getString('$_documentPrefix$id');
        if (documentJson != null) {
          try {
            final document = PDFDocumentModel.fromJson(json.decode(documentJson));
            documents.add(document);
          } catch (e) {
            debugPrint('문서 파싱 오류: $e');
          }
        }
      }
      
      return documents;
    } catch (e) {
      debugPrint('문서 목록 조회 오류: $e');
      return [];
    }
  }

  @override
  Future<void> saveDocument(PDFDocumentModel document) async {
    try {
      // 문서 저장
      await _prefs.setString(
        '$_documentPrefix${document.id}',
        json.encode(document.toJson())
      );
      
      // 문서 목록에 ID 추가
      final documentIds = _prefs.getStringList(_documentsListKey) ?? [];
      if (!documentIds.contains(document.id)) {
        documentIds.add(document.id);
        await _prefs.setStringList(_documentsListKey, documentIds);
      }
    } catch (e) {
      debugPrint('문서 저장 오류: $e');
      throw Exception('문서 저장 실패: $e');
    }
  }

  @override
  Future<PDFDocumentModel?> getDocument(String id) async {
    try {
      final documentJson = _prefs.getString('$_documentPrefix$id');
      if (documentJson != null) {
        return PDFDocumentModel.fromJson(json.decode(documentJson));
      }
      return null;
    } catch (e) {
      debugPrint('문서 조회 오류: $e');
      return null;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      // 문서 삭제
      await _prefs.remove('$_documentPrefix$id');
      
      // 문서 목록에서 ID 제거
      final documentIds = _prefs.getStringList(_documentsListKey) ?? [];
      if (documentIds.contains(id)) {
        documentIds.remove(id);
        await _prefs.setStringList(_documentsListKey, documentIds);
      }
      
      // 관련 북마크 삭제
      final bookmarkIds = _prefs.getStringList('$_bookmarksListPrefix$id') ?? [];
      for (final bookmarkId in bookmarkIds) {
        await _prefs.remove('$_bookmarkPrefix$bookmarkId');
      }
      await _prefs.remove('$_bookmarksListPrefix$id');
      
      // 마지막 읽은 페이지 정보 삭제
      await _prefs.remove('$_lastReadPagePrefix$id');
    } catch (e) {
      debugPrint('문서 삭제 오류: $e');
      throw Exception('문서 삭제 실패: $e');
    }
  }

  @override
  Future<List<PDFBookmarkModel>> getBookmarks(String documentId) async {
    try {
      final bookmarkIds = _prefs.getStringList('$_bookmarksListPrefix$documentId') ?? [];
      final bookmarks = <PDFBookmarkModel>[];
      
      for (final id in bookmarkIds) {
        final bookmarkJson = _prefs.getString('$_bookmarkPrefix$id');
        if (bookmarkJson != null) {
          try {
            final bookmark = PDFBookmarkModel.fromJson(json.decode(bookmarkJson));
            bookmarks.add(bookmark);
          } catch (e) {
            debugPrint('북마크 파싱 오류: $e');
          }
        }
      }
      
      return bookmarks;
    } catch (e) {
      debugPrint('북마크 목록 조회 오류: $e');
      return [];
    }
  }

  @override
  Future<void> saveBookmark(PDFBookmarkModel bookmark) async {
    try {
      // 북마크 저장
      await _prefs.setString(
        '$_bookmarkPrefix${bookmark.id}',
        json.encode(bookmark.toJson())
      );
      
      // 문서의 북마크 목록에 ID 추가
      final bookmarkIds = _prefs.getStringList('$_bookmarksListPrefix${bookmark.documentId}') ?? [];
      if (!bookmarkIds.contains(bookmark.id)) {
        bookmarkIds.add(bookmark.id);
        await _prefs.setStringList('$_bookmarksListPrefix${bookmark.documentId}', bookmarkIds);
      }
    } catch (e) {
      debugPrint('북마크 저장 오류: $e');
      throw Exception('북마크 저장 실패: $e');
    }
  }

  @override
  Future<void> deleteBookmark(String id) async {
    try {
      // 북마크 정보 가져오기
      final bookmarkJson = _prefs.getString('$_bookmarkPrefix$id');
      if (bookmarkJson != null) {
        final bookmark = PDFBookmarkModel.fromJson(json.decode(bookmarkJson));
        
        // 북마크 삭제
        await _prefs.remove('$_bookmarkPrefix$id');
        
        // 문서의 북마크 목록에서 ID 제거
        final bookmarkIds = _prefs.getStringList('$_bookmarksListPrefix${bookmark.documentId}') ?? [];
        if (bookmarkIds.contains(id)) {
          bookmarkIds.remove(id);
          await _prefs.setStringList('$_bookmarksListPrefix${bookmark.documentId}', bookmarkIds);
        }
      }
    } catch (e) {
      debugPrint('북마크 삭제 오류: $e');
      throw Exception('북마크 삭제 실패: $e');
    }
  }

  @override
  Future<bool> saveFile(String path, List<int> bytes) async {
    try {
      return await _storageService.saveFile(path, bytes);
    } catch (e) {
      debugPrint('파일 저장 실패: $e');
      return false;
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
  Future<bool> clearCache() async {
    try {
      return await _storageService.clearCache();
    } catch (e) {
      debugPrint('캐시 정리 실패: $e');
      return false;
    }
  }
  
  @override
  Future<List<PDFDocumentModel>> getFavoriteDocuments() async {
    try {
      // 즐겨찾기 문서 가져오기 구현
      return [];
    } catch (e) {
      debugPrint('즐겨찾기 문서 가져오기 실패: $e');
      return [];
    }
  }
  
  @override
  Future<int> getLastReadPage(String documentId) async {
    try {
      return _prefs.getInt('$_lastReadPagePrefix$documentId') ?? 0;
    } catch (e) {
      debugPrint('마지막 읽은 페이지 조회 오류: $e');
      return 0;
    }
  }
  
  @override
  Future<void> saveLastReadPage(String documentId, int page) async {
    try {
      await _prefs.setInt('$_lastReadPagePrefix$documentId', page);
    } catch (e) {
      debugPrint('마지막 읽은 페이지 저장 오류: $e');
      throw Exception('마지막 읽은 페이지 저장 실패: $e');
    }
  }
  
  @override
  Future<void> addSearchQuery(String query) async {
    try {
      final queries = _prefs.getStringList(_searchHistoryKey) ?? [];
      
      // 중복 제거
      if (queries.contains(query)) {
        queries.remove(query);
      }
      
      // 최근 검색어를 앞에 추가
      queries.insert(0, query);
      
      // 검색 기록 최대 개수 제한 (최근 10개)
      if (queries.length > 10) {
        queries.removeLast();
      }
      
      await _prefs.setStringList(_searchHistoryKey, queries);
    } catch (e) {
      debugPrint('검색어 추가 오류: $e');
      throw Exception('검색어 추가 실패: $e');
    }
  }
  
  @override
  Future<List<String>> getSearchHistory() async {
    try {
      return _prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      debugPrint('검색 기록 조회 오류: $e');
      return [];
    }
  }
  
  @override
  Future<void> clearSearchHistory() async {
    try {
      await _prefs.remove(_searchHistoryKey);
    } catch (e) {
      debugPrint('검색 기록 삭제 오류: $e');
      throw Exception('검색 기록 삭제 실패: $e');
    }
  }
  
  @override
  Future<PDFBookmarkModel?> getBookmark(String id) async {
    try {
      final bookmarkJson = _prefs.getString('$_bookmarkPrefix$id');
      if (bookmarkJson != null) {
        return PDFBookmarkModel.fromJson(json.decode(bookmarkJson));
      }
      return null;
    } catch (e) {
      debugPrint('북마크 조회 오류: $e');
      return null;
    }
  }
} 