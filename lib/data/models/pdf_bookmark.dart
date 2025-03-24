import 'package:json_annotation/json_annotation.dart';

part 'pdf_bookmark.g.dart';

/// PDF 북마크 모델
@JsonSerializable()
class PDFBookmark {
  final String id;
  final String title;
  final int page;
  final double yOffset;
  final DateTime createdAt;
  
  /// 생성자
  const PDFBookmark({
    required this.id,
    required this.title,
    required this.page,
    required this.yOffset,
    required this.createdAt,
  });
  
  /// JSON으로부터 생성
  factory PDFBookmark.fromJson(Map<String, dynamic> json) => _$PDFBookmarkFromJson(json);
  
  /// JSON 맵으로 변환
  Map<String, dynamic> toJson() => _$PDFBookmarkToJson(this);
  
  /// 속성을 변경한 새로운 인스턴스 생성
  PDFBookmark copyWith({
    String? id,
    String? title,
    int? page,
    double? yOffset,
    DateTime? createdAt,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      page: page ?? this.page,
      yOffset: yOffset ?? this.yOffset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  String toString() {
    return 'PDFBookmark{id: $id, title: $title, page: $page, yOffset: $yOffset, createdAt: $createdAt}';
  }
} 