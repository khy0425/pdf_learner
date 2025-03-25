import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import './pdf_remote_data_source.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/file_storage_service.dart';

@Injectable(as: PDFRemoteDataSource)
class PDFRemoteDataSourceImpl implements PDFRemoteDataSource {
  final FirebaseService _firebaseService;
  final FileStorageService _fileStorageService;
  static const String _documentsCollection = 'pdf_documents';
  static const String _bookmarksCollection = 'pdf_bookmarks';

  PDFRemoteDataSourceImpl(
    this._firebaseService,
    this._fileStorageService,
  );

  @override
  Future<PDFDocument> addDocument(PDFDocument document) async {
    try {
      await _firebaseService.setPDFDocument(document);
      return document;
    } catch (e) {
      throw Exception('문서 추가 실패: $e');
    }
  }

  @override
  Future<List<PDFDocument>> getDocuments() async {
    try {
      return await _firebaseService.getPDFDocuments();
    } catch (e) {
      throw Exception('문서 목록 가져오기 실패: $e');
    }
  }

  @override
  Future<PDFDocument?> getDocument(String id) async {
    try {
      return await _firebaseService.getPDFDocument(id);
    } catch (e) {
      throw Exception('문서 가져오기 실패: $e');
    }
  }

  @override
  Future<void> saveDocument(PDFDocument document) async {
    try {
      await _firebaseService.setPDFDocument(document);
    } catch (e) {
      throw Exception('문서 저장 실패: $e');
    }
  }

  @override
  Future<PDFDocument> updateDocument(PDFDocument document) async {
    try {
      await _firebaseService.updatePDFDocument(document);
      return document;
    } catch (e) {
      throw Exception('문서 업데이트 실패: $e');
    }
  }

  @override
  Future<bool> deleteDocument(String id) async {
    try {
      await _firebaseService.deletePDFDocument(id);
      return true;
    } catch (e) {
      throw Exception('문서 삭제 실패: $e');
    }
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_bookmarksCollection)
          .where('documentId', isEqualTo: documentId)
          .get();
      return snapshot.docs
          .map((doc) => PDFBookmark.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('북마크 목록 가져오기 실패: $e');
    }
  }

  @override
  Future<List<PDFBookmark>> getAllBookmarks() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_bookmarksCollection)
          .get();
      return snapshot.docs
          .map((doc) => PDFBookmark.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('모든 북마크 가져오기 실패: $e');
    }
  }

  @override
  Future<PDFBookmark> addBookmark(PDFBookmark bookmark) async {
    try {
      final docRef = await _firebaseService.firestore
          .collection(_bookmarksCollection)
          .add(bookmark.toJson());
      return bookmark.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('북마크 추가 실패: $e');
    }
  }

  @override
  Future<PDFBookmark> updateBookmark(PDFBookmark bookmark) async {
    try {
      await _firebaseService.firestore
          .collection(_bookmarksCollection)
          .doc(bookmark.id)
          .update(bookmark.toJson());
      return bookmark;
    } catch (e) {
      throw Exception('북마크 업데이트 실패: $e');
    }
  }

  @override
  Future<PDFBookmark> deleteBookmark(String bookmarkId) async {
    try {
      await _firebaseService.firestore
          .collection(_bookmarksCollection)
          .doc(bookmarkId)
          .delete();
      return null;
    } catch (e) {
      throw Exception('북마크 삭제 실패: $e');
    }
  }

  @override
  Future<List<PDFDocument>> searchDocuments(String query) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_documentsCollection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();
      return snapshot.docs
          .map((doc) => PDFDocument.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('문서 검색 실패: $e');
    }
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    try {
      final doc = await _firebaseService.firestore
          .collection(_documentsCollection)
          .doc(id)
          .get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isFavorite = data['isFavorite'] ?? false;
      await doc.reference.update({'isFavorite': !isFavorite});
      return true;
    } catch (e) {
      throw Exception('즐겨찾기 토글 실패: $e');
    }
  }

  @override
  Future<List<PDFDocument>> getFavoriteDocuments() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_documentsCollection)
          .where('isFavorite', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => PDFDocument.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('즐겨찾기 문서 가져오기 실패: $e');
    }
  }

  @override
  Future<List<PDFDocument>> getRecentDocuments() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_documentsCollection)
          .orderBy('lastAccessedAt', descending: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => PDFDocument.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('최근 문서 가져오기 실패: $e');
    }
  }

  @override
  Future<void> updateReadingProgress(String id, double progress) async {
    try {
      await _firebaseService.firestore
          .collection(_documentsCollection)
          .doc(id)
          .update({
        'readingProgress': progress,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('읽기 진행률 업데이트 실패: $e');
    }
  }

  @override
  Future<void> updateCurrentPage(String id, int page) async {
    try {
      await _firebaseService.firestore
          .collection(_documentsCollection)
          .doc(id)
          .update({
        'currentPage': page,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('현재 페이지 업데이트 실패: $e');
    }
  }

  @override
  Future<void> updateReadingTime(String id, int seconds) async {
    try {
      await _firebaseService.firestore
          .collection(_documentsCollection)
          .doc(id)
          .update({
        'readingTime': FieldValue.increment(seconds),
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('읽기 시간 업데이트 실패: $e');
    }
  }

  @override
  Future<String> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      final ref = await _fileStorageService.uploadFile(
        file,
        'pdfs/${DateTime.now().millisecondsSinceEpoch}/${file.path.split('/').last}',
      );
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('파일 업로드 실패: $e');
    }
  }

  @override
  Future<String?> downloadFile(String remoteUrl) async {
    try {
      return await _fileStorageService.getDownloadUrl(remoteUrl);
    } catch (e) {
      throw Exception('파일 다운로드 실패: $e');
    }
  }

  @override
  Future<bool> deleteFile(String remoteUrl) async {
    try {
      await _fileStorageService.deleteFile(remoteUrl);
      return true;
    } catch (e) {
      throw Exception('파일 삭제 실패: $e');
    }
  }

  @override
  Future<void> syncWithRemote() async {
    // TODO: Implement syncWithRemote
    throw UnimplementedError();
  }

  @override
  Future<PDFDocument> importPDF(File file) async {
    try {
      final remoteUrl = await uploadFile(file.path);
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: file.path.split('/').last,
        filePath: remoteUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveDocument(document);
      return document;
    } catch (e) {
      throw Exception('PDF 가져오기 실패: $e');
    }
  }

  @override
  void dispose() {
    // 필요한 정리 작업 수행
  }
} 