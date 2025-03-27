import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

abstract class PDFLocalDataSource {
  // Document operations
  Future<List<PDFDocument>> getDocuments();
  Future<PDFDocument?> getDocument(String id);
  Future<PDFDocument> importPDF(File file);
  Future<void> saveDocument(PDFDocument document);
  Future<PDFDocument> updateDocument(PDFDocument document);
  Future<bool> deleteDocument(String id);

  // Bookmark operations
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  Future<List<PDFBookmark>> getAllBookmarks();
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark);
  Future<PDFBookmark> updateBookmark(PDFBookmark bookmark);
  Future<bool> deleteBookmark(String bookmarkId);

  // Search and filter operations
  Future<List<PDFDocument>> searchDocuments(String query);
  Future<bool> toggleFavorite(String id);
  Future<List<PDFDocument>> getFavoriteDocuments();
  Future<List<PDFDocument>> getRecentDocuments();

  // Reading progress operations
  Future<void> updateReadingProgress(String id, double progress);
  Future<void> updateCurrentPage(String id, int page);
  Future<void> updateReadingTime(String id, int seconds);

  Future<PDFDocument> addDocument(PDFDocument document);
  Future<String> saveFile(String localPath);
  Future<String?> getFile(String localPath);
  Future<bool> deleteFile(String localPath);
  Future<void> clearCache();

  void dispose();
}

class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final SharedPreferences _prefs;
  static const String _documentsKey = 'pdf_documents';

  PDFLocalDataSourceImpl(this._prefs);

  @override
  Future<List<PDFDocument>> getDocuments() async {
    try {
      final String? jsonString = _prefs.getString(_documentsKey);
      if (jsonString == null) return [];
      return PDFDocument.fromJsonList(jsonString);
    } catch (e) {
      throw Exception('문서 목록 가져오기 실패: $e');
    }
  }

  @override
  Future<void> saveDocument(PDFDocument document) async {
    try {
      final documents = await getAllDocuments();
      documents.add(document);
      await _saveDocuments(documents);
    } catch (e) {
      throw Exception('문서 저장 실패: $e');
    }
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    try {
      final documents = await getAllDocuments();
      return documents.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PDFDocument>> getAllDocuments() async {
    try {
      final String? jsonString = _prefs.getString(_documentsKey);
      if (jsonString == null) return [];
      return PDFDocument.listFromJson(jsonString);
    } catch (e) {
      throw Exception('문서 목록 가져오기 실패: $e');
    }
  }

  @override
  Future<bool> deleteDocument(String id) async {
    try {
      final documents = await getAllDocuments();
      documents.removeWhere((doc) => doc.id == id);
      await _saveDocuments(documents);
      return true;
    } catch (e) {
      throw Exception('문서 삭제 실패: $e');
    }
  }

  @override
  Future<PDFDocument> updateDocument(PDFDocument document) async {
    try {
      final documents = await getAllDocuments();
      final index = documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        documents[index] = document;
        await _saveDocuments(documents);
      }
      return document;
    } catch (e) {
      throw Exception('문서 업데이트 실패: $e');
    }
  }

  @override
  Future<PDFDocument> importPDF(File file) async {
    try {
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: file.path.split('/').last.replaceAll('.pdf', ''),
        description: '',
        filePath: file.path,
        downloadUrl: '',
        pageCount: 1, // 실제 구현에서는 페이지 수를 계산해야 함
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentPage: 0,
        readingProgress: 0.0,
        isFavorite: false,
        isSelected: false,
        readingTime: 0,
        status: PDFDocumentStatus.created,
        importance: PDFDocumentImportance.medium,
        securityLevel: PDFDocumentSecurityLevel.none,
        tags: [],
        bookmarks: [],
        metadata: {},
        fileSize: file.lengthSync(),
      );
      await saveDocument(document);
      return document;
    } catch (e) {
      throw Exception('PDF 가져오기 실패: $e');
    }
  }

  Future<void> _saveDocuments(List<PDFDocument> documents) async {
    try {
      final jsonString = PDFDocument.listToJson(documents);
      await _prefs.setString(_documentsKey, jsonString);
    } catch (e) {
      throw Exception('문서 목록 저장 실패: $e');
    }
  }

  // Bookmark operations
  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<List<PDFBookmark>> getAllBookmarks() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<PDFBookmark> updateBookmark(PDFBookmark bookmark) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteBookmark(String bookmarkId) {
    // Implementation needed
    throw UnimplementedError();
  }

  // Search and filter operations
  @override
  Future<List<PDFDocument>> searchDocuments(String query) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<bool> toggleFavorite(String id) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<List<PDFDocument>> getFavoriteDocuments() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<List<PDFDocument>> getRecentDocuments() {
    // Implementation needed
    throw UnimplementedError();
  }

  // Reading progress operations
  @override
  Future<void> updateReadingProgress(String id, double progress) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<void> updateCurrentPage(String id, int page) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<void> updateReadingTime(String id, int seconds) {
    // Implementation needed
    throw UnimplementedError();
  }

  Future<PDFDocument> addDocument(PDFDocument document) {
    // Implementation needed
    throw UnimplementedError();
  }

  Future<String> saveFile(String localPath) {
    // Implementation needed
    throw UnimplementedError();
  }

  Future<String?> getFile(String localPath) {
    // Implementation needed
    throw UnimplementedError();
  }

  Future<bool> deleteFile(String localPath) {
    // Implementation needed
    throw UnimplementedError();
  }

  Future<void> clearCache() {
    // Implementation needed
    throw UnimplementedError();
  }

  void dispose() {
    // Implementation needed
  }
} 