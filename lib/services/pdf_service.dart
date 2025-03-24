import 'dart:io';
import 'package:pdf_learner/models/pdf_document.dart';

abstract class PDFService {
  Future<PDFDocument?> openPDF(File file);
  Future<void> closePDF(String id);
  Future<int> getPageCount(String id);
  Future<void> goToPage(String id, int page);
  Future<File?> renderPage(String id, int page);
  Future<String?> extractText(String id, int page);
  Future<Map<String, dynamic>?> getMetadata(String id);
  Future<List<String>> searchText(String id, String query);
  Future<void> addBookmark(String id, int page);
  Future<void> removeBookmark(String id, int page);
  Future<void> toggleFavorite(String id);
  Future<List<PDFDocument>> getRecentDocuments();
  Future<List<PDFDocument>> getFavoriteDocuments();
} 