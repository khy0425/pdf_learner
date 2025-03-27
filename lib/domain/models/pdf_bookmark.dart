import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
  
  /// 업데이트 일시
  final DateTime? updatedAt;
  
  /// 북마크 태그 목록
  final List<String> tags;
  
  /// 북마크 메모
  final String note;
  
  /// 선택된 텍스트
  final String selectedText;
  
  /// 북마크 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 북마크가 즐겨찾기인지 여부
  final bool isFavorite;
  
  /// 북마크가 선택된 상태인지 여부
  final bool isSelected;
  
  /// 북마크가 하이라이트 상태인지 여부
  final bool isHighlighted;
  
  /// 하이라이트된 텍스트 내용
  final String textContent;
  
  /// 북마크 색상
  final String color;
  
  /// 북마크 위치
  final int position;

  /// 기본 북마크 생성자
  const PDFBookmark({
    required this.id,
    required this.documentId,
    required this.title,
    this.description = '',
    required this.pageNumber,
    required this.createdAt,
    this.updatedAt,
    this.note = '',
    this.selectedText = '',
    this.tags = const [],
    this.metadata = const {},
    this.isFavorite = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.textContent = '',
    this.color = '',
    this.position = 0,
  });

  /// JSON 문자열에서 북마크 객체 생성
  factory PDFBookmark.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return PDFBookmark(
        id: json['id'] as String,
        documentId: json['documentId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        pageNumber: json['pageNumber'] as int,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        note: json['note'] as String? ?? '',
        selectedText: json['selectedText'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        isFavorite: json['isFavorite'] as bool? ?? false,
        isSelected: json['isSelected'] as bool? ?? false,
        isHighlighted: json['isHighlighted'] as bool? ?? false,
        textContent: json['textContent'] as String? ?? '',
        color: json['color'] as String? ?? '',
        position: json['position'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('북마크 JSON 파싱 오류: $e');
      return PDFBookmark(
        id: const Uuid().v4(),
        documentId: '',
        title: '오류 북마크',
        description: '파싱 중 오류 발생',
        pageNumber: 0,
        createdAt: DateTime.now(),
      );
    }
  }
  
  /// JSON 문자열로 변환
  String toJson() {
    return jsonEncode(toMap());
  }
  
  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'description': description,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'note': note,
      'selectedText': selectedText,
      'tags': tags,
      'metadata': metadata,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
      'isHighlighted': isHighlighted,
      'textContent': textContent,
      'color': color,
      'position': position,
    };
  }

  /// Map에서 객체 생성
  factory PDFBookmark.fromMap(Map<String, dynamic> map) {
    try {
      return PDFBookmark(
        id: map['id'] ?? '',
        documentId: map['documentId'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        pageNumber: map['pageNumber'] ?? 0,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : null,
        note: map['note'] ?? '',
        selectedText: map['selectedText'] ?? '',
        tags: List<String>.from(map['tags'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        isFavorite: map['isFavorite'] ?? false,
        isSelected: map['isSelected'] ?? false,
        isHighlighted: map['isHighlighted'] ?? false,
        textContent: map['textContent'] ?? '',
        color: map['color'] ?? '',
        position: map['position'] ?? 0,
      );
    } catch (e) {
      debugPrint('북마크 맵 파싱 오류: $e');
      return PDFBookmark(
        id: const Uuid().v4(),
        documentId: '',
        title: '오류 북마크',
        description: '파싱 중 오류 발생',
        pageNumber: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  /// 기본 북마크 생성
  factory PDFBookmark.createDefault() {
    return PDFBookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: '',
      pageNumber: 0,
      title: '새 북마크',
      description: '',
      createdAt: DateTime.now(),
      tags: [],
      note: '',
      metadata: {},
      isFavorite: false,
      isSelected: false,
      isHighlighted: false,
      textContent: '',
      color: '#FFFF00',
      position: 0,
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
    DateTime? updatedAt,
    String? note,
    String? selectedText,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    bool? isSelected,
    bool? isHighlighted,
    String? textContent,
    String? color,
    int? position,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      selectedText: selectedText ?? this.selectedText,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      textContent: textContent ?? this.textContent,
      color: color ?? this.color,
      position: position ?? this.position,
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
           (DateTime.now().difference(createdAt)).inMinutes <= 5;
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
    if (color.isNotEmpty) return color;
    if (metadata.isEmpty) return '#FF0000';
    return metadata['color'] ?? '#FF0000';
  }
  
  /// 북마크의 마지막 접근 시간을 상대적 시간 문자열로 반환합니다.
  String get lastAccessedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
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
      color: newColor,
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