import 'package:injectable/injectable.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/file_storage_service.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'pdf_remote_datasource.dart';

@Injectable(as: PDFRemoteDataSource)
class PDFRemoteDataSourceImpl implements PDFRemoteDataSource {
  final FirebaseService _firebaseService;
  final FileStorageService _fileStorageService;

  PDFRemoteDataSourceImpl({
    required FirebaseService firebaseService,
    required FileStorageService fileStorageService,
  })  : _firebaseService = firebaseService,
        _fileStorageService = fileStorageService;

  @override
  Future<void> uploadPDF(PDFDocument document, String filePath) async {
    try {
      final storagePath = 'pdfs/${document.id}';
      await _fileStorageService.uploadFile(filePath, storagePath);
      await _firebaseService.setPDFDocument(document);
    } catch (e) {
      throw Exception('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<List<PDFDocument>> getPDFDocuments() async {
    try {
      return await _firebaseService.getPDFDocuments();
    } catch (e) {
      throw Exception('PDF 문서 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<PDFDocument?> getPDFDocument(String documentId) async {
    try {
      return await _firebaseService.getPDFDocument(documentId);
    } catch (e) {
      throw Exception('PDF 문서를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> deletePDFDocument(String documentId) async {
    try {
      await _firebaseService.deletePDFDocument(documentId);
      await _fileStorageService.deleteFile('pdfs/$documentId');
    } catch (e) {
      throw Exception('PDF 문서 삭제 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> updatePDFDocument(PDFDocument document) async {
    try {
      await _firebaseService.updatePDFDocument(document);
    } catch (e) {
      throw Exception('PDF 문서 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> saveBookmark(PDFBookmark bookmark) async {
    try {
      await _firebaseService.saveBookmark(bookmark);
    } catch (e) {
      throw Exception('북마크 저장 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    try {
      return await _firebaseService.getBookmarks(documentId);
    } catch (e) {
      throw Exception('북마크 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _firebaseService.deleteBookmark(bookmarkId);
    } catch (e) {
      throw Exception('북마크 삭제 중 오류가 발생했습니다: $e');
    }
  }
} 