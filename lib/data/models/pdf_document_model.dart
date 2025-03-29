import '../../domain/models/pdf_document.dart';
import 'dart:convert';
import '../../core/base/result.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF 문서 데이터 모델
class PDFDocumentModel {
  /// 문서 ID
  final String id;
  
  /// 문서 제목
  final String title;
  
  /// 문서 설명
  final String description;
  
  /// 파일 경로
  final String filePath;
  
  /// 다운로드 URL
  final String downloadUrl;
  
  /// 썸네일 경로
  final String thumbnailPath;
  
  /// 작성자
  final String author;
  
  /// 파일 크기 (바이트)
  final int fileSize;
  
  /// 페이지 수
  final int pageCount;
  
  /// 총 페이지 수
  final int totalPages;
  
  /// 현재 페이지
  final int currentPage;
  
  /// 상태
  final PDFDocumentStatus status;
  
  /// 생성 시간
  final DateTime? createdAt;
  
  /// 업데이트 시간
  final DateTime? updatedAt;
  
  /// 마지막 접근 시간
  final DateTime? lastAccessedAt;
  
  /// 중요도
  final PDFImportanceLevel importance;
  
  /// 보안 수준
  final PDFSecurityLevel securityLevel;
  
  /// 즐겨찾기 여부
  final bool isFavorite;
  
  /// 선택됨 여부
  final bool isSelected;
  
  /// 태그 목록
  final List<String> tags;
  
  /// 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 출처
  final String source;
  
  /// 생성자
  PDFDocumentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.filePath,
    required this.downloadUrl,
    required this.pageCount,
    this.thumbnailPath = '',
    this.totalPages = 0,
    this.currentPage = 0,
    this.fileSize = 0,
    this.author = '',
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.isFavorite = false,
    this.isSelected = false,
    this.status = PDFDocumentStatus.added,
    this.importance = PDFImportanceLevel.medium,
    this.securityLevel = PDFSecurityLevel.none,
    this.tags = const [],
    this.metadata = const {},
    this.source = 'local',
  });
  
  /// JSON 맵에서 모델 생성
  factory PDFDocumentModel.fromJson(Map<String, dynamic> json) {
    return PDFDocumentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      fileSize: json['fileSize'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      status: _parseStatus(json['status']),
      importance: _parseImportance(json['importance']),
      securityLevel: _parseSecurityLevel(json['securityLevel']),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
      source: json['source'] as String? ?? 'local',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is Timestamp 
              ? (json['updatedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(json['updatedAt'].toString()))
          : null,
      author: json['author'] as String? ?? '',
      lastAccessedAt: json['lastAccessedAt'] != null 
          ? (json['lastAccessedAt'] is Timestamp 
              ? (json['lastAccessedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(json['lastAccessedAt'].toString()))
          : null,
    );
  }
  
  /// JSON 문자열에서 모델 생성
  factory PDFDocumentModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return PDFDocumentModel.fromJson(json);
  }
  
  /// 도메인 모델에서 데이터 모델 생성
  factory PDFDocumentModel.fromDomain(PDFDocument document) {
    return PDFDocumentModel(
      id: document.id,
      title: document.title,
      description: document.description,
      filePath: document.filePath,
      downloadUrl: document.downloadUrl,
      pageCount: document.pageCount,
      thumbnailPath: document.thumbnailPath,
      totalPages: document.totalPages,
      currentPage: document.currentPage,
      fileSize: document.fileSize,
      author: document.author,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      lastAccessedAt: document.lastAccessedAt,
      isFavorite: document.isFavorite,
      isSelected: document.isSelected,
      status: document.status,
      importance: document.importance,
      securityLevel: document.securityLevel,
      tags: document.tags,
      metadata: document.metadata,
      source: document.source.toString().split('.').last,
    );
  }
  
  /// 도메인 모델로 변환
  PDFDocument toDomain() {
    return PDFDocument(
      id: id,
      title: title,
      description: description,
      filePath: filePath,
      downloadUrl: downloadUrl,
      pageCount: pageCount,
      thumbnailPath: thumbnailPath,
      totalPages: totalPages,
      currentPage: currentPage,
      fileSize: fileSize,
      author: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastAccessedAt: lastAccessedAt,
      isFavorite: isFavorite,
      isSelected: isSelected,
      status: status,
      importance: importance,
      securityLevel: securityLevel,
      tags: tags,
      metadata: metadata,
      source: _sourceFromString(source),
      readingProgress: 0.0,
      readingTime: 0,
      lastReadPage: 0,
      accessCount: 0,
      accessLevel: PDFAccessLevel.private,
      category: PDFCategory.document,
      progress: 0.0,
      url: downloadUrl,
      thumbnailUrl: thumbnailPath,
    );
  }
  
  /// JSON 맵으로 변환
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'pageCount': pageCount,
      'thumbnailPath': thumbnailPath,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'fileSize': fileSize,
      'author': author,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
      'status': _statusToString(status),
      'importance': _importanceToString(importance),
      'securityLevel': _securityLevelToString(securityLevel),
      'tags': tags,
      'metadata': metadata,
      'source': source,
    };
    
    if (createdAt != null) {
      data['createdAt'] = createdAt!.toIso8601String();
    }
    
    if (updatedAt != null) {
      data['updatedAt'] = updatedAt!.toIso8601String();
    }
    
    if (lastAccessedAt != null) {
      data['lastAccessedAt'] = lastAccessedAt!.toIso8601String();
    }
    
    return data;
  }
  
  /// JSON 문자열로 변환
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  /// Result 클래스를 사용한 도메인 변환
  Result<PDFDocument> toDomainResult() {
    try {
      final domain = toDomain();
      return Result.success(domain);
    } catch (e) {
      return Result.failure(Exception('데이터 모델 변환 실패: $e'));
    }
  }
  
  /// Result 클래스를 사용한 JSON 문자열 변환
  Result<String> toJsonStringResult() {
    try {
      final jsonMap = toJson();
      final jsonString = jsonEncode(jsonMap);
      return Result.success(jsonString);
    } catch (e) {
      return Result.failure(Exception('JSON 문자열 변환 실패: $e'));
    }
  }
  
  /// 도메인 모델에서 데이터 모델로 변환 (Result 반환)
  static Result<PDFDocumentModel> fromDomainResult(PDFDocument document) {
    try {
      final model = PDFDocumentModel.fromDomain(document);
      return Result.success(model);
    } catch (e) {
      return Result.failure(Exception('도메인 모델 변환 실패: $e'));
    }
  }
  
  /// 도메인 모델 리스트에서 데이터 모델 리스트로 변환
  static Result<List<PDFDocumentModel>> fromDomainListResult(List<PDFDocument> documents) {
    try {
      final models = documents.map((doc) => PDFDocumentModel.fromDomain(doc)).toList();
      return Result.success(models);
    } catch (e) {
      return Result.failure(Exception('도메인 모델 리스트 변환 실패: $e'));
    }
  }
  
  /// 데이터 모델 리스트에서 도메인 모델 리스트로 변환
  static Result<List<PDFDocument>> toDomainListResult(List<PDFDocumentModel> models) {
    try {
      final domains = models.map((model) => model.toDomain()).toList();
      return Result.success(domains);
    } catch (e) {
      return Result.failure(Exception('데이터 모델 리스트 변환 실패: $e'));
    }
  }
  
  /// JSON 문자열에서 모델 생성 (Result 반환)
  static Result<PDFDocumentModel> fromJsonStringResult(String jsonString) {
    try {
      final model = PDFDocumentModel.fromJsonString(jsonString);
      return Result.success(model);
    } catch (e) {
      return Result.failure(Exception('JSON 문자열 변환 실패: $e'));
    }
  }
}

/// 상태 문자열 파싱
PDFDocumentStatus _parseStatus(dynamic status) {
  if (status == null) return PDFDocumentStatus.added;
  
  final String statusStr = status.toString().toLowerCase();
  
  switch (statusStr) {
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
    case 'initial':
      return PDFDocumentStatus.initial;
    case 'downloading':
      return PDFDocumentStatus.downloading;
    case 'created':
      return PDFDocumentStatus.created;
    default:
      return PDFDocumentStatus.added;
  }
}

/// 중요도 문자열 파싱
PDFImportanceLevel _parseImportance(dynamic importance) {
  if (importance == null) return PDFImportanceLevel.medium;
  
  final String importanceStr = importance.toString().toLowerCase();
  
  switch (importanceStr) {
    case 'low':
      return PDFImportanceLevel.low;
    case 'medium':
      return PDFImportanceLevel.medium;
    case 'high':
      return PDFImportanceLevel.high;
    case 'critical':
      return PDFImportanceLevel.critical;
    default:
      return PDFImportanceLevel.medium;
  }
}

/// 보안 수준 문자열 파싱
PDFSecurityLevel _parseSecurityLevel(dynamic securityLevel) {
  if (securityLevel == null) return PDFSecurityLevel.none;
  
  final String securityLevelStr = securityLevel.toString().toLowerCase();
  
  switch (securityLevelStr) {
    case 'none':
      return PDFSecurityLevel.none;
    case 'low':
      return PDFSecurityLevel.low;
    case 'medium':
      return PDFSecurityLevel.medium;
    case 'high':
      return PDFSecurityLevel.high;
    case 'public':
      return PDFSecurityLevel.public;
    case 'restricted':
      return PDFSecurityLevel.restricted;
    case 'confidential':
      return PDFSecurityLevel.confidential;
    case 'secret':
      return PDFSecurityLevel.secret;
    default:
      return PDFSecurityLevel.none;
  }
}

/// 상태를 문자열로 변환
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
    case PDFDocumentStatus.initial:
      return 'initial';
    case PDFDocumentStatus.downloading:
      return 'downloading';
    case PDFDocumentStatus.created:
      return 'created';
    default:
      return 'added';
  }
}

/// 중요도를 문자열로 변환
String _importanceToString(PDFImportanceLevel importance) {
  switch (importance) {
    case PDFImportanceLevel.low:
      return 'low';
    case PDFImportanceLevel.medium:
      return 'medium';
    case PDFImportanceLevel.high:
      return 'high';
    case PDFImportanceLevel.critical:
      return 'critical';
    default:
      return 'medium';
  }
}

/// 보안 수준을 문자열로 변환
String _securityLevelToString(PDFSecurityLevel securityLevel) {
  switch (securityLevel) {
    case PDFSecurityLevel.none:
      return 'none';
    case PDFSecurityLevel.low:
      return 'low';
    case PDFSecurityLevel.medium:
      return 'medium';
    case PDFSecurityLevel.high:
      return 'high';
    case PDFSecurityLevel.public:
      return 'public';
    case PDFSecurityLevel.restricted:
      return 'restricted';
    case PDFSecurityLevel.confidential:
      return 'confidential';
    case PDFSecurityLevel.secret:
      return 'secret';
    default:
      return 'none';
  }
}

/// 소스 문자열에서 PDFDocumentSource 변환
PDFDocumentSource _sourceFromString(String source) {
  switch (source.toLowerCase()) {
    case 'remote':
      return PDFDocumentSource.remote;
    case 'local':
    default:
      return PDFDocumentSource.local;
  }
} 