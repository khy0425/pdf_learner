/// AI 서비스 옵션
enum AIModelType {
  /// GPT 모델
  gpt,
  
  /// 대화 모델
  chat,
  
  /// 요약 모델
  summarize,
  
  /// 번역 모델
  translate,
  
  /// 질문-응답 모델
  qa
}

/// 요약 옵션
enum SummarizeOption {
  /// 짧게
  short,
  
  /// 중간
  medium,
  
  /// 길게
  long,
  
  /// 키워드
  keywords,
  
  /// 주요 개념
  concepts
}

/// AI 서비스 인터페이스
class AiService {
  /// API 키 확인
  Future<bool> verifyApiKey(String apiKey) async {
    return true;
  }
  
  /// 문서와 채팅
  Future<String> chatWithDocument({
    required String documentId,
    required String message,
    AIModelType modelType = AIModelType.chat,
    Map<String, dynamic>? options,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(milliseconds: 500));
    return "안녕하세요! 문서에 대해 무엇을 도와드릴까요?";
  }
  
  /// 문서 요약
  Future<String> summarizeDocument({
    required String documentId,
    SummarizeOption option = SummarizeOption.medium,
    int? maxLength,
    String? language,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(seconds: 1));
    return "이 문서는 PDF에 관한 내용을 다루고 있습니다. 주요 내용으로는...";
  }
  
  /// 질문에 답변
  Future<String> answerQuestion({
    required String documentId,
    required String question,
    AIModelType modelType = AIModelType.qa,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(milliseconds: 800));
    return "질문에 대한 답변은 문서의 내용에 따르면...";
  }
  
  /// 텍스트 번역
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(milliseconds: 300));
    return "번역된 텍스트입니다.";
  }
  
  /// 텍스트 분석
  Future<Map<String, dynamic>> analyzeText({
    required String text,
    List<String>? analysisTypes,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      "sentiment": "positive",
      "keywords": ["PDF", "문서", "학습"],
      "entities": ["PDF", "문서"],
      "language": "ko"
    };
  }
  
  /// 문서 검색
  Future<List<Map<String, dynamic>>> searchInDocument({
    required String documentId,
    required String query,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      {"page": 1, "text": "검색어와 관련된 첫 번째 결과", "score": 0.95},
      {"page": 5, "text": "검색어와 관련된 두 번째 결과", "score": 0.82},
    ];
  }
  
  /// 퀴즈 생성
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String documentId,
    int count = 5,
    String? difficulty,
  }) async {
    // 실제 API 연동 대신 간단한 응답 생성
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        "question": "PDF의 전체 이름은 무엇인가요?",
        "options": ["Portable Document Format", "Personal Document File", "Public Document Framework", "Print Document File"],
        "answer": 0
      },
      {
        "question": "PDF 파일의 일반적인 확장자는 무엇인가요?",
        "options": [".pdf", ".doc", ".txt", ".ppt"],
        "answer": 0
      }
    ];
  }
} 