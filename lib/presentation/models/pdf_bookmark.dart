/// PDF 북마크 모델
///
/// PDF 문서의 북마크(책갈피) 정보를 관리합니다.
class PDFBookmark {
  /// 북마크 고유 ID
  final String id;
  
  /// 연결된 PDF 문서 ID
  final String documentId;
  
  /// 북마크 제목
  final String title;
  
  /// 페이지 번호
  final int page;
  
  /// 위치 (텍스트 오프셋 또는 좌표)
  final int position;
  
  /// 생성 시간
  final DateTime createdAt;
  
  /// 마지막 수정 시간
  final DateTime? updatedAt;
  
  /// 북마크 색상 (16진수 문자열)
  final String color;
  
  /// 북마크 메모
  final String note;
  
  /// 북마크 유형 (사용자 정의, 자동 생성 등)
  final BookmarkType type;

  /// PDF 북마크 생성자
  const PDFBookmark({
    required this.id,
    required this.documentId,
    required this.title,
    required this.page,
    this.position = 0,
    required this.createdAt,
    this.updatedAt,
    this.color = '#FF5252',
    this.note = '',
    this.type = BookmarkType.user,
  });

  /// 복사본 생성 메서드
  PDFBookmark copyWith({
    String? id,
    String? documentId,
    String? title,
    int? page,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? note,
    BookmarkType? type,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      page: page ?? this.page,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }

  /// Map으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'page': page,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'color': color,
      'note': note,
      'type': type.index,
    };
  }

  /// Map에서 생성하는 팩토리 메서드
  factory PDFBookmark.fromJson(Map<String, dynamic> json) {
    return PDFBookmark(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      title: json['title'] as String,
      page: json['page'] as int,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      color: json['color'] as String? ?? '#FF5252',
      note: json['note'] as String? ?? '',
      type: BookmarkType.values[json['type'] as int? ?? 0],
    );
  }
}

/// 북마크 유형
enum BookmarkType {
  /// 사용자 생성
  user,
  
  /// 자동 생성
  auto,
  
  /// 중요
  important,
  
  /// 임시
  temporary
} 