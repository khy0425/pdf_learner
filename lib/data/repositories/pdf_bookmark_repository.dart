import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart' as bookmark;
import '../services/file_storage_service.dart';
import '../utils/web_utils.dart';

/// PDF 북마크 저장소
class PDFBookmarkRepository {
  final FileStorageService _storageService;
  
  PDFBookmarkRepository({
    required FileStorageService storageService,
  }) : _storageService = storageService;
  
  /// 북마크 추가
  Future<bool> addBookmark(PDFDocument document, bookmark.PDFBookmark bookmark) async {
    try {
      final updatedBookmarks = [...(document.bookmarks ?? []), bookmark];
      final updatedDocument = document.copyWith(
        bookmarks: updatedBookmarks,
      );
      
      return await _saveBookmarks(updatedDocument);
    } catch (e) {
      debugPrint('북마크 추가 중 오류: $e');
      return false;
    }
  }
  
  /// 북마크 삭제
  Future<bool> deleteBookmark(PDFDocument document, String bookmarkId) async {
    try {
      final updatedBookmarks = document.bookmarks
          ?.where((b) => b.id != bookmarkId)
          .toList();
      
      final updatedDocument = document.copyWith(
        bookmarks: updatedBookmarks,
      );
      
      return await _saveBookmarks(updatedDocument);
    } catch (e) {
      debugPrint('북마크 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 북마크 업데이트
  Future<bool> updateBookmark(PDFDocument document, bookmark.PDFBookmark bookmark) async {
    try {
      final updatedBookmarks = document.bookmarks?.map((b) {
        if (b.id == bookmark.id) {
          return bookmark;
        }
        return b;
      }).toList();
      
      final updatedDocument = document.copyWith(
        bookmarks: updatedBookmarks,
      );
      
      return await _saveBookmarks(updatedDocument);
    } catch (e) {
      debugPrint('북마크 업데이트 중 오류: $e');
      return false;
    }
  }
  
  /// 북마크 목록 가져오기
  List<bookmark.PDFBookmark> getBookmarks(PDFDocument document) {
    return document.bookmarks ?? [];
  }
  
  /// 북마크 저장
  Future<bool> _saveBookmarks(PDFDocument document) async {
    try {
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지에 저장
        final bookmarksJson = document.bookmarks?.map((b) => b.toJson()).toList();
        WebUtils.saveToLocalStorage('pdf_bookmarks_${document.id}', bookmarksJson);
      } else {
        // 네이티브에서는 파일 시스템에 저장
        await _storageService.saveDocument(document);
      }
      return true;
    } catch (e) {
      debugPrint('북마크 저장 중 오류: $e');
      return false;
    }
  }
  
  /// 북마크 로드
  Future<List<bookmark.PDFBookmark>> loadBookmarks(PDFDocument document) async {
    try {
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지에서 로드
        final bookmarksJson = WebUtils.loadFromLocalStorage('pdf_bookmarks_${document.id}');
        if (bookmarksJson != null) {
          final List<dynamic> jsonList = bookmarksJson;
          return jsonList.map((json) => bookmark.PDFBookmark.fromJson(json)).toList();
        }
      } else {
        // 네이티브에서는 파일 시스템에서 로드
        final loadedDocument = await _storageService.getDocument(document.id);
        if (loadedDocument != null) {
          return loadedDocument.bookmarks ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('북마크 로드 중 오류: $e');
      return [];
    }
  }
} 