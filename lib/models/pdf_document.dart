import 'dart:convert';

/// 주석 유형 열거형
enum AnnotationType {
  highlight,
  underline,
  note,
  drawing,
  stamp
}

/// 사각형 영역 표현 클래스
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      left: json['left'].toDouble(),
      top: json['top'].toDouble(),
      right: json['right'].toDouble(),
      bottom: json['bottom'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }
}

/// PDF 문서 데이터 모델
class PDFDocument {
  /// 문서 고유 ID
  final String id;
  
  /// 문서 제목
  final String title;
  
  /// 문서 설명
  final String? description;
  
  /// 파일 경로
  final String filePath;
  
  /// 파일 이름
  final String fileName;
  
  /// 파일 크기 (바이트)
  final int fileSize;
  
  /// 페이지 수
  final int pageCount;
  
  /// 문서 URL (원격 파일인 경우)
  final String? url;
  
  /// 총 단어 수
  final int totalWords;
  
  /// 생성 일시
  final DateTime createdAt;
  
  /// 수정 일시
  final DateTime updatedAt;
  
  /// 마지막 접근 일시
  final DateTime lastAccessedAt;
  
  /// 접근 횟수
  final int accessCount;
  
  /// 문서 썸네일 경로
  final String? thumbnailPath;
  
  /// 북마크 목록
  final List<PDFBookmark> bookmarks;
  
  /// 주석 목록
  final List<PDFAnnotation> annotations;

  /// 생성자
  PDFDocument({
    required this.id,
    required this.title,
    this.description,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.pageCount = 0,
    this.url,
    this.totalWords = 0,
    required this.createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    this.accessCount = 0,
    this.thumbnailPath,
    List<PDFBookmark>? bookmarks,
    List<PDFAnnotation>? annotations,
  }) : 
    updatedAt = updatedAt ?? createdAt,
    lastAccessedAt = lastAccessedAt ?? createdAt,
    bookmarks = bookmarks ?? [],
    annotations = annotations ?? [];

  /// JSON에서 객체 생성
  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    List<PDFBookmark> bookmarks = [];
    if (json['bookmarks'] != null) {
      bookmarks = (json['bookmarks'] as List)
          .map((item) => PDFBookmark.fromJson(item))
          .toList();
    }
    
    List<PDFAnnotation> annotations = [];
    if (json['annotations'] != null) {
      annotations = (json['annotations'] as List)
          .map((item) => PDFAnnotation.fromJson(item))
          .toList();
    }
    
    return PDFDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String? ?? 'document.pdf',
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 0,
      url: json['url'] as String?,
      totalWords: json['totalWords'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      accessCount: json['accessCount'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath'] as String?,
      bookmarks: bookmarks,
      annotations: annotations,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'url': url,
      'totalWords': totalWords,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
      'thumbnailPath': thumbnailPath,
      'bookmarks': bookmarks.map((e) => e.toJson()).toList(),
      'annotations': annotations.map((e) => e.toJson()).toList(),
    };
  }

  /// 객체 복사 및 일부 속성 수정
  PDFDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    String? fileName,
    int? fileSize,
    int? pageCount,
    String? url,
    int? totalWords,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    String? thumbnailPath,
    List<PDFBookmark>? bookmarks,
    List<PDFAnnotation>? annotations,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      url: url ?? this.url,
      totalWords: totalWords ?? this.totalWords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      bookmarks: bookmarks ?? this.bookmarks,
      annotations: annotations ?? this.annotations,
    );
  }
  
  /// 문서 접근 횟수 증가
  PDFDocument incrementAccessCount() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  @override
  String toString() {
    return 'PDFDocument{id: $id, title: $title, pageCount: $pageCount}';
  }
}

class PDFAnnotation {
  final String id;
  final int pageNumber;
  final String content;
  final AnnotationType type;
  final Rect rect;
  final DateTime createdAt;
  final String? color;

  PDFAnnotation({
    required this.id,
    required this.pageNumber,
    required this.content,
    required this.type,
    required this.rect,
    required this.createdAt,
    this.color,
  });

  factory PDFAnnotation.fromJson(Map<String, dynamic> json) {
    return PDFAnnotation(
      id: json['id'],
      pageNumber: json['pageNumber'],
      content: json['content'],
      type: AnnotationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'], 
        orElse: () => AnnotationType.highlight,
      ),
      rect: Rect.fromJson(json['rect']),
      createdAt: DateTime.parse(json['createdAt']),
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'content': content,
      'type': type.toString().split('.').last,
      'rect': rect.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'color': color,
    };
  }

  PDFAnnotation copyWith({
    String? id,
    int? pageNumber,
    String? content,
    AnnotationType? type,
    Rect? rect,
    DateTime? createdAt,
    String? color,
  }) {
    return PDFAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      content: content ?? this.content,
      type: type ?? this.type,
      rect: rect ?? this.rect,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
    );
  }
}

class PDFBookmark {
  final String id;
  final int pageNumber;
  final String title;
  final DateTime createdAt;

  PDFBookmark({
    required this.id,
    required this.pageNumber,
    required this.title,
    required this.createdAt,
  });

  /// page getter - pageNumber와 동일한 값을 반환하는 호환성용 getter
  int get page => pageNumber;

  factory PDFBookmark.fromJson(Map<String, dynamic> json) {
    return PDFBookmark(
      id: json['id'],
      pageNumber: json['pageNumber'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PDFBookmark copyWith({
    String? id,
    int? pageNumber,
    String? title,
    DateTime? createdAt,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}