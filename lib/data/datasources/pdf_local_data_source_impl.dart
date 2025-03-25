import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import './pdf_local_data_source.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

@Injectable(as: PDFLocalDataSource)
class PDFLocalDataSourceImpl implements PDFLocalDataSource {
  final SharedPreferences _prefs;
  static const String _documentsKey = 'pdf_documents';
  static const String _bookmarksKey = 'pdf_bookmarks';
  final _uuid = const Uuid();

  PDFLocalDataSourceImpl(this._prefs);

  @override
  Future<List<PDFDocument>> getDocuments() async {
    final jsonList = _prefs.getStringList(_documentsKey) ?? [];
    return jsonList.map((json) => PDFDocument.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    final documents = await getDocuments();
    return documents.firstWhere((doc) => doc.id == id);
  }

  @override
  Future<PDFDocument> importPDF(File file) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final document = PDFDocument(
      id: id,
      title: file.path.split('/').last,
      filePath: file.path,
      totalPages: 0,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
    );

    await saveDocument(document);
    return document;
  }

  @override
  Future<void> saveDocument(PDFDocument document) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    await _saveDocuments(documents);
  }

  @override
  Future<PDFDocument> updateDocument(PDFDocument document) async {
    await saveDocument(document);
    return document;
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final documents = await getDocuments();
    final initialLength = documents.length;
    documents.removeWhere((doc) => doc.id == id);
    if (documents.length < initialLength) {
      await _saveDocuments(documents);
      return true;
    }
    return false;
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    final bookmarks = await getAllBookmarks();
    return bookmarks.where((bookmark) => bookmark.documentId == documentId).toList();
  }

  @override
  Future<List<PDFBookmark>> getAllBookmarks() async {
    final jsonList = _prefs.getStringList(_bookmarksKey) ?? [];
    return jsonList.map((json) => PDFBookmark.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark) async {
    final bookmarks = await getAllBookmarks();
    bookmarks.add(bookmark);
    await _saveBookmarks(bookmarks);
    return bookmark;
  }

  @override
  Future<PDFBookmark> updateBookmark(PDFBookmark bookmark) async {
    final bookmarks = await getAllBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      bookmarks[index] = bookmark;
      await _saveBookmarks(bookmarks);
    }
    return bookmark;
  }

  @override
  Future<bool> deleteBookmark(String id) async {
    final bookmarks = await getAllBookmarks();
    final initialLength = bookmarks.length;
    bookmarks.removeWhere((bookmark) => bookmark.id == id);
    if (bookmarks.length < initialLength) {
      await _saveBookmarks(bookmarks);
      return true;
    }
    return false;
  }

  @override
  Future<List<PDFDocument>> searchDocuments(String query) async {
    final documents = await getDocuments();
    final lowercaseQuery = query.toLowerCase();
    return documents
        .where((doc) => doc.title.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      final document = documents[index];
      documents[index] = document.copyWith(isFavorite: !document.isFavorite);
      await _saveDocuments(documents);
      return true;
    }
    return false;
  }

  @override
  Future<List<PDFDocument>> getFavoriteDocuments() async {
    final documents = await getDocuments();
    return documents.where((doc) => doc.isFavorite).toList();
  }

  @override
  Future<List<PDFDocument>> getRecentDocuments() async {
    final documents = await getDocuments();
    documents.sort((a, b) => b.lastAccessedAt?.compareTo(a.lastAccessedAt ?? DateTime(0)) ?? 0);
    return documents.take(10).toList();
  }

  @override
  Future<void> updateReadingProgress(String id, double progress) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      final document = documents[index];
      documents[index] = document.copyWith(
        readingProgress: progress,
        lastAccessedAt: DateTime.now(),
      );
      await _saveDocuments(documents);
    }
  }

  @override
  Future<void> updateCurrentPage(String id, int page) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      final document = documents[index];
      documents[index] = document.copyWith(
        currentPage: page,
        lastAccessedAt: DateTime.now(),
      );
      await _saveDocuments(documents);
    }
  }

  @override
  Future<void> updateReadingTime(String id, int seconds) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      final document = documents[index];
      documents[index] = document.copyWith(
        readingTime: document.readingTime + seconds,
        lastAccessedAt: DateTime.now(),
      );
      await _saveDocuments(documents);
    }
  }

  Future<void> _saveDocuments(List<PDFDocument> documents) async {
    final jsonList = documents.map((doc) => jsonEncode(doc.toJson())).toList();
    await _prefs.setStringList(_documentsKey, jsonList);
  }

  Future<void> _saveBookmarks(List<PDFBookmark> bookmarks) async {
    final jsonList = bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList();
    await _prefs.setStringList(_bookmarksKey, jsonList);
  }

  @override
  void dispose() {
    // 리소스 정리가 필요한 경우 여기에 구현
  }
} 