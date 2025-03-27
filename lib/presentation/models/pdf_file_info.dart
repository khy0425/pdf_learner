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
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastAccessedAt = lastAccessedAt ?? DateTime.now(),
    this.bookmarks = bookmarks ?? [],
    this.annotations = annotations ?? [],
    this.fileSize = fileSize ?? size;
  
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
    );
  }

  /// PDFDocument에서 PdfFileInfo 생성
  factory PdfFileInfo.fromPdfDocument(PDFDocument document) {
    return PdfFileInfo(
      path: document.filePath,
      name: document.title,
      size: document.fileSize ?? 0,
      id: document.id,
      userId: document.userId ?? '',
      title: document.title,
      fileName: document.fileName ?? document.title,
      pageCount: document.pageCount ?? 0,
      createdAt: document.createdAt,
      lastAccessedAt: document.lastAccessedAt,
      accessCount: document.accessCount ?? 0,
      bookmarks: document.bookmarks ?? [],
      annotations: document.annotations ?? [],
      fileSize: document.fileSize ?? 0,
      isFavorite: document.isFavorite ?? false,
    );
  }
  
  /// PdfFileInfo에서 PDFDocument 생성
  PDFDocument toPdfDocument() {
    return PDFDocument(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      title: title.isEmpty ? name : title,
      filePath: path,
      userId: userId,
      fileName: fileName.isEmpty ? name : fileName,
      pageCount: pageCount,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt,
      accessCount: accessCount,
      bookmarks: bookmarks,
      annotations: annotations,
      fileSize: fileSize,
      isFavorite: isFavorite,
    );
  }

  /// 마지막 접근 시간 업데이트
  PdfFileInfo updateLastAccessed() {
    return this.copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: this.accessCount + 1,
    );
  }
} 