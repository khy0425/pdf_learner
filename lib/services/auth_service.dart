class AuthService extends ChangeNotifier {
  User? _currentUser;
  final DatabaseHelper _db;

  AuthService(this._db);

  User? get currentUser => _currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // 이메일 중복 체크
    final existing = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) {
      throw Exception('이미 사용 중인 이메일입니다');
    }

    // 비밀번호 해시화
    final salt = generateSalt();
    final hashedPassword = hashPassword(password, salt);

    // 사용자 생성
    final user = User(
      id: const Uuid().v4(),
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    // DB에 저장
    await _db.insert('users', {
      ...user.toMap(),
      'password': hashedPassword,
      'salt': salt,
    });

    _currentUser = user;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isEmpty) {
      throw Exception('이메일 또는 비밀번호가 잘못되었습니다');
    }

    final userMap = results.first;
    final storedHash = userMap['password'] as String;
    final salt = userMap['salt'] as String;

    if (hashPassword(password, salt) != storedHash) {
      throw Exception('이메일 또는 비밀번호가 잘못되었습니다');
    }

    _currentUser = User.fromMap(userMap);
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }
} 