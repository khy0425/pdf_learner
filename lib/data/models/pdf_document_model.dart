import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/pdf_document.dart';
import 'pdf_bookmark_model.dart';

part 'pdf_document_model.freezed.dart';
part 'pdf_document_model.g.dart';

@freezed
class PDFDocumentModel with _$PDFDocumentModel {
  const factory PDFDocumentModel({
    required String id,
    required String title,
    required String filePath,
    required String thumbnailPath,
    required int totalPages,
    required int currentPage,
    required bool isFavorite,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<PDFBookmarkModel> bookmarks,
  }) = _PDFDocumentModel;

  factory PDFDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$PDFDocumentModelFromJson(json);

  factory PDFDocumentModel.fromEntity(PDFDocument entity) {
    return PDFDocumentModel(
      id: entity.id,
      title: entity.title,
      filePath: entity.filePath,
      thumbnailPath: entity.thumbnailPath,
      totalPages: entity.totalPages,
      currentPage: entity.currentPage,
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      bookmarks: entity.bookmarks.map((b) => PDFBookmarkModel.fromEntity(b)).toList(),
    );
  }

  PDFDocument toEntity() {
    return PDFDocument(
      id: id,
      title: title,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      totalPages: totalPages,
      currentPage: currentPage,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookmarks: bookmarks.map((b) => b.toEntity()).toList(),
    );
  }
} 