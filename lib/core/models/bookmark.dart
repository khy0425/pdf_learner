class Bookmark {
  final String pdfPath;
  final int page;
  final DateTime createdAt;
  final String title;
  final String? description;

  Bookmark({
    required this.pdfPath,
    required this.page,
    required this.createdAt,
    required this.title,
    this.description,
  });

  Bookmark copyWith({
    String? pdfPath,
    int? page,
    DateTime? createdAt,
    String? title,
    String? description,
  }) {
    return Bookmark(
      pdfPath: pdfPath ?? this.pdfPath,
      page: page ?? this.page,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdfPath': pdfPath,
      'page': page,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'description': description,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      pdfPath: json['pdfPath'],
      page: json['page'],
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'],
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Bookmark &&
      other.pdfPath == pdfPath &&
      other.page == page &&
      other.createdAt == createdAt &&
      other.title == title &&
      other.description == description;
  }

  @override
  int get hashCode {
    return pdfPath.hashCode ^
      page.hashCode ^
      createdAt.hashCode ^
      title.hashCode ^
      description.hashCode;
  }
} 