import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';
import '../../core/utils/result.dart';

/// PDF 원격 데이터 소스 인터페이스
abstract class PDFRemoteDataSource {
  /// 모든 PDF 문서 조회
  Future<Result<List<PDFDocumentModel>>> getDocuments();
  
  /// 특정 PDF 문서 조회
  Future<Result<PDFDocumentModel?>> getDocument(String id);
  
  /// PDF 문서 저장
  Future<Result<void>> saveDocument(PDFDocumentModel document);
  
  /// PDF 문서 업데이트
  Future<Result<void>> updateDocument(PDFDocumentModel document);
  
  /// PDF 문서 삭제
  Future<Result<void>> deleteDocument(String id);
  
  /// 북마크 목록 조회
  Future<Result<List<PDFBookmarkModel>>> getBookmarks(String documentId);
  
  /// 특정 북마크 조회
  Future<Result<PDFBookmarkModel?>> getBookmark(String id);
  
  /// 북마크 저장
  Future<Result<void>> saveBookmark(PDFBookmarkModel bookmark);
  
  /// 북마크 업데이트
  Future<Result<void>> updateBookmark(PDFBookmarkModel bookmark);
  
  /// 북마크 삭제
  Future<Result<void>> deleteBookmark(String id);
  
  /// PDF 다운로드
  Future<Result<Uint8List>> downloadPdf(String url);
  
  /// 마지막으로 읽은 페이지 저장
  Future<Result<void>> saveLastReadPage(String documentId, int page);
  
  /// 문서 생성
  Future<Result<void>> createDocument(PDFDocumentModel document);
}

/// Firebase 기반 PDF 원격 데이터 소스 구현체
@Injectable(as: PDFRemoteDataSource)
class FirebasePDFRemoteDataSource implements PDFRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  // Firestore 컬렉션 경로
  static const _documentsCollection = 'pdf_documents';
  static const _bookmarksCollection = 'pdf_bookmarks';
  
  FirebasePDFRemoteDataSource(this._firestore, this._storage);
  
  @override
  Future<Result<List<PDFDocumentModel>>> getDocuments() async {
    try {
      final snapshot = await _firestore.collection(_documentsCollection).get();
      
      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        return PDFDocumentModel.fromJson(data);
      }).toList();
      
      return Result.success(documents);
    } catch (e) {
      debugPrint('원격 문서 목록 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<PDFDocumentModel?>> getDocument(String id) async {
    try {
      final doc = await _firestore
          .collection(_documentsCollection)
          .doc(id)
          .get();
      
      if (!doc.exists) {
        return Result.success(null);
      }
      
      final data = doc.data();
      if (data == null) {
        return Result.success(null);
      }
      
      return Result.success(PDFDocumentModel.fromJson(data));
    } catch (e) {
      debugPrint('원격 문서 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> saveDocument(PDFDocumentModel document) async {
    try {
      await _firestore
          .collection(_documentsCollection)
          .doc(document.id)
          .set(document.toJson());
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 문서 저장 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> updateDocument(PDFDocumentModel document) async {
    try {
      await _firestore
          .collection(_documentsCollection)
          .doc(document.id)
          .update(document.toJson());
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 문서 업데이트 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> deleteDocument(String id) async {
    try {
      // 문서 삭제
      await _firestore
          .collection(_documentsCollection)
          .doc(id)
          .delete();
      
      // 관련 북마크 삭제
      final bookmarkSnapshot = await _firestore
          .collection(_bookmarksCollection)
          .where('documentId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in bookmarkSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 문서 삭제 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PDFBookmarkModel>>> getBookmarks(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection(_bookmarksCollection)
          .where('documentId', isEqualTo: documentId)
          .get();
      
      final bookmarks = snapshot.docs.map((doc) {
        final data = doc.data();
        return PDFBookmarkModel.fromJson(data);
      }).toList();
      
      return Result.success(bookmarks);
    } catch (e) {
      debugPrint('원격 북마크 목록 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<PDFBookmarkModel?>> getBookmark(String id) async {
    try {
      final doc = await _firestore
          .collection(_bookmarksCollection)
          .doc(id)
          .get();
      
      if (!doc.exists) {
        return Result.success(null);
      }
      
      final data = doc.data();
      if (data == null) {
        return Result.success(null);
      }
      
      return Result.success(PDFBookmarkModel.fromJson(data));
    } catch (e) {
      debugPrint('원격 북마크 조회 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> saveBookmark(PDFBookmarkModel bookmark) async {
    try {
      await _firestore
          .collection(_bookmarksCollection)
          .doc(bookmark.id)
          .set(bookmark.toJson());
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 북마크 저장 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> updateBookmark(PDFBookmarkModel bookmark) async {
    try {
      await _firestore
          .collection(_bookmarksCollection)
          .doc(bookmark.id)
          .update(bookmark.toJson());
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 북마크 업데이트 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> deleteBookmark(String id) async {
    try {
      await _firestore
          .collection(_bookmarksCollection)
          .doc(id)
          .delete();
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 북마크 삭제 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<Uint8List>> downloadPdf(String url) async {
    try {
      if (url.startsWith('gs://')) {
        // Firebase Storage URL인 경우
        final ref = _storage.refFromURL(url);
        final data = await ref.getData();
        
        if (data == null) {
          return Result.failure(Exception('PDF 다운로드 실패'));
        }
        
        return Result.success(data);
      } else if (url.startsWith('http')) {
        // HTTP URL인 경우
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode != 200) {
          return Result.failure(Exception('PDF 다운로드 실패: ${response.statusCode}'));
        }
        
        return Result.success(response.bodyBytes);
      } else {
        return Result.failure(Exception('지원되지 않는 URL 형식'));
      }
    } catch (e) {
      debugPrint('원격 PDF 다운로드 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> saveLastReadPage(String documentId, int page) async {
    try {
      await _firestore
          .collection(_documentsCollection)
          .doc(documentId)
          .update({'currentPage': page});
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 마지막 읽은 페이지 저장 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> createDocument(PDFDocumentModel document) async {
    try {
      await _firestore
          .collection(_documentsCollection)
          .doc(document.id)
          .set(document.toJson());
      
      return Result.success(null);
    } catch (e) {
      debugPrint('원격 문서 생성 오류: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
} 