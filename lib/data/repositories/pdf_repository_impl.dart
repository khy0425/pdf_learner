import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/pdf_local_datasource.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';

class PDFRepositoryImpl implements PDFRepository {
  final PDFLocalDataSource _localDataSource;
  final _uuid = const Uuid();
  final PDFRepository _repository;

  PDFRepositoryImpl(this._localDataSource, this._repository);

  @override
  Future<List<PDFDocument>> getAllDocuments() async {
    final documents = await _localDataSource.getAllDocuments();
    return documents.map((doc) => doc.toEntity()).toList();
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    final documents = await _localDataSource.getAllDocuments();
    final document = documents.firstWhere((doc) => doc.id == id);
    return document.toEntity();
  }

  @override
  Future<PDFDocument> saveDocument(PDFDocument document) async {
    final documents = await _localDataSource.getAllDocuments();
    final model = PDFDocumentModel.fromEntity(document);
    documents.add(model);
    await _localDataSource.saveDocuments(documents);
    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _localDataSource.deleteDocument(id);
  }

  @override
  Future<PDFDocument> importPDF(File file) async {
    final documents = await _localDataSource.getAllDocuments();
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final document = PDFDocument(
      id: id,
      title: file.path.split('/').last,
      filePath: file.path,
      thumbnailPath: '', // TODO: Implement thumbnail generation
      totalPages: 0, // TODO: Implement PDF page counting
      currentPage: 0,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      bookmarks: [],
    );

    final model = PDFDocumentModel.fromEntity(document);
    documents.add(model);
    await _localDataSource.saveDocuments(documents);
    return document;
  }

  @override
  Future<void> updateDocument(PDFDocument document) async {
    final documents = await _localDataSource.getAllDocuments();
    final index = documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      documents[index] = PDFDocumentModel.fromEntity(document);
      await _localDataSource.saveDocuments(documents);
    }
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    final bookmarks = await _localDataSource.getAllBookmarks();
    return bookmarks
        .where((bookmark) => bookmark.documentId == documentId)
        .map((bookmark) => bookmark.toEntity())
        .toList();
  }

  @override
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark) async {
    final bookmarks = await _localDataSource.getAllBookmarks();
    final model = PDFBookmarkModel.fromEntity(bookmark);
    bookmarks.add(model);
    await _localDataSource.saveBookmarks(bookmarks);
    return bookmark;
  }

  @override
  Future<void> deleteBookmark(String bookmarkId) async {
    await _localDataSource.deleteBookmark(bookmarkId);
  }

  @override
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    final bookmarks = await _localDataSource.getAllBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      bookmarks[index] = PDFBookmarkModel.fromEntity(bookmark);
      await _localDataSource.saveBookmarks(bookmarks);
    }
  }

  @override
  Future<List<PDFDocument>> getDocuments() {
    return _repository.getDocuments();
  }

  @override
  Future<PDFDocument> addDocument(PDFDocument document) {
    return _repository.addDocument(document);
  }

  @override
  Future<bool> deleteDocument(String id) {
    return _repository.deleteDocument(id);
  }
} 