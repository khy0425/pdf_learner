import 'dart:convert';

/// PDF 북마크 모델
/// 
/// PDF 문서의 특정 페이지에 대한 북마크 정보를 관리합니다.
class PDFBookmark {
  /// 북마크 고유 ID
  final String id;
  
  /// 문서 ID
  final String documentId;
  
  /// 페이지 번호
  final int pageNumber;
  
  /// 북마크 제목
  final String title;
  
  /// 북마크 설명
  final String description;
  
  /// 생성일시
  final DateTime createdAt;
  
  /// 마지막 접근일시
  final DateTime? lastAccessedAt;
  
  /// 마지막 수정일시
  final DateTime? lastModifiedAt;
  
  /// 북마크 태그 목록
  final List<String> tags;
  
  /// 북마크 메모
  final String note;
  
  /// 북마크 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 북마크가 즐겨찾기인지 여부
  final bool isFavorite;
  
  /// 북마크가 선택된 상태인지 여부
  final bool isSelected;

  const PDFBookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.title,
    required this.description,
    required this.createdAt,
    this.lastAccessedAt,
    this.lastModifiedAt,
    required this.tags,
    required this.note,
    required this.metadata,
    required this.isFavorite,
    required this.isSelected,
  });

  /// JSON 직렬화/역직렬화를 위한 팩토리 생성자
  factory PDFBookmark.fromMap(Map<String, dynamic> json) {
    return PDFBookmark(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      pageNumber: json['pageNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null 
          ? DateTime.parse(json['lastAccessedAt'] as String) 
          : null,
      lastModifiedAt: json['lastModifiedAt'] != null 
          ? DateTime.parse(json['lastModifiedAt'] as String) 
          : null,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      note: json['note'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      isFavorite: json['isFavorite'] as bool,
      isSelected: json['isSelected'] as bool,
    );
  }
  
  /// JSON에서 북마크 객체를 생성합니다.
  factory PDFBookmark.fromJson(dynamic source) {
    if (source is String) {
      return PDFBookmark.fromMap(json.decode(source) as Map<String, dynamic>);
    } else if (source is Map<String, dynamic>) {
      return PDFBookmark.fromMap(source);
    } else {
      throw ArgumentError('Invalid JSON type: ${source.runtimeType}');
    }
  }

  /// 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'pageNumber': pageNumber,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'tags': tags,
      'note': note,
      'metadata': metadata,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
    };
  }
  
  /// 객체를 JSON 문자열로 변환
  String toJson() => json.encode(toMap());

  /// 기본 북마크 생성
  factory PDFBookmark.createDefault() {
    return PDFBookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: '',
      pageNumber: 0,
      title: '새 북마크',
      description: '',
      createdAt: DateTime.now(),
      lastAccessedAt: null,
      lastModifiedAt: null,
      tags: [],
      note: '',
      metadata: {},
      isFavorite: false,
      isSelected: false,
    );
  }
  
  /// 복사본 생성
  PDFBookmark copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    DateTime? lastModifiedAt,
    List<String>? tags,
    String? note,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    bool? isSelected,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() {
    return 'PDFBookmark(id: $id, documentId: $documentId, pageNumber: $pageNumber, title: $title, createdAt: $createdAt, tags: $tags, note: $note, metadata: $metadata, isFavorite: $isFavorite, isSelected: $isSelected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PDFBookmark &&
      other.id == id &&
      other.documentId == documentId &&
      other.pageNumber == pageNumber &&
      other.title == title &&
      other.createdAt == createdAt &&
      other.tags.length == tags.length &&
      other.tags.every((item) => tags.contains(item)) &&
      other.note == note &&
      other.isFavorite == isFavorite &&
      other.isSelected == isSelected;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      documentId.hashCode ^
      pageNumber.hashCode ^
      title.hashCode ^
      createdAt.hashCode ^
      tags.hashCode ^
      note.hashCode ^
      metadata.hashCode ^
      isFavorite.hashCode ^
      isSelected.hashCode;
  }
}

/// PDF 북마크 확장 메서드
extension PDFBookmarkX on PDFBookmark {
  /// 북마크가 유효한지 검사합니다.
  bool isValid() {
    return id.isNotEmpty &&
           documentId.isNotEmpty &&
           pageNumber > 0 &&
           createdAt.isBefore(DateTime.now()) &&
           (lastAccessedAt == null || createdAt.isBefore(lastAccessedAt!)) &&
           (DateTime.now().difference(lastAccessedAt ?? createdAt)).inMinutes <= 5;
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
    if (metadata.isEmpty) return '#FF0000';
    return metadata['color'] ?? '#FF0000';
  }
  
  /// 북마크의 마지막 접근 시간을 상대적 시간 문자열로 반환합니다.
  String get lastAccessedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastAccessedAt ?? createdAt);
    
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
      metadata: newMetadata,
    );
  }
  
  /// 북마크의 태그를 업데이트합니다.
  PDFBookmark updateTags(List<String> newTags) {
    return copyWith(
      tags: newTags,
    );
  }
  
  /// 북마크의 색상을 업데이트합니다.
  PDFBookmark updateColor(String newColor) {
    return copyWith(
      metadata: {
        ...metadata,
        'color': newColor,
      },
    );
  }
  
  /// 북마크의 메모를 업데이트합니다.
  PDFBookmark updateNote(String newNote) {
    return copyWith(
      note: newNote,
    );
  }
  
  /// 북마크의 페이지 번호를 업데이트합니다.
  PDFBookmark updatePageNumber(int newPageNumber) {
    return copyWith(
      pageNumber: newPageNumber,
    );
  }
} 