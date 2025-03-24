import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_document.freezed.dart';
part 'pdf_document.g.dart';

/// PDF 문서의 상태를 나타내는 열거형
enum PDFDocumentStatus {
  /// 초기 상태
  initial,
  /// 로딩 중
  loading,
  /// 로드됨
  loaded,
  /// 오류 발생
  error,
  /// 삭제됨
  deleted
}

/// PDF 문서의 중요도를 나타내는 열거형
enum PDFDocumentImportance {
  /// 낮음
  low,
  /// 중간
  medium,
  /// 높음
  high
}

/// PDF 문서의 보안 수준을 나타내는 열거형
enum PDFDocumentSecurityLevel {
  /// 비보안
  none,
  /// 기본 보안
  basic,
  /// 고급 보안
  advanced
}

/// PDF 문서 모델
@freezed
class PDFDocument with _$PDFDocument {
  const factory PDFDocument({
    /// 문서 고유 ID
    required String id,
    
    /// 문서 제목
    required String title,
    
    /// 파일 경로
    required String filePath,
    
    /// 파일 크기 (바이트)
    @Default(0) int fileSize,
    
    /// 총 페이지 수
    required int totalPages,
    
    /// 문서 설명
    String? description,
    
    /// 문서 상태
    @Default(PDFDocumentStatus.initial) PDFDocumentStatus status,
    
    /// 문서 중요도
    @Default(PDFDocumentImportance.medium) PDFDocumentImportance importance,
    
    /// 문서 보안 수준
    @Default(PDFDocumentSecurityLevel.none) PDFDocumentSecurityLevel securityLevel,
    
    /// 생성일시
    required DateTime createdAt,
    
    /// 수정일시
    required DateTime updatedAt,
    
    /// 마지막 접근일시
    DateTime? lastAccessedAt,
    
    /// 마지막 수정일시
    DateTime? lastModifiedAt,
    
    /// 문서 태그 목록
    @Default([]) List<String> tags,
    
    /// 문서 버전
    @Default(1) int version,
    
    /// 문서 암호화 여부
    @Default(false) bool isEncrypted,
    
    /// 문서 암호화 키
    String? encryptionKey,
    
    /// 문서 공유 여부
    @Default(false) bool isShared,
    
    /// 문서 공유 ID
    String? shareId,
    
    /// 문서 공유 URL
    String? shareUrl,
    
    /// 문서 공유 만료일시
    DateTime? shareExpiresAt,
    
    /// 문서 읽기 진행률 (0.0 ~ 1.0)
    @Default(0.0) double readingProgress,
    
    /// 마지막으로 읽은 페이지
    @Default(0) int lastReadPage,
    
    /// 총 읽기 시간 (초)
    @Default(0) int totalReadingTime,
    
    /// 마지막 읽기 시간 (초)
    @Default(0) int lastReadingTime,
    
    /// 문서 썸네일 URL
    String? thumbnailUrl,
    
    /// 문서 OCR 여부
    @Default(false) bool isOcrEnabled,
    
    /// 문서 OCR 언어
    String? ocrLanguage,
    
    /// 문서 OCR 상태
    String? ocrStatus,
    
    /// 문서 AI 요약 여부
    @Default(false) bool isSummarized,
    
    /// 문서 현재 페이지
    @Default(0) int currentPage,
    
    /// 문서 즐겨찾기 여부
    @Default(false) bool isFavorite,
  }) = _PDFDocument;

  /// JSON 직렬화/역직렬화를 위한 팩토리 생성자
  factory PDFDocument.fromJson(Map<String, dynamic> json) =>
      _$PDFDocumentFromJson(json);
} 