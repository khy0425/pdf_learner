/// 요약 옵션 열거형
enum SummarizeOption {
  /// 짧은 요약
  /// 핵심 내용만 간략하게 요약합니다. (1-2문장)
  short,
  
  /// 일반 요약
  /// 표준 길이의 요약을 생성합니다. (3-4문장)
  normal,
  
  /// 상세 요약
  /// 주요 내용을 자세하게 요약합니다. (5-6문장)
  detailed,
  
  /// 글머리 기호 요약
  /// 주요 내용을 글머리 기호 목록으로 요약합니다.
  bullets
}

/// 요약 옵션 확장 메서드
extension SummarizeOptionExtension on SummarizeOption {
  /// 요약 옵션을 문자열로 변환
  String get displayName {
    switch (this) {
      case SummarizeOption.short:
        return '짧게';
      case SummarizeOption.normal:
        return '표준';
      case SummarizeOption.detailed:
        return '자세히';
      case SummarizeOption.bullets:
        return '글머리 기호';
    }
  }
  
  /// 요약 옵션 설명
  String get description {
    switch (this) {
      case SummarizeOption.short:
        return '핵심 내용만 간략하게 요약합니다. (1-2문장)';
      case SummarizeOption.normal:
        return '표준 길이의 요약을 생성합니다. (3-4문장)';
      case SummarizeOption.detailed:
        return '주요 내용을 자세하게 요약합니다. (5-6문장)';
      case SummarizeOption.bullets:
        return '주요 내용을 글머리 기호 목록으로 요약합니다.';
    }
  }
  
  /// 요약 옵션 아이콘
  String get icon {
    switch (this) {
      case SummarizeOption.short:
        return '✓';
      case SummarizeOption.normal:
        return '✓✓';
      case SummarizeOption.detailed:
        return '✓✓✓';
      case SummarizeOption.bullets:
        return '•';
    }
  }
} 