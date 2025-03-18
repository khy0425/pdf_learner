class EnvConfig {
  static String? getGeminiApiKey() {
    // .env 파일에서 API 키 로드
    return const String.fromEnvironment('GEMINI_API_KEY');
  }
  
  static String getGeminiApiEndpoint() {
    // Gemini API 엔드포인트 설정
    return 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  }
} 