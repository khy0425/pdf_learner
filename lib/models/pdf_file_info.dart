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
  });
  
  /// 파일이 웹 URL인지 여부
  bool get isWeb => url != null && url!.isNotEmpty;
  
  /// 파일이 로컬 파일인지 여부
  bool get isLocal => file != null;
  
  /// 파일이 바이트 데이터를 가지고 있는지 여부
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  
  /// 파일이 게스트 사용자의 것인지 여부
  bool get isGuestFile => id.startsWith('guest_') || userId == 'guest_user';
  
  /// 파일 확장자
  String get extension => path.extension(fileName).toLowerCase();
  
  /// 파일 크기 (포맷팅된 문자열)
  String get formattedSize {
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
  
  /// 파일을 바이트 배열로 읽기
  Future<Uint8List> readAsBytes() async {
    try {
      // 이미 바이트 데이터가 있는 경우
      if (bytes != null && bytes!.isNotEmpty) {
        return bytes!;
      }
      
      // 로컬 파일인 경우
      if (file != null) {
        return await file!.readAsBytes();
      }
      
      // 웹 URL인 경우
      if (url != null && url!.isNotEmpty) {
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint('URL에서 PDF 로드 실패: ${response.statusCode}');
          // 오류 시 빈 PDF 반환
          return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
        }
      }
      
      debugPrint('PDF 데이터를 읽을 수 있는 유효한 소스가 없습니다');
      // 오류 시 빈 PDF 반환
      return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
    } catch (e) {
      debugPrint('PDF 파일 읽기 오류: $e');
      // 오류 시 빈 PDF 반환
      return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
    }
  }
  
  /// Map으로 변환
  Map<String, dynamic> toMap() {
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
  
  /// Map에서 생성
  factory PdfFileInfo.fromMap(Map<String, dynamic> map) {
    DateTime createdAtDate;
    try {
      if (map['createdAt'] is Timestamp) {
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] != null) {
        createdAtDate = DateTime.parse(map['createdAt']);
      } else {
        createdAtDate = DateTime.now();
      }
    } catch (e) {
      debugPrint('날짜 파싱 오류: $e');
      createdAtDate = DateTime.now();
    }

    return PdfFileInfo(
      id: map['id'] ?? '',
      fileName: map['fileName'] ?? '',
      url: map['url'],
      file: null,
      createdAt: createdAtDate,
      fileSize: map['fileSize'] ?? 0,
      bytes: null,
      userId: map['userId'] ?? '',
      firestoreId: map['firestoreId'],
    );
  }
  
  /// 복사본 생성 (일부 속성 변경)
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
  }) {
    return PdfFileInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      file: file ?? this.file,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      bytes: bytes ?? this.bytes,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
} 