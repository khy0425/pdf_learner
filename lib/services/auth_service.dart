import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _db;

  AuthService(this._db);

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일 회원가입
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 소셜 로그인
  Future<UserCredential> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    return _auth.signInWithPopup(googleProvider);
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

    _auth.currentUser = User.fromMap(userMap);
  }

  Future<void> signOut() {
    _auth.signOut();
  }

  // 사용자 데이터 관리
  Stream<User?> get authStateChanges => Stream.fromIterable([_auth.currentUser]);
} 