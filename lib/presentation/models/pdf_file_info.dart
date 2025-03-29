import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../domain/models/pdf_document.dart';

/// PDF 파일 정보 모델
class PdfFileInfo {
  /// 파일 경로
  final String path;
  
  /// 파일 이름
  final String name;
  
  /// 파일 크기
  final int size;
  
  /// 마지막 수정 시간
  final DateTime? lastModified;
  
  /// 썸네일 데이터
  final Uint8List? thumbnail;
  
  /// 선택 여부
  final bool isSelected;
  
  /// 즐겨찾기 여부
  final bool isFavorite;
  
  /// 고유 ID
  final String id;
  
  /// 사용자 ID
  final String userId;
  
  /// 제목
  final String title;
  
  /// 파일 이름 (원본)
  final String fileName;
  
  /// 페이지 수
  final int pageCount;
  
  /// 생성 시간
  final DateTime createdAt;
  
  /// 마지막 접근 시간
  final DateTime lastAccessedAt;
  
  /// 접근 횟수
  final int accessCount;
  
  /// 북마크 목록
  final List<dynamic> bookmarks;
  
  /// 주석 목록
  final List<dynamic> annotations;
  
  /// 파일 크기 (바이트)
  final int fileSize;
  
  /// 파일 URL (클라우드)
  final String url;
  
  /// 로컬 저장 여부
  final bool isLocal;
  
  /// 클라우드 저장 여부
  final bool isCloudStored;
  
  /// 게스트 파일 여부
  final bool isGuestFile;
  
  /// 읽기 진행 상태 (0.0 ~ 1.0)
  final double readingProgress;
  
  /// 포맷된 파일 크기 문자열
  final String formattedSize;
  
  /// 생성자
  PdfFileInfo({
    required this.path,
    required this.name,
    required this.size,
    this.lastModified,
    this.thumbnail,
    this.isSelected = false,
    this.isFavorite = false,
    this.id = '',
    this.userId = '',
    this.title = '',
    this.fileName = '',
    this.pageCount = 0,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    this.accessCount = 0,
    List<dynamic>? bookmarks,
    List<dynamic>? annotations,
    int? fileSize,
    this.url = '',
    this.isLocal = true,
    this.isCloudStored = false,
    this.isGuestFile = false,
    this.readingProgress = 0.0,
    String? formattedSize,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastAccessedAt = lastAccessedAt ?? DateTime.now(),
    bookmarks = bookmarks ?? [],
    annotations = annotations ?? [],
    fileSize = fileSize ?? size,
    formattedSize = formattedSize ?? _formatFileSize(fileSize ?? size);
  
  /// 파일 크기를 사람이 읽기 쉬운 형태로 변환
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
  
  /// 파일 인스턴스에서 생성
  factory PdfFileInfo.fromFile(File file, {
    Uint8List? thumbnail,
    bool isSelected = false,
    bool isFavorite = false,
    String? id,
    String? userId,
    String? title,
    int pageCount = 0,
  }) {
    final fileName = file.uri.pathSegments.last;
    return PdfFileInfo(
      path: file.path,
      name: fileName,
      size: file.lengthSync(),
      lastModified: file.lastModifiedSync(),
      thumbnail: thumbnail,
      isSelected: isSelected,
      isFavorite: isFavorite,
      id: id ?? '',
      userId: userId ?? '',
      title: title ?? fileName,
      fileName: fileName,
      pageCount: pageCount,
    );
  }
  
  /// 속성을 변경하여 새로운 인스턴스 생성
  PdfFileInfo copyWith({
    String? path,
    String? name,
    int? size,
    DateTime? lastModified,
    Uint8List? thumbnail,
    bool? isSelected,
    bool? isFavorite,
    String? id,
    String? userId,
    String? title,
    String? fileName,
    int? pageCount,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    List<dynamic>? bookmarks,
    List<dynamic>? annotations,
    int? fileSize,
    String? url,
    bool? isLocal,
    bool? isCloudStored,
    bool? isGuestFile,
    double? readingProgress,
    String? formattedSize,
  }) {
    return PdfFileInfo(
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      thumbnail: thumbnail ?? this.thumbnail,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      bookmarks: bookmarks ?? this.bookmarks,
      annotations: annotations ?? this.annotations,
      fileSize: fileSize ?? this.fileSize,
      url: url ?? this.url,
      isLocal: isLocal ?? this.isLocal,
      isCloudStored: isCloudStored ?? this.isCloudStored,
      isGuestFile: isGuestFile ?? this.isGuestFile,
      readingProgress: readingProgress ?? this.readingProgress,
      formattedSize: formattedSize ?? this.formattedSize,
    );
  }

  /// PDFDocument에서 PdfFileInfo 생성
  factory PdfFileInfo.fromPdfDocument(PDFDocument document) {
    final fileSize = document.fileSize;
    // 메타데이터에서 필요한 추가 정보 추출
    final metadata = document.metadata;
    
    return PdfFileInfo(
      path: document.filePath,
      name: _extractFileName(document.filePath),
      size: fileSize,
      id: document.id,
      userId: metadata['userId'] as String? ?? '',
      title: document.title,
      fileName: metadata['fileName'] as String? ?? _extractFileName(document.filePath),
      pageCount: document.pageCount,
      createdAt: document.createdAt ?? DateTime.now(),
      lastAccessedAt: document.lastAccessedAt ?? DateTime.now(),
      accessCount: metadata['accessCount'] as int? ?? 0,
      bookmarks: metadata['bookmarks'] as List<dynamic>? ?? [],
      annotations: metadata['annotations'] as List<dynamic>? ?? [],
      fileSize: fileSize,
      isFavorite: document.isFavorite,
      url: metadata['url'] as String? ?? '',
      isLocal: metadata['isLocal'] as bool? ?? true,
      isCloudStored: metadata['isCloudStored'] as bool? ?? false,
      isGuestFile: metadata['isGuestFile'] as bool? ?? false,
      readingProgress: document.readingProgress,
      formattedSize: _formatFileSize(fileSize),
    );
  }
  
  /// 파일 경로에서 파일 이름 추출
  static String _extractFileName(String filePath) {
    final parts = filePath.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }
  
  /// PdfFileInfo에서 PDFDocument 생성
  PDFDocument toPdfDocument() {
    // 추가 메타데이터로 저장할 속성들
    final metadata = <String, dynamic>{
      'userId': userId,
      'fileName': fileName,
      'accessCount': accessCount,
      'bookmarks': bookmarks,
      'annotations': annotations,
      'url': url,
      'isLocal': isLocal,
      'isCloudStored': isCloudStored,
      'isGuestFile': isGuestFile,
    };
    
    return PDFDocument(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      title: title.isEmpty ? name : title,
      filePath: path,
      fileSize: fileSize,
      pageCount: pageCount,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt,
      isFavorite: isFavorite,
      readingProgress: readingProgress,
      downloadUrl: url,
      status: isLocal 
        ? PDFDocumentStatus.added 
        : (isCloudStored ? PDFDocumentStatus.downloaded : PDFDocumentStatus.added),
      metadata: metadata,
    );
  }

  /// 마지막 접근 시간 업데이트
  PdfFileInfo updateLastAccessed() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }
} 