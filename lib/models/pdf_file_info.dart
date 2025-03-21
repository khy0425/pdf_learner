import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF 파일 정보를 담는 모델 클래스
class PdfFileInfo {
  final String id;
  final String fileName;
  final String? url;
  final File? file;
  final DateTime createdAt;
  final int fileSize;
  final Uint8List? bytes;
  final String userId;
  final String? firestoreId;
  final int? pageCount;
  
  /// 생성자
  PdfFileInfo({
    required this.id,
    required this.fileName,
    this.url,
    this.file,
    required this.createdAt,
    required this.fileSize,
    this.bytes,
    required this.userId,
    this.firestoreId,
    this.pageCount,
  });
  
  /// 파일이 웹 URL인지 여부
  bool get isWeb => url != null && url!.isNotEmpty;
  
  /// 파일이 로컬 파일인지 여부
  bool get isLocal => file != null;
  
  /// 파일이 바이트 데이터를 가지고 있는지 여부
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  
  /// 파일이 게스트 사용자의 것인지 여부
  bool get isGuestFile => id.startsWith('guest_') || userId == 'guest_user';
  
  /// 파일이 클라우드에 저장되어 있는지 여부
  bool get isCloudStored => url != null && url!.contains('firebasestorage.googleapis.com');
  
  /// 파일 확장자
  String get extension => path.extension(fileName).toLowerCase();
  
  /// 파일 이름 간단한 형태 (확장자 포함)
  String get name => fileName;
  
  /// 로컬 파일 경로 (웹에서는 null)
  String? get localPath => isLocal ? file?.path : null;
  
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
  Future<Uint8List> readAsBytes() async {
    if (kDebugMode) {
      print('[PdfFileInfo] PDF 바이트 읽기 시작 - 파일명: $fileName');
      print('[PdfFileInfo] 읽기 유형 - hasBytes: $hasBytes, isLocal: $isLocal, isWeb: $isWeb');
    }
    
    if (hasBytes) {
      if (kDebugMode) {
        print('[PdfFileInfo] 이미 메모리에 바이트 데이터가 있음: ${bytes!.length} 바이트');
      }
      return bytes!;
    } else if (isLocal && file != null) {
      try {
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 시작: ${file!.path}');
        }
        final fileBytes = await file!.readAsBytes();
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 성공: ${fileBytes.length} 바이트');
        }
        return fileBytes;
      } catch (e) {
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 실패: $e');
        }
        throw Exception('로컬 PDF 파일을 읽을 수 없습니다: $e');
      }
    } else if (isWeb && url != null) {
      // URL에서 파일 다운로드
      try {
        if (kDebugMode) {
          print('[PdfFileInfo] URL에서 바이트 다운로드 시작: $url');
        }
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('[PdfFileInfo] URL에서 바이트 다운로드 성공: ${response.bodyBytes.length} 바이트');
          }
          return response.bodyBytes;
        } else {
          if (kDebugMode) {
            print('[PdfFileInfo] URL에서 바이트 다운로드 실패: 상태 코드 ${response.statusCode}');
          }
          throw Exception('PDF 파일을 가져올 수 없습니다 (상태 코드: ${response.statusCode})');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PdfFileInfo] PDF 파일 다운로드 오류: $e');
        }
        throw Exception('PDF 파일 다운로드 오류: $e');
      }
    } else {
      if (kDebugMode) {
        print('[PdfFileInfo] PDF 파일을 읽을 수 없음 - 유효한 파일 정보 없음');
      }
      // 기본 빈 PDF 바이트 반환 (오류 방지)
      return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
    }
  }
  
  /// 새 속성을 가진 복사본 생성
  PdfFileInfo copyWith({
    String? id,
    String? fileName,
    String? url,
    File? file,
    DateTime? createdAt,
    int? fileSize,
    Uint8List? bytes,
    String? userId,
    String? firestoreId,
    String? cloudUrl,
    int? pageCount,
  }) {
    return PdfFileInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: cloudUrl ?? url ?? this.url,
      file: file ?? this.file,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      bytes: bytes ?? this.bytes,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
      pageCount: pageCount ?? this.pageCount,
    );
  }
  
  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'userId': userId,
      'firestoreId': firestoreId,
    };
  }
  
  /// JSON 역직렬화
  factory PdfFileInfo.fromJson(Map<String, dynamic> json) {
    return PdfFileInfo(
      id: json['id'],
      fileName: json['fileName'],
      url: json['url'],
      createdAt: DateTime.parse(json['createdAt']),
      fileSize: json['fileSize'] ?? json['size'] ?? 0,
      userId: json['userId'] ?? '',
      firestoreId: json['firestoreId'],
    );
  }
  
  /// Firestore 데이터에서 객체 생성
  factory PdfFileInfo.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime createdAt;
    try {
      if (data['timestamp'] is Timestamp) {
        createdAt = (data['timestamp'] as Timestamp).toDate();
      } else if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] != null) {
        createdAt = DateTime.parse(data['timestamp'].toString());
      } else if (data['createdAt'] != null) {
        createdAt = DateTime.parse(data['createdAt'].toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('Firestore 날짜 파싱 오류: $e');
      createdAt = DateTime.now();
    }
    
    return PdfFileInfo(
      id: data['createdAt']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: data['fileName'] ?? '알 수 없는 PDF',
      url: data['url'],
      createdAt: createdAt,
      fileSize: data['fileSize'] ?? data['size'] ?? 0,
      userId: data['userId'] ?? '',
      firestoreId: docId,
    );
  }
} 