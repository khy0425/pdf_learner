import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf_learner/models/pdf_document.dart';
import 'package:pdf_learner/services/pdf_service.dart';

class PDFServiceImpl implements PDFService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Map<String, PdfDocument> _openDocuments = {};

  PDFServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<PDFDocument?> openPDF(File file) async {
    try {
      // PDF 파일 읽기
      final pdf = await PdfDocument.openFile(file.path);
      final totalPages = pdf.pagesCount;

      // Firestore에 문서 저장
      final docRef = await _firestore.collection('pdfs').add({
        'title': file.path.split('/').last,
        'filePath': file.path,
        'totalPages': totalPages,
        'currentPage': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 메모리에 문서 저장
      _openDocuments[docRef.id] = pdf;

      return PDFDocument(
        id: docRef.id,
        title: file.path.split('/').last,
        filePath: file.path,
        totalPages: totalPages,
        currentPage: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('PDF 열기 실패: $e');
      return null;
    }
  }

  @override
  Future<void> closePDF(String id) async {
    try {
      final pdf = _openDocuments[id];
      if (pdf != null) {
        await pdf.close();
        _openDocuments.remove(id);
      }
    } catch (e) {
      print('PDF 닫기 실패: $e');
    }
  }

  @override
  Future<int> getPageCount(String id) async {
    final pdf = _openDocuments[id];
    if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');
    return pdf.pagesCount;
  }

  @override
  Future<void> goToPage(String id, int page) async {
    final pdf = _openDocuments[id];
    if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');
    if (page < 0 || page >= pdf.pagesCount) {
      throw Exception('유효하지 않은 페이지 번호입니다.');
    }
  }

  @override
  Future<File?> renderPage(String id, int page) async {
    try {
      final pdf = _openDocuments[id];
      if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');

      final pdfPage = await pdf.getPage(page + 1);
      final image = await pdfPage.render(
        width: pdfPage.width * 2,
        height: pdfPage.height * 2,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/page_$page.png');
      await file.writeAsBytes(image.bytes);

      return file;
    } catch (e) {
      print('페이지 렌더링 실패: $e');
      return null;
    }
  }

  @override
  Future<String?> extractText(String id, int page) async {
    try {
      final pdf = _openDocuments[id];
      if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');

      final pdfPage = await pdf.getPage(page + 1);
      return await pdfPage.text;
    } catch (e) {
      print('텍스트 추출 실패: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getMetadata(String id) async {
    final pdf = _openDocuments[id];
    if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');
    return pdf.metadata;
  }

  @override
  Future<List<String>> searchText(String id, String query) async {
    final pdf = _openDocuments[id];
    if (pdf == null) throw Exception('PDF가 열려있지 않습니다.');

    final results = <String>[];
    for (var i = 0; i < pdf.pagesCount; i++) {
      final page = await pdf.getPage(i + 1);
      final text = await page.text;
      if (text.toLowerCase().contains(query.toLowerCase())) {
        results.add('페이지 ${i + 1}: ${text.substring(0, 100)}...');
      }
    }
    return results;
  }

  @override
  Future<void> addBookmark(String id, int page) async {
    await _firestore.collection('pdfs').doc(id).update({
      'bookmarks': FieldValue.arrayUnion([page.toString()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeBookmark(String id, int page) async {
    await _firestore.collection('pdfs').doc(id).update({
      'bookmarks': FieldValue.arrayRemove([page.toString()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await _firestore.collection('pdfs').doc(id).get();
    final isFavorite = doc.data()?['isFavorite'] ?? false;
    
    await _firestore.collection('pdfs').doc(id).update({
      'isFavorite': !isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<PDFDocument>> getRecentDocuments() async {
    final snapshot = await _firestore
        .collection('pdfs')
        .orderBy('updatedAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => PDFDocument.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<PDFDocument>> getFavoriteDocuments() async {
    final snapshot = await _firestore
        .collection('pdfs')
        .where('isFavorite', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PDFDocument.fromFirestore(doc))
        .toList();
  }
} 