import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  UserModel _currentUser = UserModel.guest();
  bool _isLoading = false;
  String? _error;
  
  UserModel get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isPremiumUser => _currentUser.isPremium;
  
  AuthService() {
    _initializeAuthListener();
  }
  
  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = UserModel.guest();
        notifyListeners();
        return;
      }
      
      await _loadUserData(user.uid);
    });
  }
  
  Future<void> _loadUserData(String userId) async {
    try {
      _setLoading(true);
      
      // Firestore에서
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        // 저장된 사용자 정보 로드
        final userData = doc.data() as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(userData);
      } else {
        // 신규 사용자 생성
        final user = _auth.currentUser!;
        _currentUser = UserModel(
          id: user.uid,
          email: user.email,
          name: user.displayName ?? '사용자',
          role: UserRole.free, // 기본적으로 무료 회원으로 설정
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        // Firestore에 저장
        await _firestore.collection('users').doc(userId).set(_currentUser.toMap());
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 데이터 로드 중 오류: $e');
      _currentUser = UserModel.guest();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result.user != null;
    } catch (e) {
      debugPrint('이메일 로그인 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      _setLoading(true);
      
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // 사용자 정보 업데이트
        await result.user!.updateDisplayName(name);
        
        // Firestore에 저장
        final newUser = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          role: UserRole.free,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final result = await _auth.signInWithCredential(credential);
      
      if (result.user != null && result.additionalUserInfo?.isNewUser == true) {
        // 신규 사용자 정보 저장
        final newUser = UserModel(
          id: result.user!.uid,
          email: result.user!.email,
          name: result.user!.displayName ?? '사용자',
          role: UserRole.free,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
      }
      
      return result.user != null;
    } catch (e) {
      debugPrint('구글 로그인 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> upgradeToPayment({String planType = 'premium'}) async {
    // 여기에 실제 결제 로직 구현
    // 결제 성공시 사용자 역할을 설정한 구독 플랜으로 변경
    try {
      _setLoading(true);
      
      if (!isLoggedIn) return false;
      
      // 결제 처리 성공을 가정
      final userId = _auth.currentUser!.uid;
      
      // 구독 만료일 설정 (30일 후)
      final subscriptionEndDate = DateTime.now().add(const Duration(days: 30));
      
      // 플랜 타입에 따라 사용자 역할 설정
      UserRole userRole;
      if (planType == 'basic') {
        userRole = UserRole.basic;
      } else {
        userRole = UserRole.premium;
      }
      
      // 사용자 정보 업데이트
      _currentUser = _currentUser.copyWith(
        role: userRole,
        subscriptionEndDate: subscriptionEndDate,
        planType: planType,
      );
      
      // Firestore에 저장
      await _firestore.collection('users').doc(userId).update({
        'role': userRole.toString(),
        'subscriptionEndDate': subscriptionEndDate.millisecondsSinceEpoch,
        'planType': planType,
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('유료회원 업그레이드 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> checkSubscription() async {
    try {
      if (!isLoggedIn) return false;
      
      final userId = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return false;
      
      final userData = doc.data() as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);
      
      _currentUser = userModel;
      notifyListeners();
      
      return userModel.isPremium;
    } catch (e) {
      debugPrint('구독 확인 오류: $e');
      return false;
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  Future<void> updateApiKey(String apiKey) async {
    try {
      if (_currentUser == null) throw Exception('로그인이 필요합니다.');
      
      await _saveApiKey(_currentUser!.uid, apiKey);
      notifyListeners();
    } catch (e) {
      print('API 키 업데이트 오류: $e');
      _error = 'API 키 업데이트에 실패했습니다.';
      notifyListeners();
    }
  }
  
  Future<void> _saveApiKey(String userId, String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apiKey_$userId', apiKey);
    } catch (e) {
      print('API 키 저장 오류: $e');
      throw Exception('API 키 저장 실패: $e');
    }
  }
  
  Future<String?> getStoredApiKey() async {
    try {
      if (_currentUser == null) return null;
      return await _getApiKey(_currentUser!.uid);
    } catch (e) {
      print('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  Future<String?> _getApiKey(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('apiKey_$userId');
    } catch (e) {
      print('API 키 불러오기 오류: $e');
      return null;
    }
  }
  
  Future<void> _saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_${user.uid}',
        JsonEncoder().convert(user.toJson())
      );
    } catch (e) {
      print('사용자 정보 저장 오류: $e');
      throw Exception('사용자 정보 저장 실패: $e');
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
} 