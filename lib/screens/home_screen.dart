import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_service.dart';
import '../providers/tutorial_provider.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';
import 'home_page.dart';
import '../widgets/tutorial_overlay.dart';
import '../main.dart'; // 전역 인스턴스 접근을 위한 import
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:developer' as developer;
import '../services/web_firebase_initializer.dart';
import 'dart:js' as js;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  String _debugInfo = '';
  late final WebFirebaseInitializer _firebaseInitializer;
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('HomeScreen initState 호출됨');
    }
    
    // Firebase 초기화 객체 생성
    _firebaseInitializer = WebFirebaseInitializer();
    
    // 초기화 및 상태 리스너 설정
    _setupFirebaseListener();
    
    // 주기적으로 상태 확인 (백업)
    Future.delayed(const Duration(seconds: 2), _checkFirebaseStatus);
  }
  
  @override
  void dispose() {
    // 리스너 제거
    _firebaseInitializer.removeStateListener(_onFirebaseStateChanged);
    super.dispose();
  }
  
  void _setupFirebaseListener() {
    // 초기 상태 확인
    _checkFirebaseStatus();
    
    // 상태 변경 리스너 등록
    _firebaseInitializer.addStateListener(_onFirebaseStateChanged);
    
    if (kDebugMode) {
      print('Firebase 상태 리스너 등록됨');
    }
  }
  
  void _onFirebaseStateChanged(bool isInitialized, bool isUserLoggedIn, String? userId) {
    if (!mounted) return;
    
    final newDebugInfo = 'Firebase 초기화: $isInitialized, 로그인: $isUserLoggedIn, ID: $userId';
    
    if (kDebugMode) {
      print('Firebase 상태 변경: $newDebugInfo');
    }
    
    setState(() {
      _isLoggedIn = isUserLoggedIn;
      _debugInfo = newDebugInfo;
    });
  }
  
  void _checkFirebaseStatus() {
    if (!mounted || !kIsWeb) return;
    
    try {
      // JavaScript에서 상태 확인
      _firebaseInitializer.checkFirebaseStatusFromJS();
      
      // 로그인 상태 확인 후 화면 업데이트
      setState(() {
        _isLoggedIn = _firebaseInitializer.isUserLoggedIn;
        _debugInfo = 'Firebase 초기화: ${_firebaseInitializer.isInitialized}, 로그인: ${_firebaseInitializer.isUserLoggedIn}, ID: ${_firebaseInitializer.userId}';
      });
      
      if (kDebugMode) {
        print('Firebase 상태 수동 확인: $_debugInfo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase 상태 확인 오류: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('HomeScreen build: isLoggedIn = $_isLoggedIn');
    }

    // 가장 간단하고 선명한 색상의 UI로 변경
    return Container(
      color: Colors.yellow, // 아주 분명한 배경색
      child: Scaffold(
        backgroundColor: Colors.lightBlue.shade100, // 확실히 구분되는 색상
        appBar: AppBar(
          title: const Text('PDF Learner 앱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red, // 눈에 띄는 색상
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '앱이 정상적으로 로드되었습니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '이 텍스트가 보이면 Flutter가 제대로 작동 중입니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey.shade200,
                  child: Text(
                    '로그인 상태: ${_isLoggedIn ? '로그인됨' : '로그아웃됨'}',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isLoggedIn ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _checkFirebaseStatus,
                      child: const Text('상태 새로고침'),
                    ),
                    const SizedBox(width: 16),
                    if (_isLoggedIn)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        },
                        child: const Text('PDF 목록 보기'),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        },
                        child: const Text('로그인하기'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 