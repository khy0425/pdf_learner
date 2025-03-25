import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';

/// PDF 저장소 구현체
@Injectable()
class PDFRepositoryImpl implements PDFRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  PDFRepositoryImpl(this._firebaseService, this._storageService);

  @override
  Future<List<PDFDocument>> getDocuments() async {
    // Stream을 Future로 변환
    return await _firebaseService.getDocuments().first;
  }

  @override
  Future<PDFDocument?> getDocument(String documentId) async {
    return await _firebaseService.getDocument(documentId);
  }

  @override
  Future<void> createDocument(PDFDocument document) async {
    await _firebaseService.createDocument(document);
  }

  @override
  Future<void> updateDocument(PDFDocument document) async {
    await _firebaseService.updateDocument(document);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _firebaseService.deleteDocument(documentId);
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    // Stream을 Future로 변환
    return await _firebaseService.getBookmarks(documentId).first;
  }

  @override
  Future<PDFBookmark?> getBookmark(String bookmarkId) async {
    return await _firebaseService.getBookmark(bookmarkId);
  }

  @override
  Future<void> createBookmark(PDFBookmark bookmark) async {
    await _firebaseService.createBookmark(bookmark);
  }

  @override
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    await _firebaseService.updateBookmark(bookmark);
  }

  @override
  Future<void> deleteBookmark(String bookmarkId) async {
    await _firebaseService.deleteBookmark(bookmarkId);
  }

  @override
  Future<String> uploadPDFFile(String filePath, String fileName, {Uint8List? bytes}) async {
    return await _firebaseService.uploadPDFFile(filePath, fileName, bytes: bytes);
  }

  @override
  Future<void> deletePDFFile(String fileUrl) async {
    await _firebaseService.deletePDFFile(fileUrl);
  }

  @override
  Future<int> getPageCount(String filePath) async {
    // TODO: PDF 페이지 수 계산 로직 구현
    return 0;
  }

  @override
  Future<String> extractText(String filePath, int pageNumber) async {
    // TODO: PDF 텍스트 추출 로직 구현
    return '';
  }

  @override
  void dispose() {
    // 리소스 정리 로직
  }
} 