import 'package:flutter/foundation.dart';

/// PDF 데이터 모델
class PdfModel {
  final String id;
  final String userId;
  final String name;
  final int size;
  final int pageCount;
  final int textLength;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int accessCount;
  final String? url;
  final String? localPath;
  
  PdfModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.size,
    required this.pageCount,
    required this.textLength,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.accessCount,
    this.url,
    this.localPath,
  });
  
  /// 클라우드에 저장된 PDF인지 확인
  bool get isCloudStored => url != null && url!.isNotEmpty;
  
  factory PdfModel.fromMap(Map<String, dynamic> map) {
    try {
      return PdfModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        size: map['size'] as int,
        pageCount: map['pageCount'] as int,
        textLength: map['textLength'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastAccessedAt: DateTime.parse(map['lastAccessedAt'] as String),
        accessCount: map['accessCount'] as int,
        url: map['url'] as String?,
        localPath: map['localPath'] as String?,
      );
    } catch (e) {
      debugPrint('PdfModel.fromMap 오류: $e');
      rethrow;
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'size': size,
      'pageCount': pageCount,
      'textLength': textLength,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
      'url': url,
      'localPath': localPath,
    };
  }
  
  PdfModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? size,
    int? pageCount,
    int? textLength,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    String? url,
    String? localPath,
  }) {
    return PdfModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
      textLength: textLength ?? this.textLength,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
    );
  }
  
  @override
  String toString() {
    return 'PdfModel(id: $id, name: $name, size: $size, pageCount: $pageCount, accessCount: $accessCount)';
  }
} 