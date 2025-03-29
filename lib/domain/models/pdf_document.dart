import 'dart:convert';

/// PDF 문서 상태
enum PDFDocumentStatus {
  /// 추가됨
  added,
  
  /// 업데이트됨
  updated,
  
  /// 읽는 중
  reading,
  
  /// 완료됨
  completed,
  
  /// 보관됨
  archived,
  
  /// 삭제됨
  deleted,
  
  /// 다운로드됨
  downloaded,
  
  /// 초기 상태
  initial,
  
  /// 다운로드 중
  downloading,
  
  /// 생성됨
  created,
  
  /// 가져오기됨
  imported
}

/// PDF 소스 타입
enum PDFDocumentSource {
  /// 로컬
  local,
  
  /// 원격
  remote
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
  secret,
  
  /// 없음
  none,
  
  /// 낮음
  low,
  
  /// 중간
  medium,
  
  /// 높음
  high
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
class PDFDocument {
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
  final DateTime createdAt;
  
  /// 마지막 업데이트 시간
  final DateTime updatedAt;
  
  /// 마지막 접근 시간
  final DateTime? lastAccessedAt;
  
  /// 사용자 지정 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 로컬 파일 경로
  final String localPath;
  
  /// 선택 여부
  final bool isSelected;
  
  /// 중요도
  final PDFImportanceLevel importance;
  
  /// 보안 수준
  final PDFSecurityLevel securityLevel;
  
  /// 총 페이지 수 (추가 필드)
  final int totalPages;
  
  /// 현재 페이지 (추가 필드)
  final int currentPage;
  
  /// 읽기 총 시간 (초)
  final int readingTime;
  
  /// 진행률
  final double progress;
  
  /// 접근 횟수
  final int accessCount;
  
  /// 출처 (로컬 또는 원격)
  final PDFDocumentSource source;
  
  /// URL
  final String url;
  
  /// 썸네일 URL
  final String thumbnailUrl;
  
  /// 마지막 열람 시간
  DateTime get lastOpened => lastAccessedAt ?? updatedAt;

  /// PDF 문서 생성자
  PDFDocument({
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
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastAccessedAt,
    this.metadata = const {},
    this.localPath = '',
    this.isSelected = false,
    this.importance = PDFImportanceLevel.medium,
    this.securityLevel = PDFSecurityLevel.none,
    this.totalPages = 0,
    this.currentPage = 0,
    this.readingTime = 0,
    this.progress = 0.0,
    this.accessCount = 0,
    this.source = PDFDocumentSource.local,
    this.url = '',
    this.thumbnailUrl = '',
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
  
  /// 복사본 생성 메서드
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
    String? localPath,
    bool? isSelected,
    PDFImportanceLevel? importance,
    PDFSecurityLevel? securityLevel,
    int? totalPages,
    int? currentPage,
    int? readingTime,
    double? progress,
    int? accessCount,
    PDFDocumentSource? source,
    String? url,
    String? thumbnailUrl,
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
      localPath: localPath ?? this.localPath,
      isSelected: isSelected ?? this.isSelected,
      importance: importance ?? this.importance,
      securityLevel: securityLevel ?? this.securityLevel,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      readingTime: readingTime ?? this.readingTime,
      progress: progress ?? this.progress,
      accessCount: accessCount ?? this.accessCount,
      source: source ?? this.source,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  /// 문서 정보를 JSON 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
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
      'status': status.toString().split('.').last,
      'tags': tags,
      'category': category.toString().split('.').last,
      'accessLevel': accessLevel.toString().split('.').last,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'metadata': metadata,
      'localPath': localPath,
      'isSelected': isSelected,
      'importance': importance.toString().split('.').last,
      'securityLevel': securityLevel.toString().split('.').last,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'readingTime': readingTime,
      'progress': progress,
      'accessCount': accessCount,
      'source': source.toString().split('.').last,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// JSON에서 PDF 문서 생성
  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    final DateTime? createdAtParsed = json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String) 
        : null;
        
    final DateTime? updatedAtParsed = json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null;
        
    final DateTime? lastAccessedAtParsed = json['lastAccessedAt'] != null 
        ? DateTime.parse(json['lastAccessedAt'] as String) 
        : null;
        
    return PDFDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 0,
      lastReadPage: json['lastReadPage'] as int? ?? 0,
      readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      fileHash: json['fileHash'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      status: _parseDocumentStatus(json['status']),
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : const [],
      category: _parseCategory(json['category']),
      accessLevel: _parseAccessLevel(json['accessLevel']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: createdAtParsed,
      updatedAt: updatedAtParsed,
      lastAccessedAt: lastAccessedAtParsed,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : const {},
      localPath: json['localPath'] as String? ?? '',
      isSelected: json['isSelected'] as bool? ?? false,
      importance: _parseImportanceLevel(json['importance']),
      securityLevel: _parseSecurityLevel(json['securityLevel']),
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      readingTime: json['readingTime'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      accessCount: json['accessCount'] as int? ?? 0,
      source: _parseDocumentSource(json['source']),
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );
  }

  /// JSON 문자열에서 PDF 문서 생성
  factory PDFDocument.fromJsonString(String jsonString) {
    return PDFDocument.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// 빈 문서 생성
  factory PDFDocument.empty() {
    return PDFDocument(
      id: '',
      title: '',
      filePath: '',
    );
  }

  @override
  String toString() {
    return 'PDFDocument(id: $id, title: $title, filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PDFDocument &&
      other.id == id &&
      other.title == title &&
      other.filePath == filePath;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ filePath.hashCode;
  }

  // 문자열에서 enum 값 파싱 (private helper methods)
  static PDFDocumentStatus _parseDocumentStatus(dynamic value) {
    if (value == null) return PDFDocumentStatus.initial;
    if (value is PDFDocumentStatus) return value;
    
    final String statusStr = value.toString().toLowerCase();
    return PDFDocumentStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == statusStr,
      orElse: () => PDFDocumentStatus.initial,
    );
  }

  static PDFDocumentSource _parseDocumentSource(dynamic value) {
    if (value == null) return PDFDocumentSource.local;
    if (value is PDFDocumentSource) return value;
    
    final String sourceStr = value.toString().toLowerCase();
    return PDFDocumentSource.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == sourceStr,
      orElse: () => PDFDocumentSource.local,
    );
  }

  static PDFImportanceLevel _parseImportanceLevel(dynamic value) {
    if (value == null) return PDFImportanceLevel.medium;
    if (value is PDFImportanceLevel) return value;
    
    final String importanceStr = value.toString().toLowerCase();
    return PDFImportanceLevel.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == importanceStr,
      orElse: () => PDFImportanceLevel.medium,
    );
  }

  static PDFSecurityLevel _parseSecurityLevel(dynamic value) {
    if (value == null) return PDFSecurityLevel.none;
    if (value is PDFSecurityLevel) return value;
    
    final String securityStr = value.toString().toLowerCase();
    return PDFSecurityLevel.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == securityStr,
      orElse: () => PDFSecurityLevel.none,
    );
  }

  static PDFCategory _parseCategory(dynamic value) {
    if (value == null) return PDFCategory.document;
    if (value is PDFCategory) return value;
    
    final String categoryStr = value.toString().toLowerCase();
    return PDFCategory.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == categoryStr,
      orElse: () => PDFCategory.document,
    );
  }

  static PDFAccessLevel _parseAccessLevel(dynamic value) {
    if (value == null) return PDFAccessLevel.private;
    if (value is PDFAccessLevel) return value;
    
    final String accessLevelStr = value.toString().toLowerCase();
    return PDFAccessLevel.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == accessLevelStr,
      orElse: () => PDFAccessLevel.private,
    );
  }

  /// Map에서 PDFDocument 객체 생성
  factory PDFDocument.fromMap(Map<String, dynamic> map) {
    final createdAtParsed = map['createdAt'] != null 
        ? map['createdAt'] is DateTime
            ? map['createdAt'] as DateTime
            : map['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
                : DateTime.parse(map['createdAt'] as String)
        : DateTime.now();
    
    final updatedAtParsed = map['updatedAt'] != null 
        ? map['updatedAt'] is DateTime
            ? map['updatedAt'] as DateTime
            : map['updatedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
                : DateTime.parse(map['updatedAt'] as String)
        : createdAtParsed;
    
    final lastAccessedAtParsed = map['lastAccessedAt'] != null 
        ? map['lastAccessedAt'] is DateTime
            ? map['lastAccessedAt'] as DateTime
            : map['lastAccessedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'] as int)
                : DateTime.parse(map['lastAccessedAt'] as String)
        : createdAtParsed;
    
    // thumbnailPath 필드명 처리 - thumbnail 또는 thumbnailPath 둘 다 허용
    String thumbnailPath = '';
    if (map['thumbnailPath'] != null) {
      thumbnailPath = map['thumbnailPath'] as String;
    } else if (map['thumbnail'] != null) {
      thumbnailPath = map['thumbnail'] as String;
    }
    
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
      thumbnailPath: thumbnailPath,
      fileHash: map['fileHash'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      status: _statusFromString(map['status'] as String?),
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      category: _categoryFromString(map['category'] as String?),
      accessLevel: _accessLevelFromString(map['accessLevel'] as String?),
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: createdAtParsed,
      updatedAt: updatedAtParsed,
      lastAccessedAt: lastAccessedAtParsed,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<dynamic, dynamic>? ?? {}),
      localPath: map['localPath'] as String? ?? '',
      isSelected: map['isSelected'] as bool? ?? false,
      importance: _importanceFromString(map['importance'] as String?),
      securityLevel: _securityLevelFromString(map['securityLevel'] as String?),
      totalPages: map['totalPages'] as int? ?? (map['pageCount'] as int? ?? 0),
      currentPage: map['currentPage'] as int? ?? 0,
      readingTime: map['readingTime'] as int? ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      accessCount: map['accessCount'] as int? ?? 0,
      source: _sourceFromString(map['source'] as String?),
      url: map['url'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
    );
  }

  /// PDFDocument 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
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
      'thumbnail': thumbnailPath, // 하위 호환성을 위해 추가
      'fileHash': fileHash,
      'downloadUrl': downloadUrl,
      'status': _statusToString(status),
      'tags': tags,
      'category': _categoryToString(category),
      'accessLevel': _accessLevelToString(accessLevel),
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'metadata': metadata,
      'localPath': localPath,
      'isSelected': isSelected,
      'importance': _importanceToString(importance),
      'securityLevel': _securityLevelToString(securityLevel),
      'totalPages': totalPages,
      'currentPage': currentPage,
      'readingTime': readingTime,
      'progress': progress,
      'accessCount': accessCount,
      'source': _sourceToString(source),
      'url': url,
      'thumbnailUrl': thumbnailUrl,
    };
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
    case PDFDocumentStatus.updated:
      return 'updated';
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
    case PDFDocumentStatus.imported:
      return 'imported';
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
    case 'updated':
      return PDFDocumentStatus.updated;
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
    case 'imported':
      return PDFDocumentStatus.imported;
    default:
      return PDFDocumentStatus.added;
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

/// 문자열에서 중요도 변환
PDFImportanceLevel _importanceFromString(String? importance) {
  if (importance == null) return PDFImportanceLevel.medium;
  
  switch (importance.toLowerCase()) {
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

/// 보안 수준을 문자열로 변환
String _securityLevelToString(PDFSecurityLevel level) {
  switch (level) {
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

/// 문자열에서 보안 수준 변환
PDFSecurityLevel _securityLevelFromString(String? level) {
  if (level == null) return PDFSecurityLevel.none;
  
  switch (level.toLowerCase()) {
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

/// 소스를 문자열로 변환
String _sourceToString(PDFDocumentSource source) {
  switch (source) {
    case PDFDocumentSource.local:
      return 'local';
    case PDFDocumentSource.remote:
      return 'remote';
    default:
      return 'local';
  }
}

/// 문자열에서 소스 변환
PDFDocumentSource _sourceFromString(String? source) {
  if (source == null) return PDFDocumentSource.local;
  
  switch (source.toLowerCase()) {
    case 'local':
      return PDFDocumentSource.local;
    case 'remote':
      return PDFDocumentSource.remote;
    default:
      return PDFDocumentSource.local;
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
  
  /// 진행률 계산
  double get calculatedProgress {
    if (pageCount <= 0) return 0.0;
    return lastReadPage / pageCount;
  }
  
  /// 진행률 백분율 문자열
  String get progressPercentage {
    return '${(calculatedProgress * 100).round()}%';
  }
} 