import 'dart:convert';
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart';

/// PDF 문서의 상태를 나타내는 열거형
enum PDFDocumentStatus {
  initial,
  loading,
  loaded,
  error,
  processing,
  completed,
  created
}

/// PDF 문서의 중요도를 나타내는 열거형
enum PDFDocumentImportance {
  low,
  medium,
  high,
  critical,
  normal
}

/// PDF 문서의 보안 수준을 나타내는 열거형
enum PDFDocumentSecurityLevel {
  none,
  basic,
  advanced,
  encrypted,
  normal
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
  
  /// 문서 크기 (바이트)
  final int fileSize;
  
  /// 문서 페이지 수
  final int pageCount;
  
  /// 문서 생성일
  final DateTime createdAt;
  
  /// 문서 수정일
  final DateTime updatedAt;
  
  /// 문서 마지막 접근일
  final DateTime? lastAccessedAt;
  
  /// 문서 마지막 수정일
  final DateTime? lastModifiedAt;
  
  /// 문서 버전
  final int version;
  
  /// 문서 암호화 여부
  final bool isEncrypted;
  
  /// 문서 암호화 키
  final String? encryptionKey;
  
  /// 문서 공유 여부
  final bool isShared;
  
  /// 문서 공유 ID
  final String? shareId;
  
  /// 문서 공유 URL
  final String? shareUrl;
  
  /// 문서 공유 만료일
  final DateTime? shareExpiresAt;
  
  /// 문서 읽기 진행률
  final double readingProgress;
  
  /// 문서 마지막 읽은 페이지
  final int lastReadPage;
  
  /// 문서 총 읽기 시간
  final int totalReadingTime;
  
  /// 문서 마지막 읽기 시간
  final int lastReadingTime;
  
  /// 문서 썸네일 URL
  final String? thumbnailUrl;
  
  /// 문서 OCR 활성화 여부
  final bool isOcrEnabled;
  
  /// 문서 OCR 언어
  final String? ocrLanguage;
  
  /// 문서 OCR 상태
  final PDFDocumentStatus? ocrStatus;
  
  /// 문서 요약 여부
  final bool isSummarized;
  
  /// 문서 현재 페이지
  final int currentPage;
  
  /// 문서 즐겨찾기 여부
  final bool isFavorite;
  
  /// 문서 선택 여부
  final bool isSelected;
  
  /// 문서 읽기 시간
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

  const PDFDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.lastModifiedAt,
    required this.version,
    required this.isEncrypted,
    this.encryptionKey,
    required this.isShared,
    this.shareId,
    this.shareUrl,
    this.shareExpiresAt,
    required this.readingProgress,
    required this.lastReadPage,
    required this.totalReadingTime,
    required this.lastReadingTime,
    this.thumbnailUrl,
    required this.isOcrEnabled,
    this.ocrLanguage,
    this.ocrStatus,
    required this.isSummarized,
    required this.currentPage,
    required this.isFavorite,
    required this.isSelected,
    required this.readingTime,
    required this.status,
    required this.importance,
    required this.securityLevel,
    required this.tags,
    required this.bookmarks,
    required this.metadata,
  });

  /// JSON 직렬화/역직렬화를 위한 팩토리 생성자
  factory PDFDocument.fromJson(dynamic json) {
    if (json is String) {
      return PDFDocument.fromMap(jsonDecode(json));
    } else if (json is Map<String, dynamic>) {
      return PDFDocument.fromMap(json);
    } else {
      throw ArgumentError('Invalid JSON type: ${json.runtimeType}');
    }
  }

  /// Map으로부터 PDFDocument 객체를 생성합니다.
  factory PDFDocument.fromMap(Map<String, dynamic> map) {
    return PDFDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      filePath: map['filePath'] as String,
      fileSize: map['fileSize'] as int,
      pageCount: map['pageCount'] as int,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      lastAccessedAt: map['lastAccessedAt'] != null 
          ? DateTime.parse(map['lastAccessedAt'] as String) 
          : null,
      lastModifiedAt: map['lastModifiedAt'] != null 
          ? DateTime.parse(map['lastModifiedAt'] as String) 
          : null,
      version: map['version'] as int,
      isEncrypted: map['isEncrypted'] as bool,
      encryptionKey: map['encryptionKey'] as String?,
      isShared: map['isShared'] as bool,
      shareId: map['shareId'] as String?,
      shareUrl: map['shareUrl'] as String?,
      shareExpiresAt: map['shareExpiresAt'] != null 
          ? DateTime.parse(map['shareExpiresAt'] as String) 
          : null,
      readingProgress: map['readingProgress'] as double,
      lastReadPage: map['lastReadPage'] as int,
      totalReadingTime: map['totalReadingTime'] as int,
      lastReadingTime: map['lastReadingTime'] as int,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      isOcrEnabled: map['isOcrEnabled'] as bool,
      ocrLanguage: map['ocrLanguage'] as String?,
      ocrStatus: map['ocrStatus'] != null 
          ? PDFDocumentStatus.values[map['ocrStatus'] as int]
          : null,
      isSummarized: map['isSummarized'] as bool,
      currentPage: map['currentPage'] as int,
      isFavorite: map['isFavorite'] as bool,
      isSelected: map['isSelected'] as bool,
      readingTime: map['readingTime'] as int,
      status: PDFDocumentStatus.values[map['status'] as int],
      importance: PDFDocumentImportance.values[map['importance'] as int],
      securityLevel: PDFDocumentSecurityLevel.values[map['securityLevel'] as int],
      tags: List<String>.from(map['tags']),
      bookmarks: map['bookmarks'] != null
          ? (map['bookmarks'] as List<dynamic>)
              .map((e) => PDFBookmark.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  /// PDFDocument 객체를 Map으로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'version': version,
      'isEncrypted': isEncrypted,
      'encryptionKey': encryptionKey,
      'isShared': isShared,
      'shareId': shareId,
      'shareUrl': shareUrl,
      'shareExpiresAt': shareExpiresAt?.toIso8601String(),
      'readingProgress': readingProgress,
      'lastReadPage': lastReadPage,
      'totalReadingTime': totalReadingTime,
      'lastReadingTime': lastReadingTime,
      'thumbnailUrl': thumbnailUrl,
      'isOcrEnabled': isOcrEnabled,
      'ocrLanguage': ocrLanguage,
      'ocrStatus': ocrStatus?.index,
      'isSummarized': isSummarized,
      'currentPage': currentPage,
      'isFavorite': isFavorite,
      'isSelected': isSelected,
      'readingTime': readingTime,
      'status': status.index,
      'importance': importance.index,
      'securityLevel': securityLevel.index,
      'tags': tags,
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// PDFDocument 객체를 JSON 문자열로 변환합니다.
  String toJson() => jsonEncode(toMap());

  static List<PDFDocument> listFromJson(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => PDFDocument.fromJson(item)).toList();
  }

  static String listToJson(List<PDFDocument> documents) {
    final jsonList = documents.map((doc) => doc.toJson()).toList();
    return json.encode(jsonList);
  }

  /// 기본 PDF 문서 생성
  factory PDFDocument.createDefault() {
    return PDFDocument(
      id: '',
      title: '',
      description: '',
      filePath: '',
      fileSize: 0,
      pageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      isEncrypted: false,
      isShared: false,
      readingProgress: 0.0,
      lastReadPage: 0,
      totalReadingTime: 0,
      lastReadingTime: 0,
      isOcrEnabled: false,
      isSummarized: false,
      currentPage: 0,
      isFavorite: false,
      isSelected: false,
      readingTime: 0,
      status: PDFDocumentStatus.initial,
      importance: PDFDocumentImportance.medium,
      securityLevel: PDFDocumentSecurityLevel.none,
      tags: [],
      bookmarks: [],
      metadata: {},
    );
  }
  
  /// 복사본 생성 
  PDFDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    int? fileSize,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    DateTime? lastModifiedAt,
    int? version,
    bool? isEncrypted,
    String? encryptionKey,
    bool? isShared,
    String? shareId,
    String? shareUrl,
    DateTime? shareExpiresAt,
    double? readingProgress,
    int? lastReadPage,
    int? totalReadingTime,
    int? lastReadingTime,
    String? thumbnailUrl,
    bool? isOcrEnabled,
    String? ocrLanguage,
    PDFDocumentStatus? ocrStatus,
    bool? isSummarized,
    int? currentPage,
    bool? isFavorite,
    bool? isSelected,
    int? readingTime,
    PDFDocumentStatus? status,
    PDFDocumentImportance? importance,
    PDFDocumentSecurityLevel? securityLevel,
    List<String>? tags,
    List<PDFBookmark>? bookmarks,
    Map<String, dynamic>? metadata,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      isShared: isShared ?? this.isShared,
      shareId: shareId ?? this.shareId,
      shareUrl: shareUrl ?? this.shareUrl,
      shareExpiresAt: shareExpiresAt ?? this.shareExpiresAt,
      readingProgress: readingProgress ?? this.readingProgress,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      lastReadingTime: lastReadingTime ?? this.lastReadingTime,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isOcrEnabled: isOcrEnabled ?? this.isOcrEnabled,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      isSummarized: isSummarized ?? this.isSummarized,
      currentPage: currentPage ?? this.currentPage,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
      readingTime: readingTime ?? this.readingTime,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      securityLevel: securityLevel ?? this.securityLevel,
      tags: tags ?? this.tags,
      bookmarks: bookmarks ?? this.bookmarks,
      metadata: metadata ?? this.metadata,
    );
  }
} 