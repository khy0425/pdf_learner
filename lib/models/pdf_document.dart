import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_document.freezed.dart';
part 'pdf_document.g.dart';

@freezed
class PDFDocument with _$PDFDocument {
  const factory PDFDocument({
    required String id,
    required String title,
    required String filePath,
    String? thumbnailPath,
    required int totalPages,
    @Default(1) int currentPage,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAccessedAt,
    @Default(false) bool isFavorite,
    @Default([]) List<String> bookmarks,
    Map<String, dynamic>? metadata,
  }) = _PDFDocument;

  factory PDFDocument.fromJson(Map<String, dynamic> json) =>
      _$PDFDocumentFromJson(json);
} 