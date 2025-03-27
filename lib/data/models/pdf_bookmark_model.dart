import '../../domain/models/pdf_bookmark.dart';
import 'dart:convert';

class PDFBookmarkModel {
  final String id;
  final String documentId;
  final String title;
  final int pageNumber;
  final DateTime createdAt;
  final String note;
  final bool isHighlighted;
  final String textContent;
  final String color;
  final int position;

  const PDFBookmarkModel({
    required this.id,
    required this.documentId,
    required this.title,
    required this.pageNumber,
    required this.createdAt,
    this.note = '',
    this.isHighlighted = false,
    this.textContent = '',
    this.color = '',
    this.position = 0,
  });

  factory PDFBookmarkModel.fromJson(Map<String, dynamic> json) {
    return PDFBookmarkModel(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      title: json['title'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String? ?? '',
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      textContent: json['textContent'] as String? ?? '',
      color: json['color'] as String? ?? '',
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'isHighlighted': isHighlighted,
      'textContent': textContent,
      'color': color,
      'position': position,
    };
  }

  PDFBookmark toDomain() {
    return PDFBookmark(
      id: id,
      documentId: documentId,
      title: title,
      description: '',
      pageNumber: pageNumber,
      createdAt: createdAt,
      note: note,
      tags: [],
      metadata: {},
      isFavorite: false,
      isSelected: false,
      isHighlighted: isHighlighted,
      textContent: textContent,
      color: color,
      position: position,
    );
  }

  static PDFBookmarkModel fromDomain(PDFBookmark bookmark) {
    return PDFBookmarkModel(
      id: bookmark.id,
      documentId: bookmark.documentId,
      title: bookmark.title,
      pageNumber: bookmark.pageNumber,
      createdAt: bookmark.createdAt,
      note: bookmark.note,
      isHighlighted: bookmark.isHighlighted,
      textContent: bookmark.textContent,
      color: bookmark.color,
      position: bookmark.position,
    );
  }
  
  // String으로 된 JSON을 파싱하여 모델 생성
  static PDFBookmarkModel fromJsonString(String json) {
    return PDFBookmarkModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
} 