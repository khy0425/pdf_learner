import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Flutter 테스트를 위한 초기화 함수
Future<void> setupTestEnvironment() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences 준비
  SharedPreferences.setMockInitialValues({});
  
  TestWidgetsFlutterBinding.ensureInitialized();
} 