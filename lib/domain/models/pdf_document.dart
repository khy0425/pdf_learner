import 'dart:convert';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// PDF 문서의 상태를 나타내는 열거형
enum PDFDocumentStatus {
  /// 초기 상태
  initial,
  
  /// 다운로드 중
  downloading,
  
  /// 다운로드 완료
  downloaded,
  
  /// 읽는 중
  reading,
  
  /// 읽기 완료
  completed,
  
  /// 생성됨
  created,
  
  /// 삭제됨
  deleted,
}

/// PDF 문서의 중요도를 나타내는 열거형
enum PDFDocumentImportance {
  /// 낮음
  low,
  
  /// 중간
  medium,
  
  /// 높음
  high,
  
  /// 매우 중요
  critical,
}

/// PDF 문서의 보안 레벨을 나타내는 열거형
enum PDFDocumentSecurityLevel {
  /// 없음
  none,
  
  /// 낮음
  low,
  
  /// 중간
  medium,
  
  /// 높음
  high,
  
  /// 제한됨
  restricted,
}

/// PDF 문서 모델
class PDFDocument {
  /// 문서 고유 ID
  final String id;
  
  /// 문서 제목
  final String title;
  
  /// 문서 설명
  final String description;
  
  /// 문서 파일 경로
  final String filePath;
  
  /// 문서 다운로드 URL
  final String downloadUrl;
  
  /// 문서 페이지 수
  final int pageCount;
  
  /// 문서 생성일
  final DateTime createdAt;
  
  /// 문서 수정일
  final DateTime updatedAt;
  
  /// 문서 현재 페이지
  final int currentPage;
  
  /// 문서 읽기 진행률
  final double readingProgress;
  
  /// 문서 즐겨찾기 여부
  final bool isFavorite;
  
  /// 문서 선택 여부
  final bool isSelected;
  
  /// 문서 읽기 시간 (초 단위)
  final int readingTime;
  
  /// 문서 상태
  final PDFDocumentStatus status;
  
  /// 문서 중요도
  final PDFDocumentImportance importance;
  
  /// 문서 보안 수준
  final PDFDocumentSecurityLevel securityLevel;
  
  /// 문서 태그 목록
  final List<String> tags;
  
  /// 문서 북마크 목록
  final List<PDFBookmark> bookmarks;
  
  /// 문서 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 문서 파일 크기
  final int fileSize;

  /// PDF 문서의 썸네일 URL (기본값: 빈 문자열)
  final String thumbnailUrl;

  /// PDF 문서의 썸네일 경로 (로컬 파일 경로)
  final String? thumbnailPath;

  /// 총 페이지 수
  final int totalPages;
  
  /// 파일 크기
  final int size;

  PDFDocument({
    required this.id,
    required this.title,
    this.description = '',
    this.filePath = '',
    this.downloadUrl = '',
    required this.pageCount,
    this.thumbnailUrl = '',
    this.thumbnailPath,
    this.totalPages = 0,
    this.currentPage = 0,
    this.size = 0,
    this.fileSize = 0,
    this.readingProgress = 0.0,
    this.readingTime = 0,
    this.isFavorite = false,
    this.isSelected = false,
    this.status = PDFDocumentStatus.initial,
    this.importance = PDFDocumentImportance.medium,
    this.securityLevel = PDFDocumentSecurityLevel.none,
    this.tags = const [],
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.bookmarks = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// JSON 문자열에서 PDF 문서 객체 생성
  factory PDFDocument.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return PDFDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        filePath: json['filePath'] as String,
        downloadUrl: json['downloadUrl'] as String? ?? '',
        pageCount: json['pageCount'] as int? ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        thumbnailPath: json['thumbnailPath'] as String?,
        totalPages: json['totalPages'] as int? ?? 0,
        currentPage: json['currentPage'] as int? ?? 0,
        size: json['size'] as int? ?? 0,
        fileSize: json['fileSize'] as int? ?? 0,
        readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
        readingTime: json['readingTime'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isSelected: json['isSelected'] as bool? ?? false,
        status: _parseStatus(json['status']),
        importance: _parseImportance(json['importance']),
        securityLevel: _parseSecurityLevel(json['securityLevel']),
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        bookmarks: [],
      );
    } catch (e) {
      debugPrint('PDF 문서 JSON 파싱 오류: $e');
      return PDFDocument(
        id: const Uuid().v4(),
        title: '오류 문서',
        description: '파싱 중 오류 발생',
        filePath: '',
        downloadUrl: '',
        pageCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  /// JSON 문자열로 변환
  String toJson() {
    return jsonEncode(toMap());
  }
  
  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'pageCount': pageCount,
      'currentPage': currentPage,
      'readingProgress': readingProgress,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
      'readingTime': readingTime,
      'status': status.toString().split('.').last,
      'importance': importance.toString().split('.').last,
      'securityLevel': securityLevel.toString().split('.').last,
      'tags': tags,
      'bookmarks': bookmarks.map((bookmark) => bookmark.toMap()).toList(),
      'metadata': metadata,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailPath': thumbnailPath,
      'totalPages': totalPages,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Map에서 객체 생성
  factory PDFDocument.fromMap(Map<String, dynamic> map) {
    try {
      return PDFDocument(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        filePath: map['filePath'] ?? '',
        downloadUrl: map['downloadUrl'] ?? '',
        pageCount: map['pageCount'] ?? 0,
        currentPage: map['currentPage'] ?? 0,
        readingProgress: map['readingProgress']?.toDouble() ?? 0.0,
        isFavorite: map['isFavorite'] ?? false,
        isSelected: map['isSelected'] ?? false,
        readingTime: map['readingTime'] ?? 0,
        status: _parseStatus(map['status']),
        importance: _parseImportance(map['importance']),
        securityLevel: _parseSecurityLevel(map['securityLevel']),
        tags: List<String>.from(map['tags'] ?? []),
        bookmarks: [],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        fileSize: map['fileSize'] ?? 0,
        thumbnailUrl: map['thumbnailUrl'] ?? '',
        thumbnailPath: map['thumbnailPath'],
        totalPages: map['totalPages'] ?? 0,
        size: map['size'] ?? 0,
        createdAt: map['createdAt'] != null 
            ? DateTime.parse(map['createdAt']) 
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null 
            ? DateTime.parse(map['updatedAt']) 
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('PDF 문서 맵 파싱 오류: $e');
      return PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '오류 문서',
        description: '파싱 중 오류 발생',
        filePath: '',
        downloadUrl: '',
        pageCount: 0,
      );
    }
  }

  /// 상태 문자열 파싱
  static PDFDocumentStatus _parseStatus(String? status) {
    if (status == null) return PDFDocumentStatus.initial;
    
    switch (status.toLowerCase()) {
      case 'initial': return PDFDocumentStatus.initial;
      case 'downloading': return PDFDocumentStatus.downloading;
      case 'downloaded': return PDFDocumentStatus.downloaded;
      case 'reading': return PDFDocumentStatus.reading;
      case 'completed': return PDFDocumentStatus.completed;
      case 'created': return PDFDocumentStatus.created;
      case 'deleted': return PDFDocumentStatus.deleted;
      default: return PDFDocumentStatus.initial;
    }
  }
  
  /// 중요도 문자열 파싱
  static PDFDocumentImportance _parseImportance(String? importance) {
    if (importance == null) return PDFDocumentImportance.medium;
    
    switch (importance.toLowerCase()) {
      case 'low': return PDFDocumentImportance.low;
      case 'medium': return PDFDocumentImportance.medium;
      case 'high': return PDFDocumentImportance.high;
      case 'critical': return PDFDocumentImportance.critical;
      default: return PDFDocumentImportance.medium;
    }
  }
  
  /// 보안 수준 문자열 파싱
  static PDFDocumentSecurityLevel _parseSecurityLevel(String? level) {
    if (level == null) return PDFDocumentSecurityLevel.none;
    
    switch (level.toLowerCase()) {
      case 'none': return PDFDocumentSecurityLevel.none;
      case 'low': return PDFDocumentSecurityLevel.low;
      case 'medium': return PDFDocumentSecurityLevel.medium;
      case 'high': return PDFDocumentSecurityLevel.high;
      case 'restricted': return PDFDocumentSecurityLevel.restricted;
      default: return PDFDocumentSecurityLevel.none;
    }
  }

  /// 새로운 속성으로 PDFDocument 객체를 복사합니다.
  PDFDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    String? downloadUrl,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentPage,
    double? readingProgress,
    bool? isFavorite,
    bool? isSelected,
    int? readingTime,
    PDFDocumentStatus? status,
    PDFDocumentImportance? importance,
    PDFDocumentSecurityLevel? securityLevel,
    List<String>? tags,
    List<PDFBookmark>? bookmarks,
    Map<String, dynamic>? metadata,
    int? fileSize,
    String? thumbnailUrl,
    String? thumbnailPath,
    int? totalPages,
    int? size,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPage: currentPage ?? this.currentPage,
      readingProgress: readingProgress ?? this.readingProgress,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
      readingTime: readingTime ?? this.readingTime,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      securityLevel: securityLevel ?? this.securityLevel,
      tags: tags ?? this.tags,
      bookmarks: bookmarks ?? this.bookmarks,
      metadata: metadata ?? this.metadata,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      totalPages: totalPages ?? this.totalPages,
      size: size ?? this.size,
    );
  }

  @override
  String toString() {
    return 'PDFDocument(id: $id, title: $title, pageCount: $pageCount, currentPage: $currentPage, readingProgress: $readingProgress)';
  }
  
  /// JSON 문자열에서 PDFDocument 리스트를 만듭니다.
  static List<PDFDocument> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PDFDocument.fromJson(json)).toList();
  }
  
  /// PDFDocument 리스트를 JSON 문자열로 변환합니다.
  static String listToJson(List<PDFDocument> documents) {
    final jsonList = documents.map((doc) => doc.toMap()).toList();
    return json.encode(jsonList);
  }
  
  /// JSON 문자열에서 PDFDocument 리스트를 만듭니다. fromJsonList의 별칭입니다.
  static List<PDFDocument> listFromJson(String jsonString) {
    return fromJsonList(jsonString);
  }
} 