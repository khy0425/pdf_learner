import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../utils/non_web_stub.dart' if (dart.library.js) 'dart:js' as js;
import '../utils/non_web_stub.dart' if (dart.library.html) 'dart:html' as html;

/// 웹 및 모바일 환경에서 안전하게 데이터를 저장하는 클래스
class SecureStorage {
  // 싱글톤 패턴 구현
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();
  
  // 테스트용 생성자
  @visibleForTesting
  SecureStorage.forTesting();

  // 플랫폼별 스토리지 
  late final FlutterSecureStorage? _secureStorage;
  final bool _isWeb = kIsWeb;
  
  // 암호화 키 (실제 앱에서는 더 안전한 방식으로 관리)
  static const String _encryptionSalt = 'PDF_LEARNER_SECURE_SALT';
  
  /// 초기화 메서드
  Future<void> initialize() async {
    if (!_isWeb) {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
    }
    
    debugPrint('SecureStorage 초기화 완료: 웹 환경=$_isWeb');
  }
  
  /// 데이터 저장 메서드
  Future<void> saveSecureData(String key, String value) async {
    try {
      final encryptedValue = _encryptData(value);
      
      if (_isWeb) {
        // 웹 환경: HTTP-Only 쿠키 또는 sessionStorage 사용
        if (_isSensitiveKey(key)) {
          // 민감한 정보는 sessionStorage에 암호화하여 저장
          _setSessionStorageItem(key, encryptedValue);
          debugPrint('sessionStorage에 암호화된 데이터 저장: $key');
        } else {
          // 덜 민감한 정보는 localStorage에 저장
          _setLocalStorageItem(key, encryptedValue);
          debugPrint('localStorage에 암호화된 데이터 저장: $key');
        }
      } else {
        // 네이티브 환경: 보안 스토리지 사용
        await _secureStorage!.write(key: key, value: encryptedValue);
        debugPrint('보안 스토리지에 암호화된 데이터 저장: $key');
      }
    } catch (e) {
      debugPrint('데이터 저장 오류: $e');
      // 보안 스토리지 실패 시 SharedPreferences로 대체 (덜 안전함)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('secure_$key', _encryptData(value));
        debugPrint('SharedPreferences에 대체 저장: $key');
      } catch (e2) {
        debugPrint('대체 저장 실패: $e2');
        rethrow;
      }
    }
  }
  
  /// 데이터 조회 메서드
  Future<String?> getSecureData(String key) async {
    try {
      String? encryptedValue;
      
      if (_isWeb) {
        // 웹 환경
        if (_isSensitiveKey(key)) {
          // 민감한 정보는 sessionStorage에서 조회
          encryptedValue = _getSessionStorageItem(key);
        } else {
          // 덜 민감한 정보는 localStorage에서 조회
          encryptedValue = _getLocalStorageItem(key);
        }
      } else {
        // 네이티브 환경
        encryptedValue = await _secureStorage!.read(key: key);
      }
      
      // 암호화된 값이 없으면 null 반환
      if (encryptedValue == null || encryptedValue.isEmpty) {
        return null;
      }
      
      // 암호화된 값 복호화
      return _decryptData(encryptedValue);
    } catch (e) {
      debugPrint('보안 데이터 조회 오류: $e');
      
      // 대체 저장소에서 조회 시도
      try {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString('secure_$key');
        if (value != null && value.isNotEmpty) {
          return _decryptData(value);
        }
      } catch (e2) {
        debugPrint('대체 조회 실패: $e2');
      }
      
      return null;
    }
  }
  
  /// 데이터 삭제 메서드
  Future<void> deleteSecureData(String key) async {
    try {
      if (_isWeb) {
        // 웹 환경
        if (_isSensitiveKey(key)) {
          _removeSessionStorageItem(key);
        } else {
          _removeLocalStorageItem(key);
        }
        debugPrint('웹 스토리지에서 데이터 삭제: $key');
      } else {
        // 네이티브 환경
        await _secureStorage!.delete(key: key);
        debugPrint('보안 스토리지에서 데이터 삭제: $key');
      }
      
      // 대체 저장소에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
    } catch (e) {
      debugPrint('데이터 삭제 오류: $e');
      rethrow;
    }
  }
  
  /// 모든 데이터 삭제
  Future<void> deleteAllSecureData() async {
    try {
      if (_isWeb) {
        // 웹 환경
        _clearSessionStorage();
        _clearLocalStorage();
        _clearSecureCookies();
        debugPrint('모든 웹 스토리지 데이터 삭제됨');
      } else {
        // 네이티브 환경
        await _secureStorage!.deleteAll();
        debugPrint('모든 보안 스토리지 데이터 삭제됨');
      }
      
      // 대체 저장소 정리
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('secure_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('모든 데이터 삭제 오류: $e');
      rethrow;
    }
  }

  /// HTTP-Only 쿠키 설정 (XSS 공격 방지에 효과적)
  void setSecureCookie(String key, String value, {int expiryDays = 7}) {
    if (!_isWeb) return;
    
    try {
      final expiryDate = DateTime.now().add(Duration(days: expiryDays));
      final cookieValue = 
          '$key=$value; expires=${expiryDate.toUtc()}; path=/; Secure; HttpOnly; SameSite=Strict';
      
      js.context.callMethod('eval', [
        'document.cookie = "$cookieValue";'
      ]);
      
      debugPrint('보안 쿠키 설정됨: $key');
    } catch (e) {
      debugPrint('쿠키 설정 오류: $e');
    }
  }
  
  // ==================== 내부 헬퍼 메서드 ====================
  
  // sessionStorage 관련 메서드
  String? _getSessionStorageItem(String key) {
    try {
      return js.context['sessionStorage'].callMethod('getItem', [key]);
    } catch (e) {
      debugPrint('sessionStorage 조회 오류: $e');
      return null;
    }
  }
  
  void _setSessionStorageItem(String key, String value) {
    js.context['sessionStorage'].callMethod('setItem', [key, value]);
  }
  
  void _removeSessionStorageItem(String key) {
    js.context['sessionStorage'].callMethod('removeItem', [key]);
  }
  
  void _clearSessionStorage() {
    js.context['sessionStorage'].callMethod('clear');
  }
  
  // localStorage 관련 메서드
  String? _getLocalStorageItem(String key) {
    try {
      return js.context['localStorage'].callMethod('getItem', [key]);
    } catch (e) {
      debugPrint('localStorage 조회 오류: $e');
      return null;
    }
  }
  
  void _setLocalStorageItem(String key, String value) {
    js.context['localStorage'].callMethod('setItem', [key, value]);
  }
  
  void _removeLocalStorageItem(String key) {
    js.context['localStorage'].callMethod('removeItem', [key]);
  }
  
  void _clearLocalStorage() {
    js.context['localStorage'].callMethod('clear');
  }
  
  // 보안 쿠키 삭제
  void _clearSecureCookies() {
    try {
      final cookies = js.context['document']['cookie'].toString().split(';');
      for (var cookie in cookies) {
        final eqPos = cookie.indexOf('=');
        final name = eqPos > -1 ? cookie.substring(0, eqPos).trim() : cookie.trim();
        final expires = 'expires=Thu, 01 Jan 1970 00:00:00 GMT';
        js.context.callMethod('eval', [
          'document.cookie = "$name=; $expires; path=/;";'
        ]);
      }
    } catch (e) {
      debugPrint('쿠키 삭제 오류: $e');
    }
  }
  
  // 암호화 관련 메서드
  String _encryptData(String data) {
    try {
      // 고정된 키 생성 (실제 앱에서는 더 안전한 방식으로 키 관리 필요)
      final keyString = _generateKey();
      final key = encrypt.Key.fromUtf8(keyString);
      final iv = encrypt.IV.fromLength(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // IV와 암호화된 데이터를 함께 저장
      final combined = base64Encode(iv.bytes) + ':' + encrypted.base64;
      return combined;
    } catch (e) {
      debugPrint('암호화 오류: $e');
      // 암호화 실패 시 간단한 인코딩으로 대체 (권장하지 않음)
      return base64Encode(utf8.encode(_encryptionSalt + data));
    }
  }
  
  String _decryptData(String encryptedData) {
    try {
      // 결합된 데이터에서 IV와 암호화된 데이터 분리
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        // 단순 인코딩으로 저장된 경우
        final decoded = utf8.decode(base64Decode(encryptedData));
        if (decoded.startsWith(_encryptionSalt)) {
          return decoded.substring(_encryptionSalt.length);
        }
        return decoded;
      }
      
      final ivString = parts[0];
      final dataString = parts[1];
      
      final keyString = _generateKey();
      final key = encrypt.Key.fromUtf8(keyString);
      final iv = encrypt.IV.fromBase64(ivString);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt64(dataString, iv: iv);
      
      return decrypted;
    } catch (e) {
      debugPrint('복호화 오류: $e');
      // 복호화 실패 시 원본 반환
      return encryptedData;
    }
  }
  
  // 키 생성 메서드 (실제 앱에서는 더 안전한 방식으로 구현)
  String _generateKey() {
    const salt = _encryptionSalt;
    final deviceId = _getDeviceIdentifier();
    final keyData = utf8.encode(salt + deviceId);
    final keyHash = sha256.convert(keyData);
    return keyHash.toString().substring(0, 32); // AES-256 키는 32바이트
  }
  
  // 기기 식별자 획득 (실제 앱에서는 더 안전한 방식으로 구현)
  String _getDeviceIdentifier() {
    if (_isWeb) {
      try {
        final userAgent = js.context['navigator']['userAgent'].toString();
        return userAgent;
      } catch (e) {
        return 'web_device';
      }
    } else {
      return 'mobile_device';
    }
  }
  
  // 민감한 키 판별
  bool _isSensitiveKey(String key) {
    return key.contains('api_key') || 
           key.contains('token') || 
           key.contains('password') || 
           key.contains('auth') ||
           key.contains('secret');
  }
} 