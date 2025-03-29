import 'dart:async';
import '../services/storage/secure_storage.dart';
import 'package:injectable/injectable.dart';

/// API 키 서비스
/// 
/// AI 서비스 API 키 관리를 담당합니다.
@lazySingleton
class ApiKeyService {
  /// API 키 저장 키
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyOpenAIApiKey = 'openai_api_key';
  
  /// Secure Storage
  final SecureStorage _secureStorage;

  /// 생성자
  ApiKeyService({
    required SecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  /// API 키 가져오기 (Gemini)
  Future<String?> getGeminiApiKey() async {
    return await _secureStorage.read(keyGeminiApiKey);
  }

  /// API 키 저장 (Gemini)
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _secureStorage.write(keyGeminiApiKey, apiKey);
  }

  /// API 키 가져오기 (OpenAI)
  Future<String?> getOpenAIApiKey() async {
    return await _secureStorage.read(keyOpenAIApiKey);
  }

  /// API 키 저장 (OpenAI)
  Future<void> saveOpenAIApiKey(String apiKey) async {
    await _secureStorage.write(keyOpenAIApiKey, apiKey);
  }

  /// API 키 삭제 (Gemini)
  Future<void> deleteGeminiApiKey() async {
    await _secureStorage.delete(keyGeminiApiKey);
  }

  /// API 키 삭제 (OpenAI)
  Future<void> deleteOpenAIApiKey() async {
    await _secureStorage.delete(keyOpenAIApiKey);
  }

  /// API 키 확인 (Gemini)
  Future<bool> hasGeminiApiKey() async {
    final apiKey = await getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// API 키 확인 (OpenAI)
  Future<bool> hasOpenAIApiKey() async {
    final apiKey = await getOpenAIApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// API 키 유효성 검사 (Gemini)
  Future<bool> validateGeminiApiKey(String apiKey) async {
    // TODO: 실제 API 키 유효성 검증 로직 구현
    return apiKey.length > 20;
  }

  /// API 키 유효성 검사 (OpenAI)
  Future<bool> validateOpenAIApiKey(String apiKey) async {
    // TODO: 실제 API 키 유효성 검증 로직 구현
    return apiKey.startsWith('sk-') && apiKey.length > 20;
  }
} 