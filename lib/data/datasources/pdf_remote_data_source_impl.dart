import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../services/firebase/firebase_service.dart';
import '../../core/base/result.dart';
import 'pdf_remote_data_source.dart';

/// Firebase를 사용하는 원격 데이터 소스 구현
@Injectable(as: PDFRemoteDataSource)
class PDFRemoteDataSourceImpl implements PDFRemoteDataSource {
  final FirebaseService _firebaseService;
  final Uuid _uuid = const Uuid();
  
  /// 생성자
  PDFRemoteDataSourceImpl({
    required FirebaseService firebaseService,
  }) : _firebaseService = firebaseService;

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final result = await _firebaseService.getPDFDocuments();
      return result;
    } catch (e) {
      return Result.failureWithMessage('원격 문서 목록을 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<PDFDocument>> getDocument(String documentId) async {
    try {
      final result = await _firebaseService.getPDFDocument(documentId);
      if (result.isSuccess && result.data != null) {
        return Result.success(result.data!);
      }
      return Result.failureWithMessage('문서가 존재하지 않습니다');
    } catch (e) {
      return Result.failureWithMessage('원격 문서를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      final result = await _firebaseService.getBookmarksForDocument(documentId);
      return result;
    } catch (e) {
      return Result.failureWithMessage('북마크 목록을 가져오는데 실패했습니다: $e');
    }
  }
  
  @override
  Future<Result<PDFBookmark>> getBookmarkByIds(String documentId, String bookmarkId) async {
    try {
      final result = await _firebaseService.getBookmark(bookmarkId);
      if (result.isSuccess && result.data != null) {
        return Result.success(result.data!);
      }
      return Result.failureWithMessage('북마크가 존재하지 않습니다');
    } catch (e) {
      return Result.failureWithMessage('북마크를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<PDFBookmark?>> getBookmarkById(String id) async {
    try {
      return await _firebaseService.getBookmark(id);
    } catch (e) {
      return Result.failureWithMessage('북마크 ID로 검색 실패: $e');
    }
  }

  @override
  Future<Result<String>> addDocument(PDFDocument document) async {
    try {
      final result = await _firebaseService.savePDFDocument(document);
      if (result.isSuccess) {
        return Result.success(result.data.id);
      }
      return Result.failureWithMessage('문서 추가에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('문서 추가에 실패했습니다: $e');
    }
  }
  
  @override
  Future<Result<String>> createDocument(PDFDocument document) async {
    return addDocument(document);
  }

  @override
  Future<Result<bool>> updateDocument(PDFDocument document) async {
    try {
      final result = await _firebaseService.savePDFDocument(document);
      return Result.success(result.isSuccess);
    } catch (e) {
      return Result.failureWithMessage('문서 업데이트에 실패했습니다: $e');
    }
  }
  
  @override
  Future<Result<void>> saveDocument(PDFDocument document) async {
    try {
      final result = await _firebaseService.savePDFDocument(document);
      if (result.isSuccess) {
        return Result.success(null);
      }
      return Result.failureWithMessage('문서 저장에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('문서 저장에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> deleteDocument(String documentId) async {
    try {
      await _firebaseService.deletePDFDocument(documentId);
      return Result.success(true);
    } catch (e) {
      return Result.failureWithMessage('문서 삭제에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<String>> addBookmark(PDFBookmark bookmark) async {
    try {
      final result = await _firebaseService.saveBookmark(bookmark);
      if (result.isSuccess) {
        return Result.success(result.data.id);
      }
      return Result.failureWithMessage('북마크 추가에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('북마크 추가에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> updateBookmark(PDFBookmark bookmark) async {
    try {
      final result = await _firebaseService.saveBookmark(bookmark);
      return Result.success(result.isSuccess);
    } catch (e) {
      return Result.failureWithMessage('북마크 업데이트에 실패했습니다: $e');
    }
  }
  
  @override
  Future<Result<void>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final result = await _firebaseService.saveBookmark(bookmark);
      if (result.isSuccess) {
        return Result.success(null);
      }
      return Result.failureWithMessage('북마크 저장에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('북마크 저장에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> deleteBookmark(String documentId, String bookmarkId) async {
    try {
      final result = await _firebaseService.deleteBookmark(documentId, bookmarkId);
      return Result.success(result.isSuccess);
    } catch (e) {
      return Result.failureWithMessage('북마크 삭제에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> saveLastReadPage(String documentId, int page) async {
    try {
      // 여기서는 문서 업데이트로 처리
      final documentResult = await _firebaseService.getPDFDocument(documentId);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      final updatedDocument = document.copyWith(
        lastReadPage: page,
        updatedAt: DateTime.now(),
      );
      
      final saveResult = await _firebaseService.savePDFDocument(updatedDocument);
      return Result.success(saveResult.isSuccess);
    } catch (e) {
      return Result.failureWithMessage('마지막 읽은 페이지 저장에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFDocument>>> syncWithRemote(List<PDFDocument> localDocuments, List<PDFBookmark> localBookmarks) async {
    try {
      // 원격 문서 목록 가져오기
      final remoteDocumentsResult = await getDocuments();
      if (remoteDocumentsResult.isFailure) {
        return Result.failureWithMessage('원격 문서 목록을 가져오는데 실패했습니다');
      }
      
      final remoteDocuments = remoteDocumentsResult.data;
      
      // 로컬에만 있는 문서 추가
      for (final localDoc in localDocuments) {
        final exists = remoteDocuments.any((remote) => remote.id == localDoc.id);
        if (!exists) {
          await _firebaseService.savePDFDocument(localDoc);
        }
      }
      
      // 북마크 동기화
      for (final localBookmark in localBookmarks) {
        final bookmarkResult = await getBookmarkById(localBookmark.id);
        if (bookmarkResult.isSuccess && bookmarkResult.data == null) {
          await _firebaseService.saveBookmark(localBookmark);
        }
      }
      
      // 최신 문서 목록 다시 가져오기
      final updatedDocumentsResult = await getDocuments();
      if (updatedDocumentsResult.isSuccess) {
        return updatedDocumentsResult;
      } else {
        return Result.success(localDocuments);
      }
    } catch (e) {
      return Result.failureWithMessage('동기화에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFDocument>>> searchDocuments(String query) async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data;
      final results = documents.where((doc) {
        final title = doc.title.toLowerCase();
        final description = doc.description?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        
        return title.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
      
      return Result.success(results);
    } catch (e) {
      return Result.failureWithMessage('문서 검색에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final documentResult = await _firebaseService.getPDFDocument(id);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      final updatedDocument = document.copyWith(
        isFavorite: !document.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      final saveResult = await _firebaseService.savePDFDocument(updatedDocument);
      return Result.success(saveResult.isSuccess);
    } catch (e) {
      return Result.failureWithMessage('즐겨찾기 상태 변경에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data;
      final favorites = documents.where((doc) => doc.isFavorite).toList();
      
      return Result.success(favorites);
    } catch (e) {
      return Result.failureWithMessage('즐겨찾기 문서 목록을 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments() async {
    try {
      final documentsResult = await getDocuments();
      if (documentsResult.isFailure) {
        return documentsResult;
      }
      
      final documents = documentsResult.data;
      documents.sort((a, b) {
        final aTime = a.lastAccessedAt ?? DateTime.now();
        final bTime = b.lastAccessedAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      final recentDocs = documents.take(10).toList();
      return Result.success(recentDocs);
    } catch (e) {
      return Result.failureWithMessage('최근 문서 목록을 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getAllBookmarks() async {
    try {
      final result = await _firebaseService.getAllBookmarks();
      return result;
    } catch (e) {
      return Result.failureWithMessage('모든 북마크를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<Result<void>> updateReadingProgress(String id, double progress) async {
    try {
      final documentResult = await _firebaseService.getPDFDocument(id);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      final updatedDocument = document.copyWith(
        readingProgress: progress,
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.savePDFDocument(updatedDocument);
      return Result.success(null);
    } catch (e) {
      return Result.failureWithMessage('읽기 진행도 업데이트에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<void>> updateCurrentPage(String id, int page) async {
    try {
      final documentResult = await _firebaseService.getPDFDocument(id);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      final updatedDocument = document.copyWith(
        currentPage: page,
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.savePDFDocument(updatedDocument);
      return Result.success(null);
    } catch (e) {
      return Result.failureWithMessage('현재 페이지 업데이트에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<void>> updateReadingTime(String id, int seconds) async {
    try {
      final documentResult = await _firebaseService.getPDFDocument(id);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      final updatedDocument = document.copyWith(
        readingTime: (document.readingTime ?? 0) + seconds,
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.savePDFDocument(updatedDocument);
      return Result.success(null);
    } catch (e) {
      return Result.failureWithMessage('읽기 시간 업데이트에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<String>> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      final uniqueId = _uuid.v4();
      final fileName = path.basename(filePath);
      
      // 문서 메타데이터 생성
      final document = PDFDocument(
        id: uniqueId,
        title: path.basenameWithoutExtension(fileName),
        filePath: filePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 파일 업로드
      final uploadResult = await _firebaseService.uploadPDFDocument(file, document);
      if (uploadResult.isSuccess) {
        return Result.success(uploadResult.data.id);
      }
      
      return Result.failureWithMessage('파일 업로드에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('파일 업로드에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<String?>> downloadFile(String remoteUrl) async {
    // 이 메서드는 Firebase Storage URL을 통해 파일을 다운로드하여 로컬에 저장하는 기능입니다.
    // 실제 구현은 프로젝트 요구사항에 따라 달라질 수 있습니다.
    return Result.failureWithMessage('지원하지 않는 기능입니다');
  }

  @override
  Future<Result<Uint8List>> downloadPdf(String documentId) async {
    try {
      final documentResult = await _firebaseService.getPDFDocument(documentId);
      if (documentResult.isFailure || documentResult.data == null) {
        return Result.failureWithMessage('문서를 찾을 수 없습니다');
      }
      
      final document = documentResult.data!;
      
      if (document.url == null || document.url.isEmpty) {
        return Result.failureWithMessage('다운로드 URL이 없습니다');
      }
      
      // URL에서 PDF 다운로드
      final response = await http.get(Uri.parse(document.url));
      
      if (response.statusCode != 200) {
        return Result.failureWithMessage('파일 다운로드에 실패했습니다: ${response.statusCode}');
      }
      
      return Result.success(response.bodyBytes);
    } catch (e) {
      return Result.failureWithMessage('PDF 다운로드에 실패했습니다: $e');
    }
  }

  @override
  Future<Result<bool>> deleteFile(String remoteUrl) async {
    // Firebase Storage에서 파일 삭제
    // 실제 구현은 프로젝트 요구사항에 따라 달라질 수 있습니다.
    return Result.failureWithMessage('지원하지 않는 기능입니다');
  }

  @override
  Future<Result<PDFDocument>> importPDF(File file) async {
    try {
      final uniqueId = _uuid.v4();
      final fileName = path.basename(file.path);
      
      // 문서 메타데이터 생성
      final document = PDFDocument(
        id: uniqueId,
        title: path.basenameWithoutExtension(fileName),
        filePath: file.path,
        fileSize: await file.length(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Firebase에 업로드 및 저장
      final uploadResult = await _firebaseService.uploadPDFDocument(file, document);
      if (uploadResult.isSuccess) {
        return Result.success(uploadResult.data);
      }
      
      return Result.failureWithMessage('파일 가져오기에 실패했습니다');
    } catch (e) {
      return Result.failureWithMessage('PDF 파일 가져오기에 실패했습니다: $e');
    }
  }

  @override
  void dispose() {
    // Firebase 자원 정리
  }
} 