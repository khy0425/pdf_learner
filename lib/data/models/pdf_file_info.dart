import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF 파일 정보를 담는 모델 클래스
class PdfFileInfo {
  final String id;
  final String title;
  final String fileName;
  final String path;
  final int fileSize;
  final int pageCount;
  final String? url;
  final String userId;
  final String? firestoreId;
  final DateTime createdAt;
  final DateTime lastOpenedAt;
  final int accessCount;
  final Uint8List? bytes; // PDF 데이터 바이트 배열
  final File? file; // 로컬 파일 참조
  final String? thumbnailPath;

  PdfFileInfo({
    required this.id,
    required this.title,
    required this.fileName,
    required this.path,
    required this.fileSize,
    this.pageCount = 0,
    this.url,
    required this.userId,
    this.firestoreId,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    this.accessCount = 0,
    this.bytes,
    this.file,
    this.thumbnailPath,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastOpenedAt = lastOpenedAt ?? DateTime.now();
  
  /// 파일이 웹 URL인지 여부
  bool get isWeb => url != null && url!.isNotEmpty;
  
  /// 파일이 로컬 파일인지 여부
  bool get isLocal => url == null;
  
  /// 파일이 바이트 데이터를 가지고 있는지 여부
  bool get hasBytes => url != null;
  
  /// 파일이 게스트 사용자의 것인지 여부
  bool get isGuestFile => id.startsWith('guest_') || userId == 'guest_user';
  
  /// 파일이 클라우드에 저장되어 있는지 여부
  bool get isCloudStored => url != null && url!.contains('firebasestorage.googleapis.com');
  
  /// 파일 확장자
  String get extension => path.extension(fileName).toLowerCase();
  
  /// 파일 이름 간단한 형태 (확장자 포함)
  String get name => fileName;
  
  /// 로컬 파일 경로 (웹에서는 null)
  String? get localPath => isLocal ? path : null;
  
  /// 클라우드 URL (로컬 파일만 있는 경우 null)
  String? get cloudUrl => url;
  
  /// 파일 크기 (포맷팅된 문자열)
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// 파일 생성일 (포맷팅된 문자열)
  String get formattedDate {
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }
  
  /// PDF 바이트 데이터 읽기
  Future<Uint8List?> getBytes() async {
    if (bytes != null) {
      return bytes;
    } else if (isLocal && file != null) {
      try {
        return await file!.readAsBytes();
      } catch (e) {
        debugPrint('로컬 파일 읽기 오류: $e');
      }
    } else if (url != null) {
      try {
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        debugPrint('URL에서 파일 읽기 오류: $e');
      }
    }
    return null;
  }
  
  /// 문자열에서 바이트 데이터로 변환
  Future<Uint8List?> getBytesFromString(String? text) async {
    if (text == null) return null;
    return Future.value(Uint8List.fromList(utf8.encode(text)));
  }
  
  /// 새 속성을 가진 복사본 생성
  PdfFileInfo copyWith({
    String? id,
    String? title,
    String? fileName,
    String? path,
    int? fileSize,
    int? pageCount,
    String? url,
    String? userId,
    String? firestoreId,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    int? accessCount,
    Uint8List? bytes,
    File? file,
    String? thumbnailPath,
  }) {
    return PdfFileInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      path: path ?? this.path,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      url: url ?? this.url,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      accessCount: accessCount ?? this.accessCount,
      bytes: bytes ?? this.bytes,
      file: file ?? this.file,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
  
  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'url': url,
      'userId': userId,
      'firestoreId': firestoreId,
      'createdAt': createdAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
      'accessCount': accessCount,
      'bytes': bytes,
      'file': file,
      'thumbnailPath': thumbnailPath,
    };
  }
  
  /// JSON 역직렬화
  factory PdfFileInfo.fromJson(Map<String, dynamic> json) {
    return PdfFileInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      fileName: json['fileName'] as String,
      path: json['path'] as String,
      fileSize: json['fileSize'] as int,
      pageCount: json['pageCount'] as int? ?? 0,
      url: json['url'] as String?,
      userId: json['userId'] as String,
      firestoreId: json['firestoreId'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      lastOpenedAt: json['lastOpenedAt'] != null 
          ? DateTime.parse(json['lastOpenedAt'] as String) 
          : null,
      accessCount: json['accessCount'] as int? ?? 0,
      bytes: json['bytes'] as Uint8List?,
      file: json['file'] as File?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }
  
  /// Firestore 데이터에서 객체 생성
  factory PdfFileInfo.fromFirestore(Map<String, dynamic> data, String docId) {
    return PdfFileInfo(
      id: data['id'] as String? ?? docId,
      title: data['title'] as String? ?? 'Untitled',
      fileName: data['fileName'] as String? ?? 'document.pdf',
      path: data['path'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      pageCount: data['pageCount'] as int? ?? 0,
      url: data['url'] as String?,
      userId: data['userId'] as String? ?? '',
      firestoreId: docId,
      createdAt: data['createdAt'] != null && data['createdAt'] is Map
          ? (data['createdAt']['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['createdAt']['_seconds'] as int) * 1000)
              : DateTime.now())
          : DateTime.now(),
      lastOpenedAt: data['lastOpenedAt'] != null && data['lastOpenedAt'] is Map
          ? (data['lastOpenedAt']['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['lastOpenedAt']['_seconds'] as int) * 1000)
              : DateTime.now())
          : DateTime.now(),
      accessCount: data['accessCount'] as int? ?? 0,
      bytes: data['bytes'] as Uint8List?,
      file: data['file'] as File?,
      thumbnailPath: data['thumbnailPath'] as String?,
    );
  }
  
  /// Firestore에 저장할 데이터
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'url': url,
      'userId': userId,
      'createdAt': createdAt,
      'lastOpenedAt': lastOpenedAt,
      'accessCount': accessCount,
      'bytes': bytes,
      'file': file,
      'thumbnailPath': thumbnailPath,
    };
  }

  @override
  String toString() {
    return 'PdfFileInfo(id: $id, title: $title, fileName: $fileName, fileSize: $fileSize, pageCount: $pageCount)';
  }
} 