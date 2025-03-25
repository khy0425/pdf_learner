import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

abstract class PDFRemoteDataSource {
  Future<void> uploadPDF(PDFDocument document, String filePath);
  Future<List<PDFDocument>> getPDFDocuments();
  Future<PDFDocument?> getPDFDocument(String documentId);
  Future<void> deletePDFDocument(String documentId);
  Future<void> updatePDFDocument(PDFDocument document);
  Future<void> saveBookmark(PDFBookmark bookmark);
  Future<List<PDFBookmark>> getBookmarks(String documentId);
  Future<void> deleteBookmark(String bookmarkId);
} 