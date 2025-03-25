import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

abstract class PDFRemoteDataSource {
  // Document operations
  Future<PDFDocument> addDocument(PDFDocument document);
  Future<List<PDFDocument>> getDocuments();
  Future<PDFDocument?> getDocument(String id);
  Future<PDFDocument> importPDF(File file);
  Future<void> saveDocument(PDFDocument document);
  Future<PDFDocument> updateDocument(PDFDocument document);
  Future<bool> deleteDocument(String id);
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  Future<List<PDFBookmark>> getAllBookmarks();
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark);
  Future<PDFBookmark> updateBookmark(PDFBookmark bookmark);
  Future<bool> deleteBookmark(String bookmarkId);
  Future<List<PDFDocument>> searchDocuments(String query);
  Future<bool> toggleFavorite(String id);
  Future<List<PDFDocument>> getFavoriteDocuments();
  Future<List<PDFDocument>> getRecentDocuments();
  Future<void> updateReadingProgress(String id, double progress);
  Future<void> updateCurrentPage(String id, int page);
  Future<void> updateReadingTime(String id, int seconds);
  Future<String> uploadFile(String filePath);
  Future<String?> downloadFile(String remoteUrl);
  Future<bool> deleteFile(String remoteUrl);
  Future<void> syncWithRemote();
  void dispose();
} 