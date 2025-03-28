import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import './pdf_remote_data_source.dart';
import '../../core/base/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/firebase_service.dart';
import '../models/pdf_document_model.dart';
import '../models/pdf_bookmark_model.dart';
import 'package:uuid/uuid.dart';
import '../../core/exceptions/auth_exception.dart';
import '../../core/base/exception_wrapper.dart';

@Injectable(as: PDFRemoteDataSource)
class FirebasePDFRemoteDataSource implements PDFRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseService _firebaseService;
  
  static const String _documentsCollection = 'pdf_documents';
  static const String _bookmarksCollection = 'pdf_bookmarks';
  static const String _lastReadCollection = 'lastRead';
  static const String _storageFolder = 'pdf_files';
  static const int _maxSyncBatchSize = 20;

  FirebasePDFRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseService firebaseService,
  }) : _firestore = firestore,
       _storage = storage,
       _firebaseService = firebaseService;

  String get _userId {
    final user = _firebaseService.currentUser;
    if (user == null) {
      throw AuthException(message: '사용자가 인증되지 않았습니다.');
    }
    return user.uid;
  }

  @override
  Future<Result<List<PDFDocument>>> getDocuments() async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .get();

      final documents = docs.docs
          .map((doc) => PDFDocument.fromMap(doc.data()))
          .toList();

      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('문서 목록을 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<PDFDocument>> getDocument(String documentId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .get();

      if (!doc.exists) {
        return Result.failure(Exception('문서가 존재하지 않습니다.'));
      }

      return Result.success(PDFDocument.fromMap(doc.data()!));
    } catch (e) {
      return Result.failure(Exception('문서를 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getBookmarks(String documentId) async {
    try {
      final bookmarkDocs = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .collection('bookmarks')
          .get();

      final bookmarks = bookmarkDocs.docs
          .map((doc) => PDFBookmark.fromMap(doc.data()))
          .toList();

      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('북마크 목록을 가져오는데 실패했습니다: $e'));
    }
  }
  
  @override
  Future<Result<PDFBookmark>> getBookmarkByIds(String documentId, String bookmarkId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .collection('bookmarks')
          .doc(bookmarkId)
          .get();

      if (!doc.exists) {
        return Result.failure(Exception('북마크가 존재하지 않습니다.'));
      }

      return Result.success(PDFBookmark.fromMap(doc.data()!));
    } catch (e) {
      return Result.failure(Exception('북마크를 가져오는데 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<PDFBookmark?>> getBookmarkById(String id) async {
    try {
      // 모든 문서에서 해당 ID의 북마크 검색
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collectionGroup('bookmarks')
          .where('id', isEqualTo: id)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return Result.success(null);
      }
      
      final bookmarkData = querySnapshot.docs.first.data();
      return Result.success(PDFBookmark.fromMap(bookmarkData));
    } catch (e) {
      return Result.failure(Exception('북마크 ID로 검색 실패: $e'));
    }
  }

  @override
  Future<Result<String>> addDocument(PDFDocument document) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(document.id);

      await docRef.set(document.toMap());

      return Result.success(document.id);
    } catch (e) {
      return Result.failure(Exception('문서 추가에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> updateDocument(PDFDocument document) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(document.id)
          .update(document.toMap());

      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('문서 업데이트에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteDocument(String documentId) async {
    try {
      // 문서 삭제
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .delete();

      // 관련 북마크 모두 삭제
      final bookmarkDocs = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .collection('bookmarks')
          .get();

      final batch = _firestore.batch();
      for (var doc in bookmarkDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('문서 삭제에 실패했습니다: $e'));
    }
  }
  
  @override
  Future<Result<String>> addBookmark(PDFBookmark bookmark) async {
    try {
      final bookmarkRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(bookmark.documentId)
          .collection('bookmarks')
          .doc(bookmark.id);

      await bookmarkRef.set(bookmark.toMap());

      return Result.success(bookmark.id);
    } catch (e) {
      return Result.failure(Exception('북마크 추가에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> updateBookmark(PDFBookmark bookmark) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(bookmark.documentId)
          .collection('bookmarks')
          .doc(bookmark.id)
          .update(bookmark.toMap());

      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('북마크 업데이트에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteBookmark(String documentId, String bookmarkId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .collection('bookmarks')
          .doc(bookmarkId)
          .delete();

      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<bool>> saveLastReadPage(String documentId, int page) async {
    try {
      final docResult = await getDocument(documentId);
      
      if (docResult.isFailure) {
        return Result.failure(Exception('문서를 찾을 수 없습니다.'));
      }
      
      final document = docResult.data!;
      final updatedDocument = document.copyWith(lastReadPage: page, lastAccessedAt: DateTime.now());
      
      return updateDocument(updatedDocument);
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 저장에 실패했습니다: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> syncWithRemote(List<PDFDocument> localDocuments, List<PDFBookmark> localBookmarks) async {
    try {
      // 사용자 인증 확인
      if (_firebaseService.currentUser == null) {
        return Result.failure(AuthException(message: '사용자 인증이 필요합니다'));
      }
      
      // 원격 문서 가져오기
      final remoteDocsResult = await getDocuments();
      if (remoteDocsResult.isFailure) {
        return Result.failure(remoteDocsResult.error!);
      }
      
      final remoteDocs = remoteDocsResult.data!;
      final mergedDocs = <PDFDocument>[];
      
      // 로컬 문서를 원격 저장소에 동기화
      for (final localDoc in localDocuments) {
        final remoteDoc = remoteDocs.firstWhere(
          (doc) => doc.id == localDoc.id,
          orElse: () => PDFDocument(id: '', title: '', filePath: '')
        );
        
        if (remoteDoc.id.isEmpty) {
          // 원격에 없는 문서는 추가
          final addResult = await addDocument(localDoc);
          if (addResult.isSuccess) {
            mergedDocs.add(localDoc);
          }
        } else {
          // 날짜 비교하여 최신 버전 결정
          final localUpdatedAt = localDoc.updatedAt;
          final remoteUpdatedAt = remoteDoc.updatedAt;
          
          if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
            // 로컬이 최신이면 원격 업데이트
            await updateDocument(localDoc);
            mergedDocs.add(localDoc);
          } else {
            // 원격이 최신이면 로컬 업데이트용으로 원격 버전 사용
            mergedDocs.add(remoteDoc);
          }
        }
      }
      
      // 원격에만 있는 문서 추가
      for (final remoteDoc in remoteDocs) {
        final existsLocally = localDocuments.any((doc) => doc.id == remoteDoc.id);
        if (!existsLocally) {
          mergedDocs.add(remoteDoc);
        }
      }
      
      // 북마크 동기화
      await _syncBookmarks(localBookmarks);
      
      return Result.success(mergedDocs);
    } catch (e) {
      return Result.failure(Exception('동기화 중 오류 발생: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> searchDocuments(String query) async {
    try {
      final snapshot = await _firestore
          .collection('pdf_documents')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final documents = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PDFDocument.fromMap(data);
          })
          .toList();
      
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('문서 검색 실패: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .doc(id)
          .get();
      
      if (!doc.exists) return Result.success(false);
      
      final data = doc.data()!;
      final isFavorite = data['isFavorite'] as bool? ?? false;
      
      await doc.reference.update({'isFavorite': !isFavorite});
      
      return Result.success(!isFavorite);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 토글 실패: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .where('isFavorite', isEqualTo: true)
          .get();

      final documents = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PDFDocument.fromMap(data);
          })
          .toList();
      
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 문서 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<List<PDFDocument>>> getRecentDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      final documents = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PDFDocument.fromMap(data);
          })
          .toList();
      
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('최근 문서 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<void>> updateReadingProgress(String id, double progress) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .doc(id)
          .update({
            'readingProgress': progress,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('읽기 진행도 업데이트 실패: $e'));
    }
  }

  @override
  Future<Result<void>> updateCurrentPage(String id, int page) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .doc(id)
          .update({
            'currentPage': page,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('현재 페이지 업데이트 실패: $e'));
    }
  }

  @override
  Future<Result<void>> updateReadingTime(String id, int seconds) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_documentsCollection)
          .doc(id)
          .update({
            'readingTime': FieldValue.increment(seconds),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('읽기 시간 업데이트 실패: $e'));
    }
  }

  @override
  Future<Result<String>> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final ref = _storage.ref('$_documentsCollection/$fileName');
      
      await ref.putFile(file);
      
      final downloadUrl = await ref.getDownloadURL();
      return Result.success(downloadUrl);
    } catch (e) {
      return Result.failure(Exception('파일 업로드 실패: $e'));
    }
  }

  @override
  Future<Result<String?>> downloadFile(String remoteUrl) async {
    try {
      // 이 메서드는 모바일 환경에서만 구현
      if (kIsWeb) {
        return Result.success(remoteUrl);
      }
      
      // 실제 구현은 여기에 추가해야 함
      throw UnimplementedError('다운로드 기능은 아직 구현되지 않았습니다.');
    } catch (e) {
      return Result.failure(Exception('파일 다운로드 실패: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteFile(String remoteUrl) async {
    try {
      final ref = _storage.refFromURL(remoteUrl);
      await ref.delete();
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('파일 삭제 실패: $e'));
    }
  }

  @override
  Future<Result<PDFDocument>> importPDF(File file) async {
    try {
      if (!file.existsSync()) {
        return Result.failure(Exception('파일이 존재하지 않습니다.'));
      }
      
      // 파일 이름에서 확장자를 제외한 제목 추출
      final fileName = file.path.split('/').last;
      final title = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      
      // UUID 생성
      final uuid = Uuid();
      final documentId = uuid.v4();
      
      // Firebase Storage에 파일 업로드
      final Reference ref = _storage.ref().child('users/$_userId/pdfs/$documentId.pdf');
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // PDF 문서 생성
      final document = PDFDocument(
        id: documentId,
        title: title,
        fileName: fileName,
        downloadUrl: downloadUrl,
        path: file.path,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PDFDocumentStatus.imported,
        fileSize: file.lengthSync(),
        pageCount: 0, // 실제 페이지 수는 별도로 계산 필요
        localPath: file.path,
      );
      
      // Firestore에 문서 저장
      final result = await addDocument(document);
      
      if (result.isFailure) {
        return Result.failure(result.error!);
      }
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 가져오기 중 오류 발생: $e'));
    }
  }

  @override
  void dispose() {
    // 리소스 정리가 필요한 경우 여기에 구현
  }

  @override
  Future<Result<String>> createDocument(PDFDocument document) async {
    return addDocument(document);
  }

  @override
  Future<Result<void>> saveDocument(PDFDocument document) async {
    try {
      final result = await updateDocument(document);
      if (result.isFailure) {
        return Result.failure(result.error!);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('문서 저장 실패: $e'));
    }
  }

  @override
  Future<Result<List<PDFBookmark>>> getAllBookmarks() async {
    try {
      final result = await _getAllBookmarks();
      if (result.isFailure) {
        return Result.failure(result.error!);
      }
      return Result.success(result.data!);
    } catch (e) {
      return Result.failure(Exception('북마크 목록 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<void>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final result = await updateBookmark(bookmark);
      if (result.isFailure) {
        return Result.failure(result.error!);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('북마크 저장 실패: $e'));
    }
  }

  @override
  Future<Result<PDFBookmark?>> getBookmark(String id, String documentId) async {
    try {
      final result = await getBookmarkById(id);
      if (result.isFailure) {
        return Result.failure(result.error!);
      }
      return Result.success(result.data);
    } catch (e) {
      return Result.failure(Exception('북마크 가져오기 실패: $e'));
    }
  }
  
  // 모든 북마크 가져오기 (내부 메서드)
  Future<Result<List<PDFBookmark>>> _getAllBookmarks() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_bookmarksCollection)
          .get();
          
      final bookmarks = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PDFBookmark.fromMap(data);
          })
          .toList();
          
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('모든 북마크 가져오기 실패: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> downloadPdf(String documentId) async {
    try {
      // 먼저 문서 정보를 가져와서 다운로드 URL을 확인합니다
      final docResult = await getDocument(documentId);
      if (docResult.isFailure) {
        return Result.failure(docResult.error!);
      }
      
      final document = docResult.data!;
      final downloadUrl = document.downloadUrl;
      
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return Result.failure(Exception('문서에 다운로드 URL이 없습니다.'));
      }
      
      // URL에서 파일 다운로드
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        return Result.failure(Exception('PDF 다운로드 실패: HTTP 상태 코드 ${response.statusCode}'));
      }
      
      // 바이트 데이터 반환
      return Result.success(response.bodyBytes);
    } catch (e) {
      return Result.failure(Exception('PDF 다운로드 중 오류 발생: $e'));
    }
  }

  // 북마크 동기화 헬퍼 메소드
  Future<void> _syncBookmarks(List<PDFBookmark> localBookmarks) async {
    try {
      // 원격 북마크 가져오기
      final remoteBookmarksResult = await getAllBookmarks();
      if (remoteBookmarksResult.isFailure) {
        return;
      }
      
      final remoteBookmarks = remoteBookmarksResult.data!;
      
      // 로컬 북마크를 원격에 동기화
      for (final localBookmark in localBookmarks) {
        final remoteBookmark = remoteBookmarks.firstWhere(
          (b) => b.id == localBookmark.id,
          orElse: () => PDFBookmark(id: '', documentId: '', title: '', page: 0)
        );
        
        if (remoteBookmark.id.isEmpty) {
          // 원격에 없는 북마크는 추가
          await addBookmark(localBookmark);
        } else {
          // 날짜 비교하여 최신 버전 결정
          final localUpdatedAt = localBookmark.updatedAt;
          final remoteUpdatedAt = remoteBookmark.updatedAt;
          
          if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
            // 로컬이 최신이면 원격 업데이트
            await updateBookmark(localBookmark);
          }
        }
      }
      
      // 여기서는 원격에만 있는 북마크는 로컬에 추가하지 않음
      // 이 부분은 repository에서 처리하도록 함
    } catch (e) {
      debugPrint('북마크 동기화 중 오류: $e');
    }
  }
} 