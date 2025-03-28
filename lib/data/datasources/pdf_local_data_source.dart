import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/base/result.dart';
import '../../services/storage/storage_service.dart';
import 'package:path/path.dart' as path;

/// PDF 문서 로컬 데이터 소스 인터페이스
abstract class PDFLocalDataSource {
  /// 모든 PDF 문서를 가져옵니다.
  Future<Result<List<PDFDocument>>> getDocuments();
  
  /// ID로 특정 PDF 문서를 가져옵니다.
  Future<Result<PDFDocument?>> getDocument(String id);
  
  /// PDF 문서를 저장합니다.
  Future<Result<void>> saveDocument(PDFDocument document);
  
  /// PDF 문서를 삭제합니다.
  Future<Result<void>> deleteDocument(String id);
  
  /// PDF 문서에 대한 모든 북마크를 가져옵니다.
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId);
  
  /// 모든 북마크를 가져옵니다.
  Future<Result<List<PDFBookmark>>> getAllBookmarks();
  
  /// ID로 특정 북마크를 가져옵니다.
  Future<Result<PDFBookmark?>> getBookmark(String id);
  
  /// 북마크를 저장합니다.
  Future<Result<void>> saveBookmark(PDFBookmark bookmark);
  
  /// 북마크를 삭제합니다.
  Future<Result<void>> deleteBookmark(String id);
  
  /// 검색어를 저장합니다.
  Future<Result<void>> addSearchQuery(String query);
  
  /// 검색 기록을 가져옵니다.
  Future<Result<List<String>>> getSearchHistory();
  
  /// 검색 기록을 삭제합니다.
  Future<Result<void>> clearSearchHistory();
  
  /// 캐시를 정리합니다.
  Future<Result<void>> clearCache();
  
  /// 파일을 저장합니다.
  Future<Result<String>> saveFile(String path, Uint8List bytes);
  
  /// 파일을 삭제합니다.
  Future<Result<bool>> deleteFile(String path);
  
  /// 파일 존재 여부를 확인합니다.
  Future<Result<bool>> fileExists(String path);
  
  /// 파일 크기를 가져옵니다.
  Future<Result<int>> getFileSize(String path);
  
  /// 즐겨찾기한 문서를 가져옵니다.
  Future<Result<List<PDFDocument>>> getFavoriteDocuments();
  
  /// 마지막으로 읽은 페이지를 가져옵니다.
  Future<Result<int>> getLastReadPage(String documentId);
  
  /// 마지막으로 읽은 페이지를 저장합니다.
  Future<Result<void>> saveLastReadPage(String documentId, int page);
  
  /// PDF 파일을 가져옵니다.
  Future<Result<PDFDocument>> importPDF(File file);
}

@Injectable(as: PDFLocalDataSource)
class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final StorageService _storageService;
  
  static const String _documentsKey = 'pdf_documents';
  static const String _bookmarksKey = 'pdf_bookmarks';
  static const String _searchHistoryKey = 'search_history';
  static const String _lastReadPagePrefix = 'last_read_page_';
  
  PDFLocalDataSourceImpl(this._storageService);
  
  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final String? jsonString = _storageService.getString(_documentsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return Result.success([]);
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<PDFDocument> documents = jsonList
          .map((jsonMap) => PDFDocument.fromMap(jsonMap))
          .toList();
      
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('문서 목록 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> saveDocument(PDFDocument document) async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return Result.failure(documentsResult.error!);
      }
      
      final documents = documentsResult.data!;
      final index = documents.indexWhere((doc) => doc.id == document.id);
      
      if (index != -1) {
        // 기존 문서 업데이트
        documents[index] = document;
      } else {
        // 새 문서 추가
        documents.add(document);
      }
      
      await _saveDocuments(documents);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('문서 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<PDFDocument?>> getDocument(String id) async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return Result.failure(documentsResult.error!);
      }
      
      final documents = documentsResult.data!;
      final document = documents.firstWhere(
        (doc) => doc.id == id, 
        orElse: () => PDFDocument(id: '', title: '', filePath: '')
      );
      
      // ID가 빈 문자열인 경우 문서를 찾지 못한 것으로 간주
      if (document.id.isEmpty) {
        return Result.success(null);
      }
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('문서 검색 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> deleteDocument(String id) async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return Result.failure(documentsResult.error!);
      }
      
      final documents = documentsResult.data!;
      final originalCount = documents.length;
      documents.removeWhere((doc) => doc.id == id);
      
      // 문서가 제거되지 않은 경우
      if (originalCount == documents.length) {
        return Result.success(null); // 이미 없는 문서라면 성공으로 간주
      }
      
      // 관련 북마크도 삭제
      final bookmarksResult = await getAllBookmarks();
      if (bookmarksResult.isSuccess) {
        final bookmarks = bookmarksResult.data!;
        bookmarks.removeWhere((bookmark) => bookmark.documentId == id);
        await _saveBookmarks(bookmarks);
      }
      
      // 마지막 읽은 페이지 데이터 삭제
      await _storageService.remove('$_lastReadPagePrefix$id');
      
      // 문서 목록 저장
      await _saveDocuments(documents);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('문서 삭제 실패: $e'));
    }
  }
  
  Future<void> _saveDocuments(List<PDFDocument> documents) async {
    final jsonList = documents.map((doc) => doc.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await _storageService.setString(_documentsKey, jsonString);
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      final bookmarksResult = await getAllBookmarks();
      if (bookmarksResult.isFailure) {
        return Result.failure(bookmarksResult.error!);
      }
      
      final allBookmarks = bookmarksResult.data!;
      final documentBookmarks = allBookmarks
          .where((bookmark) => bookmark.documentId == documentId)
          .toList();
      
      return Result.success(documentBookmarks);
    } catch (e) {
      return Result.failure(Exception('북마크 목록 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<PDFBookmark?>> getBookmark(String id) async {
    try {
      final bookmarksResult = await getAllBookmarks();
      if (bookmarksResult.isFailure) {
        return Result.failure(bookmarksResult.error!);
      }
      
      final bookmarks = bookmarksResult.data!;
      final bookmark = bookmarks.firstWhere(
        (b) => b.id == id,
        orElse: () => PDFBookmark(
          id: '',
          documentId: '',
          title: '',
          page: 0
        )
      );
      
      if (bookmark.id.isEmpty) {
        return Result.success(null);
      }
      
      return Result.success(bookmark);
    } catch (e) {
      return Result.failure(Exception('북마크 검색 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final bookmarksResult = await getAllBookmarks();
      if (bookmarksResult.isFailure) {
        return Result.failure(bookmarksResult.error!);
      }
      
      final bookmarks = bookmarksResult.data!;
      final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
      
      if (index != -1) {
        // 기존 북마크 업데이트
        bookmarks[index] = bookmark;
      } else {
        // 새 북마크 추가
        bookmarks.add(bookmark);
      }
      
      await _saveBookmarks(bookmarks);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('북마크 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> deleteBookmark(String id) async {
    try {
      final bookmarksResult = await getAllBookmarks();
      if (bookmarksResult.isFailure) {
        return Result.failure(bookmarksResult.error!);
      }
      
      final bookmarks = bookmarksResult.data!;
      bookmarks.removeWhere((b) => b.id == id);
      
      await _saveBookmarks(bookmarks);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제 실패: $e'));
    }
  }
  
  @override
  Future<Result<List<PDFBookmark>>> getAllBookmarks() async {
    try {
      final String? jsonString = _storageService.getString(_bookmarksKey);
      if (jsonString == null || jsonString.isEmpty) {
        return Result.success([]);
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<PDFBookmark> bookmarks = jsonList
          .map((jsonMap) => PDFBookmark.fromMap(jsonMap))
          .toList();
      
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('모든 북마크 가져오기 실패: $e'));
    }
  }
  
  Future<void> _saveBookmarks(List<PDFBookmark> bookmarks) async {
    final jsonList = bookmarks.map((bookmark) => bookmark.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await _storageService.setString(_bookmarksKey, jsonString);
  }
  
  @override
  Future<Result<void>> saveLastReadPage(String documentId, int page) async {
    try {
      await _storageService.setInt('$_lastReadPagePrefix$documentId', page);
      
      // 문서 자체의 lastReadPage도 업데이트
      final documentResult = await getDocument(documentId);
      if (documentResult.isSuccess && documentResult.data != null) {
        final document = documentResult.data!;
        final updatedDocument = document.copyWith(
          lastReadPage: page,
          updatedAt: DateTime.now(),
        );
        await saveDocument(updatedDocument);
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<int>> getLastReadPage(String documentId) async {
    try {
      final page = _storageService.getInt('$_lastReadPagePrefix$documentId') ?? 0;
      return Result.success(page);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return Result.failure(documentsResult.error!);
      }
      
      final documents = documentsResult.data!;
      final favoriteDocuments = documents
          .where((doc) => doc.isFavorite)
          .toList();
      
      return Result.success(favoriteDocuments);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 문서 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> addSearchQuery(String query) async {
    try {
      if (query.trim().isEmpty) {
        return Result.success(null); // 빈 검색어는 저장하지 않음
      }
      
      final historyResult = await getSearchHistory();
      if (historyResult.isFailure) {
        return Result.failure(historyResult.error!);
      }
      
      final history = historyResult.data!;
      
      // 이미 존재하는 쿼리면 삭제
      history.remove(query);
      
      // 최신 쿼리를 목록 앞에 추가
      history.insert(0, query);
      
      // 최대 20개까지만 유지
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }
      
      await _storageService.setStringList(_searchHistoryKey, history);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('검색어 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<List<String>>> getSearchHistory() async {
    try {
      final history = _storageService.getStringList(_searchHistoryKey) ?? [];
      return Result.success(history);
    } catch (e) {
      return Result.failure(Exception('검색 기록 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> clearSearchHistory() async {
    try {
      await _storageService.remove(_searchHistoryKey);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('검색 기록 삭제 실패: $e'));
    }
  }
  
  @override
  Future<Result<void>> clearCache() async {
    try {
      await _storageService.clearCache();
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('캐시 정리 실패: $e'));
    }
  }
  
  @override
  Future<Result<String>> saveFile(String filePath, Uint8List bytes) async {
    try {
      final savedPath = await _storageService.saveFile(bytes, path.basename(filePath));
      return Result.success(savedPath);
    } catch (e) {
      return Result.failure(Exception('파일 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<bool>> deleteFile(String filePath) async {
    try {
      await _storageService.deleteFile(filePath);
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('파일 삭제 실패: $e'));
    }
  }
  
  @override
  Future<Result<bool>> fileExists(String filePath) async {
    try {
      final exists = await _storageService.fileExists(filePath);
      return Result.success(exists);
    } catch (e) {
      return Result.failure(Exception('파일 존재 여부 확인 실패: $e'));
    }
  }
  
  @override
  Future<Result<int>> getFileSize(String filePath) async {
    try {
      final size = await _storageService.getFileSize(filePath);
      return Result.success(size);
    } catch (e) {
      return Result.failure(Exception('파일 크기 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<PDFDocument>> importPDF(File file) async {
    try {
      // 중복 파일 확인 (파일명 기준)
      final fileName = path.basename(file.path);
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return Result.failure(documentsResult.error!);
      }
      
      final documents = documentsResult.data!;
      for (final doc in documents) {
        final docFileName = path.basename(doc.filePath);
        if (docFileName == fileName) {
          return Result.success(doc); // 이미 존재하는 문서 반환
        }
      }
      
      // 새 문서 생성
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName.replaceAll('.pdf', ''),
        filePath: file.path,
        fileSize: await file.length(),
        pageCount: await _storageService.getPDFPageCount(file.path),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 문서 저장
      final saveResult = await saveDocument(document);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.error!);
      }
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 가져오기 실패: $e'));
    }
  }
} 