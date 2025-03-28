import '../../domain/models/pdf_document.dart';
import 'dart:convert';
import '../../core/base/result.dart';

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
  final String author;
  final String url;
  final double progress;
  final int accessCount;
  final String source;
  final DateTime? lastAccessedAt;

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
    this.author = '',
    this.url = '',
    this.progress = 0.0,
    this.accessCount = 0,
    this.source = 'local',
    this.lastAccessedAt,
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
      author: json['author'] as String? ?? '',
      url: json['url'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      accessCount: json['accessCount'] as int? ?? 0,
      source: json['source'] as String? ?? 'local',
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
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
      'author': author,
      'url': url,
      'progress': progress,
      'accessCount': accessCount,
      'source': source,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }

  PDFDocument toDomain() {
    return PDFDocument(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      url: url,
      totalPages: totalPages,
      currentPage: currentPage,
      progress: progress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastAccessedAt: lastAccessedAt ?? createdAt,
      accessCount: accessCount,
      source: source == 'remote'
          ? PDFDocumentSource.remote
          : PDFDocumentSource.local,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'url': url,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': (lastAccessedAt ?? createdAt).toIso8601String(),
      'accessCount': accessCount,
      'source': source,
    };
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
      author: document.author,
      url: document.url,
      progress: document.progress,
      accessCount: document.accessCount,
      source: document.source == PDFDocumentSource.remote ? 'remote' : 'local',
      lastAccessedAt: document.lastAccessedAt,
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

  // Result 클래스를 사용하는 변환 메서드
  static Result<PDFDocumentModel> fromDomainResult(PDFDocument document) {
    try {
      final model = PDFDocumentModel.fromDomain(document);
      return Result.success(model);
    } catch (e) {
      return Result.failure(Exception('도메인 모델 변환 실패: $e'));
    }
  }
  
  Result<PDFDocument> toDomainResult() {
    try {
      final domain = toDomain();
      return Result.success(domain);
    } catch (e) {
      return Result.failure(Exception('데이터 모델 변환 실패: $e'));
    }
  }
  
  static Result<List<PDFDocumentModel>> fromDomainListResult(List<PDFDocument> documents) {
    try {
      final models = documents.map((doc) => PDFDocumentModel.fromDomain(doc)).toList();
      return Result.success(models);
    } catch (e) {
      return Result.failure(Exception('도메인 모델 리스트 변환 실패: $e'));
    }
  }
  
  static Result<List<PDFDocument>> toDomainListResult(List<PDFDocumentModel> models) {
    try {
      final domains = models.map((model) => model.toDomain()).toList();
      return Result.success(domains);
    } catch (e) {
      return Result.failure(Exception('데이터 모델 리스트 변환 실패: $e'));
    }
  }
  
  // 문자열에서 변환
  static Result<PDFDocumentModel> fromJsonStringResult(String jsonString) {
    try {
      final model = PDFDocumentModel.fromJsonString(jsonString);
      return Result.success(model);
    } catch (e) {
      return Result.failure(Exception('JSON 문자열 변환 실패: $e'));
    }
  }
  
  // JSON 문자열로 변환
  Result<String> toJsonStringResult() {
    try {
      final jsonMap = toJson();
      final jsonString = jsonEncode(jsonMap);
      return Result.success(jsonString);
    } catch (e) {
      return Result.failure(Exception('JSON 문자열 변환 실패: $e'));
    }
  }
} 