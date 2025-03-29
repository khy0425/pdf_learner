import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_summary.freezed.dart';
part 'ai_summary.g.dart';

/// AI 요약 결과 모델
@freezed
class AiSummary with _$AiSummary {
  /// 생성자
  const factory AiSummary({
    /// 고유 식별자
    required String id,
    
    /// 문서 ID
    required String documentId,
    
    /// 요약 내용
    required String content,
    
    /// 요약 제목
    String? title,
    
    /// 생성일
    required DateTime createdAt,
    
    /// 시작 페이지
    required int startPage,
    
    /// 종료 페이지
    required int endPage,
    
    /// 요약 길이
    @Default('medium') String length,
  }) = _AiSummary;
  
  /// JSON에서 변환
  factory AiSummary.fromJson(Map<String, dynamic> json) => _$AiSummaryFromJson(json);
}

/// 요약 길이 옵션
enum SummaryLength {
  /// 짧은 요약
  short,
  
  /// 중간 길이 요약
  medium,
  
  /// 긴 요약
  long,
}

/// 요약 길이 확장 메서드
extension SummaryLengthExtension on SummaryLength {
  /// 문자열로 변환
  String get value {
    switch (this) {
      case SummaryLength.short:
        return 'short';
      case SummaryLength.medium:
        return 'medium';
      case SummaryLength.long:
        return 'long';
      default:
        return 'medium';
    }
  }
  
  /// 표시명
  String get displayName {
    switch (this) {
      case SummaryLength.short:
        return '짧게';
      case SummaryLength.medium:
        return '보통';
      case SummaryLength.long:
        return '자세히';
      default:
        return '보통';
    }
  }
} 