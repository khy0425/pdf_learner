import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_bookmark.freezed.dart';
part 'pdf_bookmark.g.dart';

/// PDF 북마크 모델
/// 
/// PDF 문서의 특정 페이지에 대한 북마크 정보를 관리합니다.
@freezed
class PDFBookmark with _$PDFBookmark {
  const factory PDFBookmark({
    /// 북마크 고유 ID
    required String id,
    
    /// 문서 ID
    required String documentId,
    
    /// 페이지 번호
    required int pageNumber,
    
    /// 북마크 제목
    required String title,
    
    /// 북마크 설명
    String? description,
    
    /// 생성일시
    required DateTime createdAt,
    
    /// 마지막 접근일시
    DateTime? lastAccessedAt,
    
    /// 북마크 태그 목록
    @Default([]) List<String> tags,
    
    /// 북마크 색상
    @Default('#FFEB3B') String color,
    
    /// 북마크 위치 (페이지 내 Y 좌표)
    @Default(0.0) double position,
    
    /// 북마크 텍스트 선택 영역
    String? selectedText,
    
    /// 북마크 노트
    String? note,
    
    /// 북마크 중요도 (1-5)
    @Default(3) int importance,
  }) = _PDFBookmark;

  /// JSON 직렬화/역직렬화를 위한 팩토리 생성자
  factory PDFBookmark.fromJson(Map<String, dynamic> json) =>
      _$PDFBookmarkFromJson(json);
}

/// PDF 북마크 확장 메서드
extension PDFBookmarkX on PDFBookmark {
  /// 북마크가 유효한지 검사합니다.
  bool isValid() {
    return id.isNotEmpty &&
           documentId.isNotEmpty &&
           pageNumber > 0 &&
           createdAt.isBefore(DateTime.now()) &&
           createdAt.isBefore(lastAccessedAt) &&
           (DateTime.now().difference(lastAccessedAt ?? DateTime.now())).inMinutes <= 5;
  }
  
  /// 북마크가 활성 상태인지 검사합니다.
  bool isActive() {
    return isValid();
  }
  
  /// 북마크의 공유 상태를 확인합니다.
  bool isSharedAndValid() {
    return false; // 공유 기능 제거
  }
  
  /// 북마크의 공유 권한을 확인합니다.
  bool hasPermission(String permission) {
    return false; // 공유 기능 제거
  }
  
  /// 북마크의 색상을 ARGB 형식의 문자열로 반환합니다.
  String get colorString {
    if (color.isEmpty) return '#FF000000';
    return color;
  }
  
  /// 북마크의 마지막 접근 시간을 상대적 시간 문자열로 반환합니다.
  String get lastAccessedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastAccessedAt ?? DateTime.now());
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
  
  /// 북마크의 메타데이터를 업데이트합니다.
  PDFBookmark updateMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(
      updatedAt: DateTime.now(),
    );
  }
  
  /// 북마크의 태그를 업데이트합니다.
  PDFBookmark updateTags(List<String> newTags) {
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 북마크의 색상을 업데이트합니다.
  PDFBookmark updateColor(String newColor) {
    return copyWith(
      color: newColor,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 북마크의 메모를 업데이트합니다.
  PDFBookmark updateNote(String? newNote) {
    return copyWith(
      note: newNote,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 북마크의 페이지 번호를 업데이트합니다.
  PDFBookmark updatePageNumber(int newPageNumber) {
    return copyWith(
      pageNumber: newPageNumber,
      updatedAt: DateTime.now(),
    );
  }
} 