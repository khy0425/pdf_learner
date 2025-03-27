import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'pdf_local_datasource.dart';
import 'package:pdf_learner_v2/services/storage/storage_service.dart';

/// PDF 로컬 데이터 소스 구현 클래스
class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final SharedPreferences _preferences;
  final StorageService _storageService;
  
  // SharedPreferences 키
  static const String _documentsKey = 'pdf_documents';
  static const String _bookmarksKey = 'pdf_bookmarks';
  static const String _favoritesKey = 'pdf_favorites';
  static const String _lastReadPageKey = 'pdf_last_read_';
  static const String _searchHistoryKey = 'pdf_search_history';
  
  PDFLocalDataSourceImpl(this._preferences, this._storageService);
  
  @override
  Future<List<PDFDocument>> getDocuments() async {
    final documents = _preferences.getStringList(_documentsKey) ?? [];
    return documents
        .map((json) => PDFDocumentModel.fromJson(jsonDecode(json)).toDomain())
        .toList();
  }
  
  @override
  Future<PDFDocument?> getDocument(String documentId) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == documentId);
    return index >= 0 ? documents[index] : null;
  }
  
  @override
  Future<bool> saveDocument(PDFDocument document) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == document.id);
    
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    
    final jsonList = documents
        .map((doc) => jsonEncode(PDFDocumentModel.fromDomain(doc).toJson()))
        .toList();
    
    return await _preferences.setStringList(_documentsKey, jsonList);
  }
  
  @override
  Future<bool> deleteDocument(String documentId) async {
    final documents = await getDocuments();
    final newList = documents.where((doc) => doc.id != documentId).toList();
    
    final jsonList = newList
        .map((doc) => jsonEncode(PDFDocumentModel.fromDomain(doc).toJson()))
        .toList();
    
    return await _preferences.setStringList(_documentsKey, jsonList);
  }
  
  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    final key = '${_bookmarksKey}_$documentId';
    final bookmarks = _preferences.getStringList(key) ?? [];
    
    return bookmarks
        .map((json) => PDFBookmarkModel.fromJson(jsonDecode(json)).toDomain())
        .toList();
  }
  
  @override
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId) async {
    final bookmarks = await getBookmarks(documentId);
    final index = bookmarks.indexWhere((bookmark) => bookmark.id == bookmarkId);
    return index >= 0 ? bookmarks[index] : null;
  }
  
  @override
  Future<bool> saveBookmark(PDFBookmark bookmark) async {
    final bookmarks = await getBookmarks(bookmark.documentId);
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    
    if (index >= 0) {
      bookmarks[index] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
    
    final key = '${_bookmarksKey}_${bookmark.documentId}';
    final jsonList = bookmarks
        .map((b) => jsonEncode(PDFBookmarkModel.fromDomain(b).toJson()))
        .toList();
    
    return await _preferences.setStringList(key, jsonList);
  }
  
  @override
  Future<bool> deleteBookmark(String documentId, String bookmarkId) async {
    final bookmarks = await getBookmarks(documentId);
    final newList = bookmarks.where((b) => b.id != bookmarkId).toList();
    
    final key = '${_bookmarksKey}_$documentId';
    final jsonList = newList
        .map((b) => jsonEncode(PDFBookmarkModel.fromDomain(b).toJson()))
        .toList();
    
    return await _preferences.setStringList(key, jsonList);
  }
  
  @override
  Future<List<PDFDocument>> getFavoriteDocuments() async {
    final documents = await getDocuments();
    return documents.where((doc) => doc.isFavorite).toList();
  }
  
  @override
  Future<int> getLastReadPage(String documentId) async {
    final key = '$_lastReadPageKey$documentId';
    return _preferences.getInt(key) ?? 0;
  }
  
  @override
  Future<bool> saveLastReadPage(String documentId, int pageNumber) async {
    final key = '$_lastReadPageKey$documentId';
    return await _preferences.setInt(key, pageNumber);
  }
  
  @override
  Future<List<String>> getSearchHistory() async {
    return _preferences.getStringList(_searchHistoryKey) ?? [];
  }
  
  @override
  Future<bool> saveSearchQuery(String query) async {
    final history = await getSearchHistory();
    
    // 중복 제거
    if (history.contains(query)) {
      history.remove(query);
    }
    
    // 최신 검색어를 맨 앞에 추가
    history.insert(0, query);
    
    // 최대 10개 유지
    while (history.length > 10) {
      history.removeLast();
    }
    
    return await _preferences.setStringList(_searchHistoryKey, history);
  }
  
  @override
  Future<bool> clearSearchHistory() async {
    return await _preferences.setStringList(_searchHistoryKey, []);
  }
  
  @override
  Future<bool> clearCache() async {
    try {
      return await _storageService.clearCache();
    } catch (e) {
      print('캐시 정리 실패: $e');
      return false;
    }
  }
  
  @override
  Future<bool> saveFile(String path, List<int> bytes) async {
    try {
      return await _storageService.saveFile(path, bytes);
    } catch (e) {
      print('파일 저장 실패: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteFile(String path) async {
    try {
      return await _storageService.deleteFile(path);
    } catch (e) {
      print('파일 삭제 실패: $e');
      return false;
    }
  }
  
  @override
  Future<bool> fileExists(String path) async {
    try {
      return await _storageService.fileExists(path);
    } catch (e) {
      print('파일 존재 확인 실패: $e');
      return false;
    }
  }
  
  @override
  Future<int> getFileSize(String path) async {
    try {
      return await _storageService.getFileSize(path);
    } catch (e) {
      print('파일 크기 확인 실패: $e');
      return 0;
    }
  }
} 