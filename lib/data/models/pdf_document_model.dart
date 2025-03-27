import '../../domain/models/pdf_document.dart';
import 'dart:convert';

class PDFDocumentModel {
  final String id;
  final String title;
  final String description;
  final String filePath;
  final String downloadUrl;
  final int pageCount;
  final String thumbnailUrl;
  final int totalPages;
  final int currentPage;
  final int size;
  final int fileSize;
  final double readingProgress;
  final int readingTime;
  final bool isFavorite;
  final bool isSelected;
  final PDFDocumentStatus status;
  final PDFDocumentImportance importance;
  final PDFDocumentSecurityLevel securityLevel;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PDFDocumentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.filePath,
    required this.downloadUrl,
    required this.pageCount,
    this.thumbnailUrl = '',
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
    this.createdAt,
    this.updatedAt,
  });

  factory PDFDocumentModel.fromJson(Map<String, dynamic> json) {
    return PDFDocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      filePath: json['filePath'] as String,
      downloadUrl: json['downloadUrl'] as String,
      pageCount: json['pageCount'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
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
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'pageCount': pageCount,
      'thumbnailUrl': thumbnailUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'size': size,
      'fileSize': fileSize,
      'readingProgress': readingProgress,
      'readingTime': readingTime,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
      'status': status.toString().split('.').last,
      'importance': importance.toString().split('.').last,
      'securityLevel': securityLevel.toString().split('.').last,
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PDFDocument toDomain() {
    return PDFDocument(
      id: id,
      title: title,
      description: description,
      filePath: filePath,
      downloadUrl: downloadUrl,
      pageCount: pageCount,
      thumbnailUrl: thumbnailUrl,
      totalPages: totalPages,
      currentPage: currentPage,
      size: size,
      fileSize: fileSize,
      readingProgress: readingProgress,
      readingTime: readingTime,
      isFavorite: isFavorite,
      isSelected: isSelected,
      status: status,
      importance: importance,
      securityLevel: securityLevel,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookmarks: [], // 북마크는 별도로 관리
    );
  }

  static PDFDocumentModel fromDomain(PDFDocument document) {
    return PDFDocumentModel(
      id: document.id,
      title: document.title,
      description: document.description,
      filePath: document.filePath,
      downloadUrl: document.downloadUrl,
      pageCount: document.pageCount,
      thumbnailUrl: document.thumbnailUrl,
      totalPages: document.totalPages,
      currentPage: document.currentPage,
      size: document.size,
      fileSize: document.fileSize,
      readingProgress: document.readingProgress,
      readingTime: document.readingTime,
      isFavorite: document.isFavorite,
      isSelected: document.isSelected,
      status: document.status,
      importance: document.importance,
      securityLevel: document.securityLevel,
      tags: document.tags,
      metadata: document.metadata,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    );
  }
  
  // String으로 된 JSON을 파싱하여 모델 생성
  static PDFDocumentModel fromJsonString(String json) {
    return PDFDocumentModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
  
  /// 상태 문자열 파싱
  static PDFDocumentStatus _parseStatus(dynamic status) {
    if (status == null) return PDFDocumentStatus.initial;
    
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
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
  static PDFDocumentImportance _parseImportance(dynamic importance) {
    if (importance == null) return PDFDocumentImportance.medium;
    
    final importanceStr = importance.toString().toLowerCase();
    switch (importanceStr) {
      case 'low': return PDFDocumentImportance.low;
      case 'medium': return PDFDocumentImportance.medium;
      case 'high': return PDFDocumentImportance.high;
      case 'critical': return PDFDocumentImportance.critical;
      default: return PDFDocumentImportance.medium;
    }
  }
  
  /// 보안 수준 문자열 파싱
  static PDFDocumentSecurityLevel _parseSecurityLevel(dynamic level) {
    if (level == null) return PDFDocumentSecurityLevel.none;
    
    final levelStr = level.toString().toLowerCase();
    switch (levelStr) {
      case 'none': return PDFDocumentSecurityLevel.none;
      case 'low': return PDFDocumentSecurityLevel.low;
      case 'medium': return PDFDocumentSecurityLevel.medium;
      case 'high': return PDFDocumentSecurityLevel.high;
      case 'restricted': return PDFDocumentSecurityLevel.restricted;
      default: return PDFDocumentSecurityLevel.none;
    }
  }
} 