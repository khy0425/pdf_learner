import 'package:uuid/uuid.dart';

/// 요약 길이 옵션
enum SummaryLength {
  short,  // 짧은 요약 (1-2문장)
  medium, // 중간 길이 요약 (3-5문장)
  long    // 긴 요약 (1-2단락)
}

/// 요약 스타일 옵션
enum SummaryStyle {
  standard,   // 표준 요약
  academic,   // 학술적 스타일
  simplified, // 쉬운 말로 풀어쓴 스타일
  bullet      // 불릿 포인트 리스트
}

/// AI 요약 모델
class AiSummary {
  final String id;
  final String documentId;
  final String summary;
  final String keywords;
  final String keyPoints;
  final int startPage;
  final int endPage;
  final DateTime createdAt;
  
  /// 생성자
  AiSummary({
    String? id,
    required this.documentId,
    required this.summary,
    required this.keywords,
    required this.keyPoints,
    required this.startPage,
    required this.endPage,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'summary': summary,
      'keywords': keywords,
      'keyPoints': keyPoints,
      'startPage': startPage,
      'endPage': endPage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// JSON에서 생성
  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      summary: json['summary'] as String,
      keywords: json['keywords'] as String,
      keyPoints: json['keyPoints'] as String,
      startPage: json['startPage'] as int,
      endPage: json['endPage'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  /// 복사본 생성
  AiSummary copyWith({
    String? id,
    String? documentId,
    String? summary,
    String? keywords,
    String? keyPoints,
    int? startPage,
    int? endPage,
    DateTime? createdAt,
  }) {
    return AiSummary(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      keyPoints: keyPoints ?? this.keyPoints,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// 키워드 목록을 문자열로 변환
  String get keywordsText {
    if (keywords.isEmpty) return '';
    return keywords;
  }
  
  /// 핵심 포인트 목록을 문자열로 변환
  String get keyPointsText {
    if (keyPoints.isEmpty) return '';
    return keyPoints;
  }
}

/// PDF 텍스트 추출 결과 모델
class PdfTextExtraction {
  final String documentId;
  final Map<int, String> pageTexts; // 페이지 번호와 해당 페이지 텍스트
  final DateTime extractedAt;
  
  PdfTextExtraction({
    required this.documentId,
    required this.pageTexts,
    DateTime? extractedAt,
  }) : extractedAt = extractedAt ?? DateTime.now();
  
  /// 전체 텍스트 가져오기
  String getFullText() {
    final entries = pageTexts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).join('\n\n');
  }
  
  /// 특정 페이지 범위의 텍스트 가져오기
  String getTextFromRange(int startPage, int endPage) {
    final entries = pageTexts.entries
      .where((e) => e.key >= startPage && e.key <= endPage)
      .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).join('\n\n');
  }
} 