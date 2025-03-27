import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import '../domain/models/pdf_document.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../domain/models/pdf_bookmark.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../core/models/result.dart';

@injectable
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  final Uuid _uuid = const Uuid();

  // 인증 관련 메서드
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// 이메일/비밀번호로 로그인
  Future<Result<User>> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(Exception('로그인 실패: $e'));
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  Future<Result<User>> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(Exception('회원가입 실패: $e'));
    }
  }
  
  /// 구글로 로그인
  Future<Result<User>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        return Result.failure(Exception('구글 로그인 취소'));
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      return Result.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(Exception('구글 로그인 실패: $e'));
    }
  }
  
  /// 익명으로 로그인
  Future<Result<User>> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return Result.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(Exception('익명 로그인 실패: $e'));
    }
  }
  
  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
  
  /// 사용자 ID 가져오기
  String? get userId => _auth.currentUser?.uid;
  
  // PDF 문서 관련 메서드
  
  /// PDF 문서 컬렉션 참조
  CollectionReference get _pdfsCollection => 
      _firestore.collection('pdf_documents');
  
  /// 사용자 PDF 문서 컬렉션 참조
  CollectionReference get _userPdfsCollection => 
      _firestore.collection('users/${userId ?? 'anonymous'}/pdf_documents');
  
  /// 북마크 컬렉션 참조
  CollectionReference get _bookmarksCollection => 
      _firestore.collection('bookmarks');
  
  /// 사용자 북마크 컬렉션 참조
  CollectionReference _userBookmarksForDocument(String documentId) => 
      _firestore.collection('users/${userId ?? 'anonymous'}/pdf_documents/$documentId/bookmarks');
  
  /// PDF 문서 저장
  Future<Result<PDFDocument>> savePDFDocument(PDFDocument document) async {
    try {
      final docRef = document.id.isEmpty 
          ? _userPdfsCollection.doc()
          : _userPdfsCollection.doc(document.id);
      
      final updatedDocument = document.copyWith(
        id: docRef.id,
        createdAt: document.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(updatedDocument.toMap());
      
      return Result.success(updatedDocument);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 저장 실패: $e'));
    }
  }
  
  /// PDF 문서 업로드
  Future<Result<PDFDocument>> uploadPDFDocument(File file, PDFDocument document) async {
    try {
      final fileName = path.basename(file.path);
      final storagePath = 'pdfs/${userId ?? 'anonymous'}/${document.id}/$fileName';
      
      // 파일 업로드
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 문서 정보 업데이트
      final updatedDocument = document.copyWith(
        downloadUrl: downloadUrl,
        filePath: storagePath,
        status: PDFDocumentStatus.downloaded,
        updatedAt: DateTime.now(),
      );
      
      // Firestore에 저장
      return savePDFDocument(updatedDocument);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 업로드 실패: $e'));
    }
  }
  
  /// PDF 문서 가져오기
  Future<Result<PDFDocument?>> getPDFDocument(String documentId) async {
    try {
      final doc = await _firestore
          .collection('pdf_documents')
          .doc(documentId)
          .get();
      
      if (!doc.exists) {
        return Result.success(null);
      }
      
      final document = PDFDocument.fromMap(doc.data() as Map<String, dynamic>);
      
      return Result.success(document);
    } catch (e) {
      debugPrint('PDF 문서 가져오기 오류: $e');
      return Result.failure(Exception('PDF 문서 가져오기 실패: $e'));
    }
  }
  
  /// PDF 문서 목록 가져오기
  Future<Result<List<PDFDocument>>> getPDFDocuments() async {
    try {
      final querySnapshot = await _userPdfsCollection.get();
      
      final documents = querySnapshot.docs
          .map((doc) => PDFDocument.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      return Result.success(documents);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 목록 가져오기 실패: $e'));
    }
  }
  
  /// PDF 문서 삭제
  Future<Result<void>> deletePDFDocument(String documentId) async {
    try {
      // 문서 정보 가져오기
      final docResult = await getPDFDocument(documentId);
      
      if (docResult.isFailure) {
        return Result.failure(docResult.error!);
      }
      
      final document = docResult.getOrNull()!;
      
      // 스토리지 파일 삭제
      if (document.filePath.isNotEmpty) {
        await _storage.ref().child(document.filePath).delete();
      }
      
      // Firestore 문서 삭제
      await _userPdfsCollection.doc(documentId).delete();
      
      // 관련 북마크 삭제
      await _deleteBookmarksForDocument(documentId);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 삭제 실패: $e'));
    }
  }
  
  /// 문서 관련 북마크 모두 삭제
  Future<void> _deleteBookmarksForDocument(String documentId) async {
    final bookmarksSnapshot = await _userBookmarksForDocument(documentId).get();
    
    final batch = _firestore.batch();
    for (final doc in bookmarksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  /// 북마크 저장
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final bookmarkRef = bookmark.id.isEmpty
          ? _userBookmarksForDocument(bookmark.documentId).doc()
          : _userBookmarksForDocument(bookmark.documentId).doc(bookmark.id);
      
      final updatedBookmark = bookmark.copyWith(
        id: bookmarkRef.id,
        createdAt: bookmark.createdAt ?? DateTime.now(),
      );
      
      await bookmarkRef.set(updatedBookmark.toMap());
      
      return Result.success(updatedBookmark);
    } catch (e) {
      return Result.failure(Exception('북마크 저장 실패: $e'));
    }
  }
  
  /// 북마크 가져오기
  Future<Result<PDFBookmark>> getBookmark(String documentId, String bookmarkId) async {
    try {
      final docSnapshot = await _userBookmarksForDocument(documentId).doc(bookmarkId).get();
      
      if (!docSnapshot.exists) {
        return Result.failure(Exception('북마크를 찾을 수 없습니다.'));
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final bookmark = PDFBookmark.fromMap(data);
      
      return Result.success(bookmark);
    } catch (e) {
      return Result.failure(Exception('북마크 가져오기 실패: $e'));
    }
  }
  
  /// 문서의 북마크 목록 가져오기
  Future<Result<List<PDFBookmark>>> getBookmarksForDocument(String documentId) async {
    try {
      final querySnapshot = await _userBookmarksForDocument(documentId).get();
      
      final bookmarks = querySnapshot.docs
          .map((doc) => PDFBookmark.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('북마크 목록 가져오기 실패: $e'));
    }
  }
  
  /// 북마크 삭제
  Future<Result<void>> deleteBookmark(String documentId, String bookmarkId) async {
    try {
      await _userBookmarksForDocument(documentId).doc(bookmarkId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제 실패: $e'));
    }
  }
  
  /// PDF 파일 다운로드
  Future<Result<Uint8List>> downloadPDFFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final data = await ref.getData();
      
      if (data == null) {
        return Result.failure(Exception('PDF 파일 다운로드 실패: 데이터가 없습니다.'));
      }
      
      return Result.success(data);
    } catch (e) {
      return Result.failure(Exception('PDF 파일 다운로드 실패: $e'));
    }
  }

  // 이전 메서드에 대한 래퍼
  Future<String> uploadBytes(Uint8List bytes, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('바이트 데이터 업로드 중 오류: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.refFromURL(storagePath);
      await ref.delete();
    } catch (e) {
      debugPrint('파일 삭제 중 오류: $e');
      rethrow;
    }
  }

  /// PDF 문서 업데이트
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    try {
      final docRef = _firestore
          .collection('pdf_documents')
          .doc(document.id);
      
      final data = document.toMap();
      // createdAt과 updatedAt 필드는 항상 Timestamp로 변환해서 저장
      data['createdAt'] = Timestamp.fromDate(document.createdAt);
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await docRef.update(data);
      
      // 업데이트된 문서 반환
      return Result.success(document.copyWith(
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('PDF 문서 업데이트 오류: $e');
      return Result.failure(Exception('PDF 문서 업데이트 실패: $e'));
    }
  }

  // 구독 관련 메서드
  
  /// 구독 정보 저장
  Future<Result<bool>> saveSubscription(String userId, Map<String, dynamic> subscriptionData) async {
    try {
      if (userId.isEmpty) {
        return Result.failure(Exception('유효하지 않은.사용자 ID'));
      }
      
      // 구독 정보 컬렉션에 저장
      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscriptionData, SetOptions(merge: true));
      
      // 사용자 문서가 존재하는지 확인
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        // 사용자 문서가 없으면 새로 생성
        await _firestore.collection('users').doc(userId).set({
          'hasActiveSubscription': true,
          'subscriptionType': subscriptionData['planName'],
          'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 사용자 정보 업데이트
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
              'hasActiveSubscription': true,
              'subscriptionType': subscriptionData['planName'],
              'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
            });
      }
      
      return Result.success(true);
    } catch (e) {
      debugPrint('구독 정보 저장 오류: $e');
      return Result.failure(Exception('구독 정보 저장 실패: $e'));
    }
  }

  /// 구독 상태 확인
  Future<Result<Map<String, dynamic>?>> getSubscriptionStatus(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();
      
      if (docSnapshot.exists) {
        return Result.success(docSnapshot.data());
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.failure(Exception('구독 상태 확인 실패: $e'));
    }
  }

  /// 구독 취소
  Future<Result<bool>> cancelSubscription(String userId) async {
    try {
      // 현재 구독 정보 가져오기
      final subscription = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();
      
      if (!subscription.exists) {
        return Result.failure(Exception('활성 구독을 찾을 수 없습니다'));
      }
      
      // 구독 상태를 취소로 업데이트
      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .update({'status': 'cancelled'});
      
      // 사용자 문서 업데이트 - 구독 상태 비활성화
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'hasActiveSubscription': false});
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('구독 취소 실패: $e'));
    }
  }
} 