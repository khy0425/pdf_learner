import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(
    this._auth,
    this._firestore,
    this._storage,
  );

  // 유저 상태 관련 getter
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
  String? get userId => currentUser?.uid;

  // Firestore 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get usersCollection => _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> getUserDocumentsCollection(String userId) {
    return usersCollection.doc(userId).collection('documents');
  }
  
  CollectionReference<Map<String, dynamic>> getUserBookmarksCollection(String userId) {
    return usersCollection.doc(userId).collection('bookmarks');
  }
  
  // 스토리지 참조
  Reference getUserStorageRef(String userId) {
    return _storage.ref().child('users/$userId');
  }
  
  Reference getPDFStorageRef(String userId, String documentId) {
    return getUserStorageRef(userId).child('pdfs/$documentId.pdf');
  }
  
  // 파일 업로드
  Future<String> uploadFile(String userId, String path, File file) async {
    try {
      final ref = _storage.ref().child('users/$userId/$path');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
  
  // 웹용 파일 업로드
  Future<String> uploadBytes(String userId, String path, Uint8List bytes, String contentType) async {
    try {
      final ref = _storage.ref().child('users/$userId/$path');
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
  
  // 파일 다운로드 URL 획득
  Future<String> getDownloadURL(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
  
  // 파일 삭제
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      rethrow;
    }
  }

  // PDF 문서 관련 메서드
  Future<List<PDFDocument>> getPDFDocuments() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    final snapshot = await getUserDocumentsCollection(user.uid).get();
    return snapshot.docs.map((doc) => PDFDocument.fromMap(doc.data())).toList();
  }
  
  Future<PDFDocument?> getPDFDocument(String id) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await getUserDocumentsCollection(user.uid).doc(id).get();
    if (!doc.exists) return null;
    
    return PDFDocument.fromMap(doc.data()!);
  }
  
  Future<void> addPDFDocument(PDFDocument document) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserDocumentsCollection(user.uid).doc(document.id).set(document.toMap());
  }
  
  Future<void> updatePDFDocument(PDFDocument document) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserDocumentsCollection(user.uid).doc(document.id).update(document.toMap());
  }
  
  Future<void> deletePDFDocument(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserDocumentsCollection(user.uid).doc(id).delete();
  }
  
  // 북마크 관련 메서드
  Future<List<PDFBookmark>> getBookmarks(String documentId) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    final snapshot = await getUserBookmarksCollection(user.uid)
        .where('documentId', isEqualTo: documentId)
        .get();
    return snapshot.docs.map((doc) => PDFBookmark.fromMap(doc.data())).toList();
  }
  
  Future<PDFBookmark?> getBookmark(String documentId, String bookmarkId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await getUserBookmarksCollection(user.uid).doc(bookmarkId).get();
    if (!doc.exists) return null;
    
    return PDFBookmark.fromMap(doc.data()!);
  }
  
  Future<void> addBookmark(PDFBookmark bookmark) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserBookmarksCollection(user.uid).doc(bookmark.id).set(bookmark.toMap());
  }
  
  Future<void> updateBookmark(PDFBookmark bookmark) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserBookmarksCollection(user.uid).doc(bookmark.id).update(bookmark.toMap());
  }
  
  Future<void> deleteBookmark(String documentId, String bookmarkId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    await getUserBookmarksCollection(user.uid).doc(bookmarkId).delete();
  }
  
  // PDF 파일 업로드/삭제
  Future<String> uploadPDFFile(Uint8List fileBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final filename = '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ref = _storage.ref().child('${user.uid}/pdfs/$filename');
    
    // Uint8List를 사용하여 업로드
    await ref.putData(fileBytes);
    return await ref.getDownloadURL();
  }
  
  Future<void> deletePDFFile(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    // Firebase Storage 참조에서 파일 경로 추출
    if (filePath.startsWith('gs://') || filePath.startsWith('http')) {
      final ref = _storage.refFromURL(filePath);
      await ref.delete();
    } else {
      // 상대 경로인 경우
      final ref = _storage.ref().child(filePath);
      await ref.delete();
    }
  }
} 