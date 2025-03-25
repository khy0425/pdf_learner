import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../presentation/models/user_model.dart';
import '../../presentation/repositories/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'users';

  UserRepositoryImpl(this._firestore);

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    return getUser(id);
  }

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<UserModel?> getUserStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await saveUser(user);
  }
} 