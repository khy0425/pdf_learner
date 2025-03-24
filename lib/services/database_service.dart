import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  DatabaseService(this._firestore);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _firestore.collection('test').limit(1).get();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('데이터베이스 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  Future<void> createDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _firestore.collection(collection).doc(id).set(data);
    } catch (e) {
      debugPrint('문서 생성 실패: $e');
      rethrow;
    }
  }

  Future<void> updateDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      debugPrint('문서 업데이트 실패: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument({
    required String collection,
    required String id,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      debugPrint('문서 삭제 실패: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String id,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      return doc.data();
    } catch (e) {
      debugPrint('문서 조회 실패: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String id,
  }) {
    if (!_isInitialized) {
      throw Exception('데이터베이스 서비스가 초기화되지 않았습니다.');
    }

    return _firestore
        .collection(collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<List<Map<String, dynamic>>> getDocuments({
    required String collection,
    Query? query,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      var collectionRef = _firestore.collection(collection);
      if (query != null) {
        collectionRef = query;
      }

      final querySnapshot = await collectionRef.get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('문서 목록 조회 실패: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamDocuments({
    required String collection,
    Query? query,
  }) {
    if (!_isInitialized) {
      throw Exception('데이터베이스 서비스가 초기화되지 않았습니다.');
    }

    var collectionRef = _firestore.collection(collection);
    if (query != null) {
      collectionRef = query;
    }

    return collectionRef.snapshots().map((querySnapshot) =>
        querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> runTransaction(
    Future<void> Function(Transaction transaction) updateFunction,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _firestore.runTransaction(updateFunction);
    } catch (e) {
      debugPrint('트랜잭션 실행 실패: $e');
      rethrow;
    }
  }

  Future<void> batchWrite(
    Future<void> Function(WriteBatch batch) updateFunction,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final batch = _firestore.batch();
      await updateFunction(batch);
      await batch.commit();
    } catch (e) {
      debugPrint('배치 쓰기 실패: $e');
      rethrow;
    }
  }
} 