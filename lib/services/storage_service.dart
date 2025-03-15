import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';

class StorageService {
  // Firebase 서비스 인스턴스
  FirebaseStorage? _storage;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  
  // 초기화 상태 추적
  bool _isInitialized = false;
  
  // 생성자에서 안전하게 초기화
  StorageService() {
    if (kDebugMode) {
      print('🟢 [StorageService] 생성자 호출됨');
    }
    
    _initializeAsync();
  }
  
  // 비동기 초기화 메서드
  Future<void> _initializeAsync() async {
    try {
      if (kDebugMode) {
        print('🟢 [StorageService] 초기화 시작');
      }
      
      // Firebase가 이미 초기화되었는지 확인
      if (!Firebase.apps.isEmpty) {
        if (kDebugMode) {
          print('🟢 [StorageService] Firebase가 이미 초기화됨');
        }
      } else {
        if (kDebugMode) {
          print('🟠 [StorageService] Firebase가 아직 초기화되지 않음');
        }
      }
      
      // 안전하게 인스턴스 가져오기
      _storage = FirebaseStorage.instance;
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🟢 [StorageService] 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] 초기화 오류: $e');
      }
      _isInitialized = false;
    }
  }
  
  // 서비스가 초기화되었는지 확인
  bool get isInitialized => _isInitialized;
  
  // Firebase Storage 인스턴스 안전하게 가져오기
  FirebaseStorage get storage {
    if (_storage == null) {
      if (kDebugMode) {
        print('🟠 [StorageService] FirebaseStorage 인스턴스 재시도');
      }
      try {
        _storage = FirebaseStorage.instance;
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [StorageService] FirebaseStorage 인스턴스 가져오기 실패: $e');
        }
        throw Exception('FirebaseStorage를 초기화할 수 없습니다: $e');
      }
    }
    return _storage!;
  }
  
  // Firestore 인스턴스 안전하게 가져오기
  FirebaseFirestore get firestore {
    if (_firestore == null) {
      if (kDebugMode) {
        print('🟠 [StorageService] FirebaseFirestore 인스턴스 재시도');
      }
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [StorageService] FirebaseFirestore 인스턴스 가져오기 실패: $e');
        }
        throw Exception('FirebaseFirestore를 초기화할 수 없습니다: $e');
      }
    }
    return _firestore!;
  }
  
  // Auth 인스턴스 안전하게 가져오기
  FirebaseAuth get auth {
    if (_auth == null) {
      if (kDebugMode) {
        print('🟠 [StorageService] FirebaseAuth 인스턴스 재시도');
      }
      try {
        _auth = FirebaseAuth.instance;
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [StorageService] FirebaseAuth 인스턴스 가져오기 실패: $e');
        }
        throw Exception('FirebaseAuth를 초기화할 수 없습니다: $e');
      }
    }
    return _auth!;
  }
  
  // 현재 사용자 ID 가져오기
  String? get currentUserId {
    try {
      return auth.currentUser?.uid;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] 현재 사용자 ID 가져오기 오류: $e');
      }
      return null;
    }
  }
  
  // PDF 파일을 Firebase Storage에 업로드
  Future<String?> uploadPdf(String fileName, Uint8List bytes, {String? userId}) async {
    try {
      // 사용자 ID 확인
      final uid = userId ?? currentUserId;
      if (uid == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // 업로드 경로 생성 (사용자 ID 별로 폴더 구분)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'pdfs/$uid/$timestamp\_$fileName';
      final storageRef = storage.ref().child(path);
      
      // 파일 업로드
      await storageRef.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
      
      // 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Firestore에 메타데이터 저장
      await _saveMetadataToFirestore(uid, fileName, downloadUrl, bytes.length, timestamp);
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] PDF 업로드 오류: $e');
      }
      return null;
    }
  }
  
  // Firestore에 PDF 메타데이터 저장
  Future<void> _saveMetadataToFirestore(
    String userId, 
    String fileName, 
    String downloadUrl, 
    int size, 
    int timestamp
  ) async {
    try {
      await firestore.collection('pdf_files').add({
        'userId': userId,
        'fileName': fileName,
        'url': downloadUrl,
        'size': size,
        'createdAt': timestamp,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] PDF 메타데이터 저장 오류: $e');
      }
    }
  }
  
  // 사용자의 모든 PDF 파일 메타데이터 가져오기
  Future<List<Map<String, dynamic>>> getUserPdfFiles(String userId) async {
    try {
      if (kDebugMode) {
        print('🟢 [StorageService] ${userId}의 PDF 파일 가져오기 시작');
      }
      
      final snapshot = await firestore
          .collection('pdf_files')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      final result = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Firestore 문서 ID 추가
        return data;
      }).toList();
      
      if (kDebugMode) {
        print('🟢 [StorageService] ${result.length}개의 PDF 파일 가져옴');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] PDF 목록 가져오기 오류: $e');
      }
      return [];
    }
  }
  
  // Firebase Storage에서 PDF 파일 다운로드
  Future<Uint8List?> downloadPdf(String url) async {
    try {
      if (url.startsWith('http')) {
        // HTTP URL인 경우 다운로드
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } else {
        // Firebase Storage 참조인 경우
        final storageRef = storage.ref(url);
        final data = await storageRef.getData();
        return data;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] PDF 다운로드 오류: $e');
      }
    }
    return null;
  }
  
  // PDF 파일 삭제
  Future<bool> deletePdf(String url, String firestoreId) async {
    try {
      // Firestore에서 메타데이터 삭제
      await firestore.collection('pdf_files').doc(firestoreId).delete();
      
      // Storage에서 파일 삭제
      if (url.contains('firebasestorage.googleapis.com')) {
        // URL에서 파일 경로 추출
        final path = Uri.parse(url).path;
        final segments = path.split('/');
        const prefixToRemove = '/o/';
        const suffixToRemove = '?alt=media';
        
        // /o/ 다음의 경로 추출하고 URL 디코딩
        final encodedFilePath = path.substring(
          path.indexOf(prefixToRemove) + prefixToRemove.length,
          path.indexOf(suffixToRemove)
        );
        final filePath = Uri.decodeComponent(encodedFilePath);
        
        // 파일 삭제
        await storage.ref(filePath).delete();
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [StorageService] PDF 삭제 오류: $e');
      }
      return false;
    }
  }
  
  // PDF가 전체 경로인지 확인
  bool isPdfUrlComplete(String? url) {
    return url != null && url.startsWith('http');
  }
} 