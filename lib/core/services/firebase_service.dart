import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:universal_html/html.dart' as html;
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'package:pdf_learner_v2/domain/models/user_model.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';

@Injectable()
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(this._auth, this._firestore, this._storage);

  // 초기화
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // 인증 관련 메서드
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Firestore 관련 메서드
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // PDF 문서 관련 메서드
  Future<void> createDocument(PDFDocument document) async {
    await _firestore.collection('documents').doc(document.id).set(document.toJson());
  }

  Future<void> updateDocument(PDFDocument document) async {
    await _firestore.collection('documents').doc(document.id).update(document.toJson());
  }

  Future<void> deleteDocument(String documentId) async {
    await _firestore.collection('documents').doc(documentId).delete();
  }

  Future<PDFDocument?> getDocument(String documentId) async {
    final doc = await _firestore.collection('documents').doc(documentId).get();
    if (doc.exists) {
      return PDFDocument.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<List<PDFDocument>> getDocuments() {
    return _firestore
        .collection('documents')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PDFDocument.fromJson(doc.data()))
            .toList());
  }

  // 북마크 관련 메서드
  Future<void> createBookmark(PDFBookmark bookmark) async {
    await _firestore.collection('bookmarks').doc(bookmark.id).set(bookmark.toJson());
  }

  Future<void> updateBookmark(PDFBookmark bookmark) async {
    await _firestore.collection('bookmarks').doc(bookmark.id).update(bookmark.toJson());
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _firestore.collection('bookmarks').doc(bookmarkId).delete();
  }

  Future<PDFBookmark?> getBookmark(String bookmarkId) async {
    final doc = await _firestore.collection('bookmarks').doc(bookmarkId).get();
    if (doc.exists) {
      return PDFBookmark.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<List<PDFBookmark>> getBookmarks(String documentId) {
    return _firestore
        .collection('bookmarks')
        .where('documentId', isEqualTo: documentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PDFBookmark.fromJson(doc.data()))
            .toList());
  }

  // Storage 관련 메서드
  Future<String> uploadPDFFile(String filePath, String fileName, {Uint8List? bytes}) async {
    final ref = _storage.ref().child('pdfs/$fileName');
    
    if (bytes != null) {
      // 웹 환경인 경우 바이트 데이터 업로드
      await ref.putData(bytes);
    } else {
      // 네이티브 환경인 경우 파일 업로드
      final file = File(filePath);
      await ref.putFile(file);
    }
    
    return await ref.getDownloadURL();
  }

  Future<void> deletePDFFile(String fileUrl) async {
    final ref = _storage.refFromURL(fileUrl);
    await ref.delete();
  }

  // 유틸리티 메서드
  UserModel? _userCredentialToUserModel(UserCredential? credential) {
    if (credential?.user == null) return null;
    
    final user = credential!.user!;
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      settings: UserSettings.createDefault(),
    );
  }
} 