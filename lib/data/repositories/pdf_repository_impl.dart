import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../core/services/firebase_service.dart';

/// PDF 저장소 구현체
@Injectable(as: PDFRepository)
class PDFRepositoryImpl implements PDFRepository {
  final FirebaseService _firebaseService;
  final SharedPreferences _prefs;

  PDFRepositoryImpl(this._firebaseService, this._prefs);

  @override
  Future<List<PDFDocument>> getDocuments() async {
    if (_firebaseService.isAnonymous) {
      // 익명 사용자는 로컬 스토리지에서만 조회
      final documentsJson = _prefs.getStringList('documents') ?? [];
      return documentsJson
          .map((json) => PDFDocument.fromJson(json))
          .toList();
    } else {
      // 로그인 사용자는 Firebase에서 조회
      return await _firebaseService.getPDFDocuments();
    }
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    if (_firebaseService.isAnonymous) {
      final documentsJson = _prefs.getStringList('documents') ?? [];
      final documentJson = documentsJson.firstWhere(
        (json) => PDFDocument.fromJson(json).id == id,
        orElse: () => '',
      );
      return documentJson.isNotEmpty ? PDFDocument.fromJson(documentJson) : null;
    } else {
      return await _firebaseService.getPDFDocument(id);
    }
  }

  @override
  Future<void> createDocument(PDFDocument document) async {
    if (_firebaseService.isAnonymous) {
      final documentsJson = _prefs.getStringList('documents') ?? [];
      documentsJson.add(document.toJson());
      await _prefs.setStringList('documents', documentsJson);
    } else {
      await _firebaseService.addPDFDocument(document);
    }
  }

  @override
  Future<void> updateDocument(PDFDocument document) async {
    if (_firebaseService.isAnonymous) {
      final documentsJson = _prefs.getStringList('documents') ?? [];
      final index = documentsJson.indexWhere(
        (json) => PDFDocument.fromJson(json).id == document.id,
      );
      if (index != -1) {
        documentsJson[index] = document.toJson();
        await _prefs.setStringList('documents', documentsJson);
      }
    } else {
      await _firebaseService.updatePDFDocument(document);
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (_firebaseService.isAnonymous) {
      final documentsJson = _prefs.getStringList('documents') ?? [];
      documentsJson.removeWhere(
        (json) => PDFDocument.fromJson(json).id == id,
      );
      await _prefs.setStringList('documents', documentsJson);
    } else {
      await _firebaseService.deletePDFDocument(id);
    }
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    if (_firebaseService.isAnonymous) {
      final bookmarksJson = _prefs.getStringList('bookmarks_$documentId') ?? [];
      return bookmarksJson
          .map((json) => PDFBookmark.fromJson(json))
          .toList();
    } else {
      return await _firebaseService.getBookmarks(documentId);
    }
  }

  @override
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId) async {
    if (_firebaseService.isAnonymous) {
      final bookmarksJson = _prefs.getStringList('bookmarks_$documentId') ?? [];
      final bookmarkJson = bookmarksJson.firstWhere(
        (json) => PDFBookmark.fromJson(json).id == bookmarkId,
        orElse: () => '',
      );
      return bookmarkJson.isNotEmpty ? PDFBookmark.fromJson(bookmarkJson) : null;
    } else {
      return await _firebaseService.getBookmark(documentId, bookmarkId);
    }
  }

  @override
  Future<void> createBookmark(PDFBookmark bookmark) async {
    if (_firebaseService.isAnonymous) {
      final documentId = bookmark.documentId;
      final bookmarksJson = _prefs.getStringList('bookmarks_$documentId') ?? [];
      bookmarksJson.add(bookmark.toJson());
      await _prefs.setStringList('bookmarks_$documentId', bookmarksJson);
    } else {
      await _firebaseService.addBookmark(bookmark);
    }
  }

  @override
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    if (_firebaseService.isAnonymous) {
      final documentId = bookmark.documentId;
      final bookmarksJson = _prefs.getStringList('bookmarks_$documentId') ?? [];
      final index = bookmarksJson.indexWhere(
        (json) => PDFBookmark.fromJson(json).id == bookmark.id,
      );
      if (index != -1) {
        bookmarksJson[index] = bookmark.toJson();
        await _prefs.setStringList('bookmarks_$documentId', bookmarksJson);
      }
    } else {
      await _firebaseService.updateBookmark(bookmark);
    }
  }

  @override
  Future<void> deleteBookmark(String documentId, String bookmarkId) async {
    if (_firebaseService.isAnonymous) {
      final bookmarksJson = _prefs.getStringList('bookmarks_$documentId') ?? [];
      bookmarksJson.removeWhere(
        (json) => PDFBookmark.fromJson(json).id == bookmarkId,
      );
      await _prefs.setStringList('bookmarks_$documentId', bookmarksJson);
    } else {
      await _firebaseService.deleteBookmark(documentId, bookmarkId);
    }
  }

  @override
  Future<String> uploadPDFFile(Uint8List file) async {
    if (_firebaseService.isAnonymous) {
      // 익명 사용자는 로컬에 저장
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString('pdf_file_$fileId', file.toString());
      return fileId;
    } else {
      // 로그인 사용자는 Firebase Storage에 업로드
      return await _firebaseService.uploadPDFFile(file);
    }
  }

  @override
  Future<void> deletePDFFile(String filePath) async {
    if (_firebaseService.isAnonymous) {
      // 익명 사용자는 로컬 스토리지에서 삭제
      await _prefs.remove(filePath);
    } else {
      // 로그인 사용자는 Firebase Storage에서 삭제
      await _firebaseService.deletePDFFile(filePath);
    }
  }

  @override
  Future<int> getPageCount(String filePath) async {
    // TODO: 실제 PDF 파일의 페이지 수를 구하는 로직 구현
    // 웹에서는 다른 방식으로 처리해야 할 수 있음
    return 1;
  }

  @override
  Future<String> extractText(String filePath, int pageNumber) async {
    // TODO: 실제 PDF 파일에서 텍스트 추출 로직 구현
    // 웹에서는 다른 방식으로 처리해야 할 수 있음
    return '';
  }
  
  @override
  Future<Map<String, dynamic>> getMetadata(String filePath) async {
    // TODO: 실제 PDF 메타데이터 추출 로직 구현
    return {};
  }

  @override
  void dispose() {
    // 필요한 리소스 정리
  }
} 