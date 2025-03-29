import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/base/result.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/models/pdf_document.dart';
import 'firebase_service.dart';

/// Firebase 서비스 구현
@Injectable(as: FirebaseService)
class FirebaseServiceImpl implements FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GoogleSignIn _googleSignIn;
  
  final Uuid _uuid = const Uuid();
  
  FirebaseServiceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GoogleSignIn? googleSignIn,
  }) : 
    _auth = auth ?? FirebaseAuth.instance,
    _firestore = firestore ?? FirebaseFirestore.instance,
    _storage = storage ?? FirebaseStorage.instance,
    _googleSignIn = googleSignIn ?? GoogleSignIn();
  
  /// Firebase 서비스 초기화
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase가 이미 초기화된 경우에는 예외가 발생할 수 있으므로 무시
      print('Firebase 초기화 중 오류(무시 가능): $e');
    }
  }
  
  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  @override
  User? get currentUser => _auth.currentUser;
  
  @override
  String? get userId => _auth.currentUser?.uid;
  
  @override
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
  
  @override
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
  
  @override
  Future<Result<User>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
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
  
  @override
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
  
  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
  
  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Firestore 레퍼런스 메서드
  CollectionReference get _pdfsCollection => 
      _firestore.collection('pdf_documents');
  
  CollectionReference get _userPdfsCollection => 
      _firestore.collection('users/${userId ?? 'anonymous'}/pdf_documents');
  
  CollectionReference get _bookmarksCollection => 
      _firestore.collection('bookmarks');
  
  CollectionReference _userBookmarksForDocument(String documentId) => 
      _firestore.collection('users/${userId ?? 'anonymous'}/pdf_documents/$documentId/bookmarks');
  
  @override
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
  
  @override
  Future<Result<PDFDocument>> uploadPDFDocument(File file, PDFDocument document) async {
    try {
      final fileName = file.path.split('/').last;
      final storagePath = 'pdfs/${userId ?? 'anonymous'}/${document.id}/$fileName';
      
      // 파일 업로드
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 문서 정보 업데이트
      final updatedDocument = document.copyWith(
        url: downloadUrl,
        filePath: storagePath,
        updatedAt: DateTime.now(),
      );
      
      // Firestore에 저장
      return savePDFDocument(updatedDocument);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 업로드 실패: $e'));
    }
  }
  
  @override
  Future<Result<PDFDocument?>> getPDFDocument(String documentId) async {
    try {
      final doc = await _userPdfsCollection.doc(documentId).get();
      
      if (!doc.exists) {
        return Result.success(null);
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final document = PDFDocument.fromMap(data);
      
      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 문서 가져오기 실패: $e'));
    }
  }
  
  @override
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
  
  @override
  Future<Result<void>> deletePDFDocument(String documentId) async {
    try {
      // 문서 정보 가져오기
      final docResult = await getPDFDocument(documentId);
      
      if (docResult.isFailure) {
        return Result.failure(docResult.error!);
      }
      
      final document = docResult.data;
      
      if (document != null && document.filePath != null) {
        // 스토리지 파일 삭제
        try {
          await _storage.ref().child(document.filePath!).delete();
        } catch (e) {
          print('스토리지 파일 삭제 실패: $e');
        }
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
  
  Future<void> _deleteBookmarksForDocument(String documentId) async {
    try {
      final bookmarksSnapshot = await _userBookmarksForDocument(documentId).get();
      final batch = _firestore.batch();
      
      for (var doc in bookmarksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('북마크 삭제 실패: $e');
    }
  }
  
  @override
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark) async {
    try {
      final docRef = bookmark.id.isEmpty 
          ? _userBookmarksForDocument(bookmark.documentId).doc()
          : _userBookmarksForDocument(bookmark.documentId).doc(bookmark.id);
      
      final updatedBookmark = bookmark.copyWith(
        id: docRef.id,
        createdAt: bookmark.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(updatedBookmark.toMap());
      
      return Result.success(updatedBookmark);
    } catch (e) {
      return Result.failure(Exception('북마크 저장 실패: $e'));
    }
  }
  
  @override
  Future<Result<PDFBookmark?>> getBookmark(String bookmarkId) async {
    try {
      // 모든 문서를 검색하여 북마크 찾기 (비효율적, 실제 앱에서는 구조를 개선해야 함)
      final docsSnapshot = await _userPdfsCollection.get();
      
      for (var docDoc in docsSnapshot.docs) {
        final bookmarkDoc = await _userBookmarksForDocument(docDoc.id)
            .doc(bookmarkId).get();
            
        if (bookmarkDoc.exists) {
          final data = bookmarkDoc.data() as Map<String, dynamic>;
          return Result.success(PDFBookmark.fromMap(data));
        }
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('북마크 가져오기 실패: $e'));
    }
  }
  
  @override
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
  
  @override
  Future<Result<List<PDFBookmark>>> getAllBookmarks() async {
    try {
      final userId = this.userId;
      if (userId == null) {
        return Result.success([]);
      }
      
      // 사용자의 모든 문서를 가져온 다음 각 문서의 북마크를 조회
      final docSnapshot = await _userPdfsCollection.get();
      final bookmarks = <PDFBookmark>[];
      
      for (final doc in docSnapshot.docs) {
        final documentId = doc.id;
        final bookmarkSnapshot = await _userBookmarksForDocument(documentId).get();
        
        for (final bookmarkDoc in bookmarkSnapshot.docs) {
          final data = bookmarkDoc.data() as Map<String, dynamic>;
          final bookmark = PDFBookmark.fromMap(data);
          bookmarks.add(bookmark);
        }
      }
      
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(Exception('모든 북마크 가져오기 실패: $e'));
    }
  }
  
  @override
  Future<Result<bool>> deleteBookmark(String documentId, String bookmarkId) async {
    try {
      await _userBookmarksForDocument(documentId).doc(bookmarkId).delete();
      return Result.success(true);
    } catch (e) {
      return Result.failure(Exception('북마크 삭제 실패: $e'));
    }
  }
} 