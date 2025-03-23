import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 주석 유형 열거형
enum AnnotationType {
  highlight,
  underline,
  note,
  drawing,
  stamp
}

/// PDF 문서 모델
class PDFDocument {
  /// 고유 ID
  final String id;
  
  /// 문서 제목
  final String title;
  
  /// 파일 경로
  final String path;
  
  /// 썸네일 이미지 경로
  final String thumbnailPath;
  
  /// 페이지 수
  final int pageCount;
  
  /// 추가된 날짜
  final DateTime dateAdded;
  
  /// 마지막으로 열어본 날짜
  final DateTime lastOpened;
  
  /// 파일 크기 (바이트)
  final int fileSize;
  
  /// 즐겨찾기 페이지 목록
  final List<int> favorites;
  
  /// 북마크 목록 (하위 호환용)
  final List<PDFBookmark> bookmarks;
  
  /// 주석 목록 (하위 호환용)
  final List<PDFAnnotation> annotations;
  
  /// 리워드 광고 버튼 표시 여부
  final bool showRewardButton;
  
  /// 광고 표시 여부
  final bool showAds;
  
  /// PDF 문서 생성자
  PDFDocument({
    required this.id,
    required this.title,
    required this.path,
    this.thumbnailPath = '',
    this.pageCount = 0,
    required this.dateAdded,
    required this.lastOpened,
    this.fileSize = 0,
    List<int>? favorites,
    List<PDFBookmark>? bookmarks,
    List<PDFAnnotation>? annotations,
    this.showRewardButton = false,
    this.showAds = true,
  }) : 
    this.favorites = favorites ?? const [],
    this.bookmarks = bookmarks ?? const [],
    this.annotations = annotations ?? const [];
  
  /// filePath getter (하위 호환성 유지)
  String? get filePath => path;
  
  /// 복사본 생성 (일부 속성 변경 가능)
  PDFDocument copyWith({
    String? id,
    String? title,
    String? path,
    String? thumbnailPath,
    int? pageCount,
    DateTime? dateAdded,
    DateTime? lastOpened,
    int? fileSize,
    List<int>? favorites,
    List<PDFBookmark>? bookmarks,
    List<PDFAnnotation>? annotations,
    bool? showRewardButton,
    bool? showAds,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      fileSize: fileSize ?? this.fileSize,
      favorites: favorites ?? this.favorites,
      bookmarks: bookmarks ?? this.bookmarks,
      annotations: annotations ?? this.annotations,
      showRewardButton: showRewardButton ?? this.showRewardButton,
      showAds: showAds ?? this.showAds,
    );
  }
  
  /// JSON에서 PDF 문서 생성
  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    return PDFDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String? ?? json['filePath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      fileSize: json['fileSize'] as int? ?? 0,
      favorites: (json['favorites'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? const [],
      bookmarks: (json['bookmarks'] as List<dynamic>?)
          ?.map((e) => PDFBookmark.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      annotations: (json['annotations'] as List<dynamic>?)
          ?.map((e) => PDFAnnotation.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }
  
  /// PDF 문서를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'thumbnailPath': thumbnailPath,
      'pageCount': pageCount,
      'dateAdded': dateAdded.toIso8601String(),
      'lastOpened': lastOpened.toIso8601String(),
      'fileSize': fileSize,
      'favorites': favorites,
      'bookmarks': bookmarks.map((e) => e.toJson()).toList(),
      'annotations': annotations.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PDFDocument{id: $id, title: $title, pageCount: $pageCount}';
  }
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