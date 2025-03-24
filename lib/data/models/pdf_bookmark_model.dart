import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/pdf_bookmark.dart';

part 'pdf_bookmark_model.freezed.dart';
part 'pdf_bookmark_model.g.dart';

@freezed
class PDFBookmarkModel with _$PDFBookmarkModel {
  const factory PDFBookmarkModel({
    required String id,
    required String documentId,
    required String title,
    required int pageNumber,
    required DateTime createdAt,
    String? description,
  }) = _PDFBookmarkModel;

  factory PDFBookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$PDFBookmarkModelFromJson(json);

  factory PDFBookmarkModel.fromEntity(PDFBookmark entity) {
    return PDFBookmarkModel(
      id: entity.id,
      documentId: entity.documentId,
      title: entity.title,
      pageNumber: entity.pageNumber,
      createdAt: entity.createdAt,
      description: entity.description,
    );
  }

  PDFBookmark toEntity() {
    return PDFBookmark(
      id: id,
      documentId: documentId,
      title: title,
      pageNumber: pageNumber,
      createdAt: createdAt,
      description: description,
    );
  }
} 