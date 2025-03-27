class Note {
  final String pdfPath;
  final int page;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final List<String>? tags;

  Note({
    required this.pdfPath,
    required this.page,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.tags,
  });

  Note copyWith({
    String? pdfPath,
    int? page,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    List<String>? tags,
  }) {
    return Note(
      pdfPath: pdfPath ?? this.pdfPath,
      page: page ?? this.page,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdfPath': pdfPath,
      'page': page,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
      'tags': tags,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      pdfPath: json['pdfPath'],
      page: json['page'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      title: json['title'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Note &&
      other.pdfPath == pdfPath &&
      other.page == page &&
      other.content == content &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.title == title &&
      _listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return pdfPath.hashCode ^
      page.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      title.hashCode ^
      (tags != null ? tags.hashCode : 0);
  }
  
  // 두 리스트의 동등성 비교
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
} 