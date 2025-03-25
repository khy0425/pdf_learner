import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

/// Firebase 서비스를 제공하는 클래스
@singleton
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  @factoryMethod
  static FirebaseService create() {
    return FirebaseService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      FirebaseStorage.instance,
    );
  }
  
  FirebaseService(this._auth, this._firestore, this._storage);
  
  /// Firebase Auth 인스턴스
  FirebaseAuth get auth => _auth;
  
  /// Firebase Firestore 인스턴스
  FirebaseFirestore get firestore => _firestore;
  
  /// Firebase Storage 인스턴스
  FirebaseStorage get storage => _storage;
  
  /// 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  /// 사용자 ID
  String? get userId => currentUser?.uid;
  
  /// 인증 상태
  bool get isAuthenticated => currentUser != null;
  
  /// 이메일 인증 여부
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
  
  /// 이메일
  String? get email => currentUser?.email;
  
  /// 이름
  String? get displayName => currentUser?.displayName;
  
  /// 프로필 사진 URL
  String? get photoUrl => currentUser?.photoURL;
  
  /// 전화번호
  String? get phoneNumber => currentUser?.phoneNumber;
  
  /// 마지막 로그인 일시
  DateTime? get lastSignInTime => currentUser?.metadata.lastSignInTime;
  
  /// 계정 생성 일시
  DateTime? get creationTime => currentUser?.metadata.creationTime;

  /// Firestore 컬렉션 참조 가져오기
  CollectionReference<Map<String, dynamic>> getCollection(String path) {
    return _firestore.collection(path);
  }

  /// Firestore 문서 참조 가져오기
  DocumentReference<Map<String, dynamic>> getDocument(String path) {
    return _firestore.doc(path);
  }

  /// Storage 참조 가져오기
  Reference getStorageRef(String path) {
    return _storage.ref().child(path);
  }

  /// Storage URL 가져오기
  Future<String> getStorageUrl(String path) async {
    return await _storage.ref().child(path).getDownloadURL();
  }

  /// Storage 파일 업로드
  Future<String> uploadFile(String path, List<int> bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  /// Storage 파일 삭제
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  /// Firestore 배치 작업 시작
  WriteBatch startBatch() {
    return _firestore.batch();
  }

  /// Firestore 트랜잭션 시작
  Future<T> runTransaction<T>(Future<T> Function(Transaction) action) {
    return _firestore.runTransaction(action);
  }

  /// Firestore 쿼리 생성
  Query<Map<String, dynamic>> createQuery({
    required String collection,
    String? orderBy,
    bool? descending,
    int? limit,
    DocumentSnapshot? startAfter,
    DocumentSnapshot? endBefore,
    List<dynamic>? whereClauses,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending ?? false);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (endBefore != null) {
      query = query.endBeforeDocument(endBefore);
    }

    if (whereClauses != null) {
      for (final clause in whereClauses) {
        if (clause is WhereClause) {
          query = query.where(
            clause.field,
            isEqualTo: clause.value,
          );
        }
      }
    }

    return query;
  }
}

/// Firestore Where 절 클래스
class WhereClause {
  final String field;
  final dynamic value;

  WhereClause(this.field, this.value);
} 