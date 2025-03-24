import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_bookmark.freezed.dart';
part 'pdf_bookmark.g.dart';

@freezed
class PDFBookmark with _$PDFBookmark {
  const factory PDFBookmark({
    required String id,
    required String documentId,
    required int pageNumber,
    required String title,
    String? description,
    required DateTime createdAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
  }) = _PDFBookmark;

  factory PDFBookmark.fromJson(Map<String, dynamic> json) =>
      _$PDFBookmarkFromJson(json);
} 