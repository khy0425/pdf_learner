import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'pdf_bookmark.dart';

part 'pdf_document.freezed.dart';
part 'pdf_document.g.dart';

/// 주석 유형 열거형
enum AnnotationType {
  highlight,
  underline,
  note,
  drawing,
  stamp
}

/// PDF 문서 모델
@freezed
class PDFDocument with _$PDFDocument {
  const factory PDFDocument({
    required String id,
    required String title,
    required String filePath,
    required String thumbnailPath,
    required int totalPages,
    @Default(0) int currentPage,
    @Default(false) bool isFavorite,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<PDFBookmark> bookmarks,
  }) = _PDFDocument;

  factory PDFDocument.fromJson(Map<String, dynamic> json) =>
      _$PDFDocumentFromJson(json);
}

/// PDF 북마크 모델
class PDFBookmark {
  /// 고유 ID
  final String id;
  
  /// 북마크 제목
  final String title;
  
  /// 페이지 번호
  final int pageNumber;
  
  /// 스크롤 위치 (y좌표)
  final double scrollPosition;

  /// 생성일
  final DateTime createdAt;

  /// 북마크 생성자
  PDFBookmark({
    String? id,
    required this.title,
    required this.pageNumber,
    required this.scrollPosition,
    DateTime? createdAt,
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    this.createdAt = createdAt ?? DateTime.now();

  /// JSON에서 북마크 생성
  factory PDFBookmark.fromJson(Map<String, dynamic> json) {
    return PDFBookmark(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String,
      pageNumber: json['pageNumber'] as int,
      scrollPosition: (json['scrollPosition'] as num).toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 북마크를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pageNumber': pageNumber,
      'scrollPosition': scrollPosition,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// PDF 주석 영역을 표현하는 클래스
class PdfRect {
  final double left;
  final double top;
  final double width;
  final double height;
  
  const PdfRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  
  // 직렬화를 위한 메소드
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }
  
  // JSON에서 생성하는 팩토리 메소드
  factory PdfRect.fromJson(Map<String, dynamic> json) {
    return PdfRect(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}

/// PDF 주석 모델
class PDFAnnotation {
  /// 고유 ID
  final String id;
  
  /// 주석 내용
  final String text;
  
  /// 페이지 번호
  final int pageNumber;
  
  /// 사각형 영역
  final PdfRect rectangle;
  
  /// 주석 색상
  final Color color;
  
  /// 생성일
  final DateTime createdAt;

  /// 주석 생성자
  PDFAnnotation({
    String? id,
    required this.text,
    required this.pageNumber,
    required this.rectangle,
    required this.color,
    DateTime? createdAt,
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    this.createdAt = createdAt ?? DateTime.now();

  /// JSON에서 주석 생성
  factory PDFAnnotation.fromJson(Map<String, dynamic> json) {
    final rectData = json['rectangle'] as Map<String, dynamic>;
    final colorData = json['color'] as Map<String, dynamic>;
    
    return PDFAnnotation(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String,
      pageNumber: json['pageNumber'] as int,
      rectangle: PdfRect(
        left: (rectData['left'] as num).toDouble(), 
        top: (rectData['top'] as num).toDouble(),
        width: (rectData['width'] as num).toDouble(),
        height: (rectData['height'] as num).toDouble(),
      ),
      color: Color.fromRGBO(
        colorData['r'] as int,
        colorData['g'] as int,
        colorData['b'] as int,
        (colorData['a'] as num).toDouble(),
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 주석을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'pageNumber': pageNumber,
      'rectangle': rectangle.toJson(),
      'color': {
        'r': color.red,
        'g': color.green,
        'b': color.blue,
        'a': color.opacity,
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
}