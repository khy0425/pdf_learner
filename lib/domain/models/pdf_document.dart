import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pdf_bookmark.dart';

/// PDF 문서 상태
enum PDFDocumentStatus {
  /// 추가됨
  added,
  
  /// 읽는 중
  reading,
  
  /// 완료됨
  completed,
  
  /// 보관됨
  archived,
  
  /// 삭제됨
  deleted,
  
  /// 다운로드됨
  downloaded
}

/// PDF 중요도
enum PDFImportanceLevel {
  /// 낮음
  low,
  
  /// 중간
  medium,
  
  /// 높음
  high,
  
  /// 매우 높음
  critical
}

/// PDF 보안 수준
enum PDFSecurityLevel {
  /// 공개
  public,
  
  /// 제한됨
  restricted,
  
  /// 기밀
  confidential,
  
  /// 극비
  secret
}

/// PDF 파일 카테고리
enum PDFCategory {
  /// 책
  book,
  
  /// 논문
  paper,
  
  /// 문서
  document,
  
  /// 기타
  other
}

/// PDF 파일 접근 레벨
enum PDFAccessLevel {
  /// 공개
  public,
  
  /// 비공개
  private,
  
  /// 공유됨
  shared
}

/// PDF 문서 모델
/// 
/// PDF 문서의 메타데이터와 파일 정보를 관리합니다.
class PDFDocument extends Equatable {
  /// 문서 ID
  final String id;
  
  /// 문서 제목
  final String title;
  
  /// 파일 경로
  final String filePath;
  
  /// 파일 크기 (바이트)
  final int fileSize;
  
  /// 총 페이지 수
  final int pageCount;
  
  /// 마지막으로 읽은 페이지
  final int lastReadPage;
  
  /// 읽기 진행 상태 (0.0 ~ 1.0)
  final double readingProgress;
  
  /// 작성자 정보
  final String author;
  
  /// 문서 설명
  final String description;
  
  /// 썸네일 이미지 경로
  final String thumbnailPath;
  
  /// 문서 해시 (무결성 확인용)
  final String fileHash;
  
  /// 다운로드 URL
  final String downloadUrl;
  
  /// 문서 상태
  final PDFDocumentStatus status;
  
  /// 태그 목록
  final List<String> tags;
  
  /// 문서 카테고리
  final PDFCategory category;
  
  /// 접근 레벨
  final PDFAccessLevel accessLevel;
  
  /// 좋아요 표시 여부
  final bool isFavorite;
  
  /// 생성 시간
  final DateTime? createdAt;
  
  /// 마지막 업데이트 시간
  final DateTime? updatedAt;
  
  /// 마지막 접근 시간
  final DateTime? lastAccessedAt;
  
  /// 사용자 지정 메타데이터
  final Map<String, dynamic> metadata;
  
  /// PDF 문서 생성자
  const PDFDocument({
    required this.id,
    required this.title,
    required this.filePath,
    this.fileSize = 0,
    this.pageCount = 0,
    this.lastReadPage = 0,
    this.readingProgress = 0.0,
    this.author = '',
    this.description = '',
    this.thumbnailPath = '',
    this.fileHash = '',
    this.downloadUrl = '',
    this.status = PDFDocumentStatus.added,
    this.tags = const [],
    this.category = PDFCategory.document,
    this.accessLevel = PDFAccessLevel.private,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.metadata = const {},
  });
  
  /// JSON 문자열에서 인스턴스 생성
  factory PDFDocument.fromJson(String json) {
    return PDFDocument.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
  
  /// 맵에서 인스턴스 생성
  factory PDFDocument.fromMap(Map<String, dynamic> map) {
    return PDFDocument(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      fileSize: map['fileSize'] as int? ?? 0,
      pageCount: map['pageCount'] as int? ?? 0,
      lastReadPage: map['lastReadPage'] as int? ?? 0,
      readingProgress: (map['readingProgress'] as num?)?.toDouble() ?? 0.0,
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      fileHash: map['fileHash'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      status: _statusFromString(map['status'] as String?),
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      category: _categoryFromString(map['category'] as String?),
      accessLevel: _accessLevelFromString(map['accessLevel'] as String?),
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt'].toString()))
          : null,
      lastAccessedAt: map['lastAccessedAt'] != null 
          ? (map['lastAccessedAt'] is Timestamp 
              ? (map['lastAccessedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['lastAccessedAt'].toString()))
          : null,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map) 
          : const {},
    );
  }
  
  /// 다른 인스턴스와 현재 인스턴스 비교를 위한 프로퍼티 목록
  @override
  List<Object?> get props => [
    id,
    title,
    filePath,
    fileSize,
    pageCount,
    lastReadPage,
    readingProgress,
    author,
    description,
    thumbnailPath,
    fileHash,
    downloadUrl,
    status,
    tags,
    category,
    accessLevel,
    isFavorite,
    createdAt,
    updatedAt,
    lastAccessedAt,
    metadata,
  ];
  
  /// 도메인 개체로 변환 (자기 자신을 반환)
  PDFDocument toDomain() => this;
  
  /// JSON 문자열로 변환
  String toJson() {
    return jsonEncode(toMap());
  }
  
  /// 맵으로 변환
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'lastReadPage': lastReadPage,
      'readingProgress': readingProgress,
      'author': author,
      'description': description,
      'thumbnailPath': thumbnailPath,
      'fileHash': fileHash,
      'downloadUrl': downloadUrl,
      'status': _statusToString(status),
      'tags': tags,
      'category': _categoryToString(category),
      'accessLevel': _accessLevelToString(accessLevel),
      'isFavorite': isFavorite,
    };
    
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toIso8601String();
    }
    
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }
    
    if (lastAccessedAt != null) {
      map['lastAccessedAt'] = lastAccessedAt!.toIso8601String();
    }
    
    if (metadata.isNotEmpty) {
      map['metadata'] = metadata;
    }
    
    return map;
  }
  
  /// 복사본 생성
  PDFDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    int? fileSize,
    int? pageCount,
    int? lastReadPage,
    double? readingProgress,
    String? author,
    String? description,
    String? thumbnailPath,
    String? fileHash,
    String? downloadUrl,
    PDFDocumentStatus? status,
    List<String>? tags,
    PDFCategory? category,
    PDFAccessLevel? accessLevel,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      readingProgress: readingProgress ?? this.readingProgress,
      author: author ?? this.author,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileHash: fileHash ?? this.fileHash,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      accessLevel: accessLevel ?? this.accessLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 카테고리를 문자열로 변환
String _categoryToString(PDFCategory category) {
  switch (category) {
    case PDFCategory.book:
      return 'book';
    case PDFCategory.paper:
      return 'paper';
    case PDFCategory.document:
      return 'document';
    case PDFCategory.other:
      return 'other';
    default:
      return 'document';
  }
}

/// 문자열에서 카테고리 변환
PDFCategory _categoryFromString(String? category) {
  if (category == null) return PDFCategory.document;
  
  switch (category.toLowerCase()) {
    case 'book':
      return PDFCategory.book;
    case 'paper':
      return PDFCategory.paper;
    case 'document':
      return PDFCategory.document;
    case 'other':
      return PDFCategory.other;
    default:
      return PDFCategory.document;
  }
}

/// 접근 레벨을 문자열로 변환
String _accessLevelToString(PDFAccessLevel level) {
  switch (level) {
    case PDFAccessLevel.public:
      return 'public';
    case PDFAccessLevel.private:
      return 'private';
    case PDFAccessLevel.shared:
      return 'shared';
    default:
      return 'private';
  }
}

/// 문자열에서 접근 레벨 변환
PDFAccessLevel _accessLevelFromString(String? level) {
  if (level == null) return PDFAccessLevel.private;
  
  switch (level.toLowerCase()) {
    case 'public':
      return PDFAccessLevel.public;
    case 'private':
      return PDFAccessLevel.private;
    case 'shared':
      return PDFAccessLevel.shared;
    default:
      return PDFAccessLevel.private;
  }
}

/// PDF 문서 상태를 문자열로 변환
String _statusToString(PDFDocumentStatus status) {
  switch (status) {
    case PDFDocumentStatus.added:
      return 'added';
    case PDFDocumentStatus.reading:
      return 'reading';
    case PDFDocumentStatus.completed:
      return 'completed';
    case PDFDocumentStatus.archived:
      return 'archived';
    case PDFDocumentStatus.deleted:
      return 'deleted';
    case PDFDocumentStatus.downloaded:
      return 'downloaded';
    default:
      return 'added';
  }
}

/// 문자열에서 PDF 문서 상태로 변환
PDFDocumentStatus _statusFromString(String? status) {
  if (status == null) return PDFDocumentStatus.added;
  
  switch (status.toLowerCase()) {
    case 'added':
      return PDFDocumentStatus.added;
    case 'reading':
      return PDFDocumentStatus.reading;
    case 'completed':
      return PDFDocumentStatus.completed;
    case 'archived':
      return PDFDocumentStatus.archived;
    case 'deleted':
      return PDFDocumentStatus.deleted;
    case 'downloaded':
      return PDFDocumentStatus.downloaded;
    default:
      return PDFDocumentStatus.added;
  }
}

/// PDFDocument 확장 메서드
extension PDFDocumentX on PDFDocument {
  /// 문서가 유효한지 확인
  bool isValid() {
    return id.isNotEmpty && 
           title.isNotEmpty && 
           filePath.isNotEmpty;
  }
  
  /// 마지막 접근 시간 표시 문자열
  String get lastAccessedTimeAgo {
    final now = DateTime.now();
    final lastAccessed = lastAccessedAt ?? now;
    final difference = now.difference(lastAccessed);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
  
  /// 파일 크기 표시 문자열
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (pageCount <= 0) return 0.0;
    return lastReadPage / pageCount;
  }
  
  /// 진행률 백분율 문자열
  String get progressPercentage {
    return '${(progress * 100).round()}%';
  }
} 