import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../core/base/result.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/models/pdf_document.dart';

/// Firebase 서비스 인터페이스
abstract class FirebaseService {
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges;
  
  /// 현재 사용자
  User? get currentUser;
  
  /// 현재 사용자 ID
  String? get userId;
  
  /// 이메일/비밀번호로 로그인
  Future<Result<User>> signInWithEmailAndPassword(String email, String password);
  
  /// 이메일/비밀번호로 회원가입
  Future<Result<User>> signUpWithEmailAndPassword(String email, String password);
  
  /// 구글로 로그인
  Future<Result<User>> signInWithGoogle();
  
  /// 익명으로 로그인
  Future<Result<User>> signInAnonymously();
  
  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);
  
  /// 로그아웃
  Future<void> signOut();
  
  /// PDF 문서 저장
  Future<Result<PDFDocument>> savePDFDocument(PDFDocument document);
  
  /// PDF 문서 업로드
  Future<Result<PDFDocument>> uploadPDFDocument(File file, PDFDocument document);
  
  /// PDF 문서 가져오기
  Future<Result<PDFDocument?>> getPDFDocument(String documentId);
  
  /// PDF 문서 목록 가져오기
  Future<Result<List<PDFDocument>>> getPDFDocuments();
  
  /// PDF 문서 삭제
  Future<Result<void>> deletePDFDocument(String documentId);
  
  /// 북마크 저장
  Future<Result<PDFBookmark>> saveBookmark(PDFBookmark bookmark);
  
  /// 북마크 가져오기
  Future<Result<PDFBookmark?>> getBookmark(String bookmarkId);
  
  /// 문서의 북마크 목록 가져오기
  Future<Result<List<PDFBookmark>>> getBookmarksForDocument(String documentId);
  
  /// 사용자의 모든 북마크 가져오기
  Future<Result<List<PDFBookmark>>> getAllBookmarks();
  
  /// 북마크 삭제
  Future<Result<bool>> deleteBookmark(String documentId, String bookmarkId);
} 