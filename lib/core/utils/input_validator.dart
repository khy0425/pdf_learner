import 'package:flutter/foundation.dart';
import 'dart:convert';

/// API 키 유형
enum ApiKeyType {
  gemini,
  huggingFace,
  azure,
  firebase,
  custom,
}

/// 사용자 입력 유효성 검사를 담당하는 유틸리티 클래스
class InputValidator {
  /// 이메일 유효성 검사
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // 이메일 정규 표현식
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email);
  }
  
  /// 비밀번호 강도 검사
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.tooWeak;
    if (password.length < 8) return PasswordStrength.weak;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialChars) strength++;
    if (password.length > 12) strength++;
    
    switch (strength) {
      case 0:
      case 1:
        return PasswordStrength.tooWeak;
      case 2:
        return PasswordStrength.weak;
      case 3:
        return PasswordStrength.medium;
      case 4:
        return PasswordStrength.strong;
      default:
        return PasswordStrength.veryStrong;
    }
  }
  
  /// API 키가 유효한지 검증
  static bool isValidApiKey(String apiKey, ApiKeyType type) {
    if (apiKey.isEmpty) return false;
    
    switch (type) {
      case ApiKeyType.gemini:
        // Gemini API 키는 'AIzaSy'로 시작하는 Google Cloud API 키 형식
        return apiKey.startsWith('AIzaSy') && apiKey.length >= 30;
        
      case ApiKeyType.huggingFace:
        // Hugging Face API 키는 'hf_' 접두사로 시작
        return apiKey.startsWith('hf_') && apiKey.length >= 15;
        
      case ApiKeyType.azure:
        // Azure API 키는 GUID 형식이거나 긴 영숫자 문자열
        return apiKey.length >= 32 && RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(apiKey);
        
      case ApiKeyType.firebase:
        // Firebase API 키는 최소 30자, 영숫자 조합
        return apiKey.length >= 30 && RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(apiKey);
        
      default:
        // 기본 검증: 최소 길이와 허용 문자
        return apiKey.length >= 10 && RegExp(r'^[a-zA-Z0-9_\-\.]+$').hasMatch(apiKey);
    }
  }
  
  /// PDF 파일 경로 유효성 검사
  static bool isValidPdfPath(String path) {
    if (path.isEmpty) return false;
    
    // 확장자 검사
    if (!path.toLowerCase().endsWith('.pdf')) return false;
    
    // 경로 주입 공격 방지
    if (path.contains('..') || path.contains('//')) return false;
    
    // 웹 URL 검사 (http/https로 시작하는 경우)
    if (path.startsWith('http')) {
      try {
        final uri = Uri.parse(path);
        return uri.scheme == 'http' || uri.scheme == 'https';
      } catch (e) {
        debugPrint('유효하지 않은 URL: $e');
        return false;
      }
    }
    
    return true;
  }
  
  /// 보안 헤더 유효성 검사
  static bool isValidHeader(String key, String value) {
    // 금지된 헤더 키 목록
    final forbiddenKeys = [
      'cookie', 'authorization', 'proxy', 'sec-', 'host'
    ];
    
    // 금지된 헤더 값 패턴
    final forbiddenPatterns = [
      RegExp(r'<script>'), 
      RegExp(r'javascript:'),
      RegExp(r'data:text/html'),
      RegExp(r'base64'),
    ];
    
    // 금지된 헤더 키 검사
    final lowerKey = key.toLowerCase();
    if (forbiddenKeys.any((k) => lowerKey.contains(k))) {
      return false;
    }
    
    // 금지된 패턴 검사
    if (forbiddenPatterns.any((pattern) => pattern.hasMatch(value))) {
      return false;
    }
    
    return true;
  }
  
  /// JSON 데이터 유효성 검사
  static bool isValidJson(String jsonString) {
    if (jsonString.isEmpty) return false;
    
    try {
      json.decode(jsonString);
      return true;
    } catch (e) {
      debugPrint('유효하지 않은 JSON: $e');
      return false;
    }
  }
  
  /// 검색어 유효성 검사
  static bool isValidSearchQuery(String query) {
    if (query.isEmpty) return false;
    if (query.length < 2) return false;  // 최소 2자 이상
    
    // SQL 인젝션 방지를 위한 위험 패턴 검사
    final sqlInjectionPatterns = [
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\b', caseSensitive: false),
      RegExp(r'--'), 
      RegExp(r';'),
      RegExp(r'/\*'),
      RegExp(r'\*/'),
    ];
    
    if (sqlInjectionPatterns.any((pattern) => pattern.hasMatch(query))) {
      return false;
    }
    
    // XSS 방지를 위한 위험 패턴 검사
    final xssPatterns = [
      RegExp(r'<script>'), 
      RegExp(r'</script>'),
      RegExp(r'javascript:'),
      RegExp(r'onerror='),
      RegExp(r'onload='),
    ];
    
    if (xssPatterns.any((pattern) => pattern.hasMatch(query))) {
      return false;
    }
    
    return true;
  }
  
  /// 파일명 유효성 검사
  static bool isValidFilename(String filename) {
    if (filename.isEmpty) return false;
    
    // 금지된 문자 검사
    final forbiddenChars = RegExp(r'[<>:"/\\|?*]');
    if (forbiddenChars.hasMatch(filename)) return false;
    
    // 최대 길이 제한
    if (filename.length > 255) return false;
    
    return true;
  }
  
  /// 메시지 내용 유효성 검사 (채팅, 댓글 등)
  static bool isValidMessage(String message) {
    if (message.isEmpty) return false;
    
    // 메시지 길이 제한
    if (message.length > 5000) return false;
    
    // XSS 방지
    final scriptTags = RegExp(r'<script>.*?</script>', caseSensitive: false, dotAll: true);
    if (scriptTags.hasMatch(message)) return false;
    
    return true;
  }
  
  /// 사용자 입력 문자열 정제 (XSS 방지)
  static String sanitizeInput(String input) {
    if (input.isEmpty) return '';
    
    // HTML 태그 제거
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 위험한 문자 이스케이프
    sanitized = sanitized
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
    
    return sanitized;
  }
  
  /// URL 유효성 검사
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// 숫자 문자열 유효성 검사
  static bool isNumeric(String str) {
    return RegExp(r'^-?[0-9]+(\.[0-9]+)?$').hasMatch(str);
  }
  
  /// 파일 이름 유효성 검사
  static bool isValidFileName(String fileName) {
    if (fileName.isEmpty) return false;
    
    // 파일 이름에 허용되지 않는 문자 확인
    return !RegExp(r'[\\/:*?"<>|]').hasMatch(fileName);
  }
  
  /// 전화번호 유효성 검사
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    
    // 국제 전화번호 형식 확인 (국가코드 포함 가능)
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-()]'), ''));
  }
  
  /// 신용카드 번호 유효성 검사 (Luhn 알고리즘 사용)
  static bool isValidCreditCard(String cardNumber) {
    if (cardNumber.isEmpty) return false;
    
    // 공백, 대시 제거
    final digits = cardNumber.replaceAll(RegExp(r'[\s\-]'), '');
    
    // 16자리 숫자인지 확인
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(digits)) {
      return false;
    }
    
    // Luhn 알고리즘 적용
    int sum = 0;
    bool alternate = false;
    
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10 == 0);
  }
  
  /// 주소 유효성 검사 (기본적인 검사)
  static bool isValidAddress(String address) {
    return address.trim().length >= 5;
  }
  
  /// 사용자 이름 유효성 검사
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    
    // 사용자 이름 규칙: 3~20자, 영문자, 숫자, 밑줄, 하이픈만 허용
    return RegExp(r'^[a-zA-Z0-9_\-]{3,20}$').hasMatch(username);
  }
}

/// 비밀번호 강도 열거형
enum PasswordStrength {
  tooWeak,
  weak,
  medium,
  strong,
  veryStrong,
} 