import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';

@injectable
class PDFViewModel extends ChangeNotifier {
  final PDFRepository _pdfRepository;
  List<PDFDocument> _documents = [];
  List<PDFBookmark> _bookmarks = [];
  PDFDocument? _currentDocument;
  bool _isLoading = false;
  String? _error;

  PDFViewModel(this._pdfRepository);

  List<PDFDocument> get documents => _documents;
  List<PDFBookmark> get bookmarks => _bookmarks;
  PDFDocument? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _documents = await _pdfRepository.getDocuments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDocument(String documentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentDocument = await _pdfRepository.getPDFDocument(documentId);
      if (_currentDocument != null) {
        _bookmarks = await _pdfRepository.getBookmarks(documentId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createDocument(PDFDocument document) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.createPDFDocument(document);
      _documents.add(document);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDocument(PDFDocument document) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.updatePDFDocument(document);
      final index = _documents.indexWhere((d) => d.id == document.id);
      if (index != -1) {
        _documents[index] = document;
      }
      if (_currentDocument?.id == document.id) {
        _currentDocument = document;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.deletePDFDocument(documentId);
      _documents.removeWhere((d) => d.id == documentId);
      if (_currentDocument?.id == documentId) {
        _currentDocument = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBookmark(PDFBookmark bookmark) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.createBookmark(bookmark);
      _bookmarks.add(bookmark);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBookmark(PDFBookmark bookmark) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.updateBookmark(bookmark);
      final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
      if (index != -1) {
        _bookmarks[index] = bookmark;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.deleteBookmark(bookmarkId);
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadPDFFile(String filePath, String fileName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      return await _pdfRepository.uploadPDFFile(filePath, fileName);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePDFFile(String fileUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _pdfRepository.deletePDFFile(fileUrl);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 