class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        subscription: UserSubscription.free,
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  Future<void> upgradeSubscription() async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'subscription': UserSubscription.premium.name,
        'subscriptionExpiresAt': DateTime.now().add(
          const Duration(days: 30),
        ).toIso8601String(),
      });

      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
        createdAt: _currentUser!.createdAt,
        photoUrl: _currentUser!.photoUrl,
        subscription: UserSubscription.premium,
      );
      
      notifyListeners();
    } catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  Future<void> checkSubscriptionStatus() async {
    if (_currentUser == null) return;

    final doc = await _firestore.collection('users').doc(_currentUser!.id).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    if (data['subscriptionExpiresAt'] != null) {
      final expiresAt = DateTime.parse(data['subscriptionExpiresAt']);
      if (expiresAt.isBefore(DateTime.now())) {
        // 구독 만료
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'subscription': UserSubscription.free.name,
          'subscriptionExpiresAt': null,
        });
        _currentUser = User.fromMap(data)..subscription = UserSubscription.free;
        notifyListeners();
      }
    }
  }

  Exception _handleFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception('이미 사용 중인 이메일입니다');
        case 'invalid-email':
          return Exception('잘못된 이메일 형식입니다');
        case 'weak-password':
          return Exception('비밀번호가 너무 약합니다');
        // ... 기타 에러 처리
      }
    }
    return Exception('알 수 없는 오류가 발생했습니다');
  }
} 