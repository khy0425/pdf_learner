import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF 북마크 타입 정의
enum PDFBookmarkType {
  /// 일반 북마크
  normal,
  
  /// 하이라이트
  highlight,
  
  /// 메모
  note,
  
  /// 그림 주석
  drawing,
  
  /// 텍스트 선택
  textSelection
}

/// PDF 북마크 모델
/// 
/// PDF 문서의 특정 페이지에 대한 북마크 정보를 관리합니다.
class PDFBookmark extends Equatable {
  /// 북마크 고유 ID
  final String id;
  
  /// 북마크가 속한 문서 ID
  final String documentId;
  
  /// 북마크 제목
  final String title;
  
  /// 북마크된 페이지 번호
  final int page;
  
  /// 페이지 내 위치 (0.0 ~ 1.0)
  final double position;
  
  /// 북마크 색상 (ARGB 값)
  final int color;
  
  /// 북마크 타입
  final PDFBookmarkType type;
  
  /// 북마크 내용
  final String? content;
  
  /// 생성 시간
  final DateTime? createdAt;
  
  /// 마지막 업데이트 시간
  final DateTime? updatedAt;
  
  /// 즐겨찾기 여부
  final bool isFavorite;
  
  /// 메타데이터
  final Map<String, dynamic> metadata;
  
  /// 북마크 생성자
  const PDFBookmark({
    required this.id,
    required this.documentId,
    required this.title,
    required this.page,
    this.position = 0.0,
    this.color = 0xFF42A5F5,
    this.type = PDFBookmarkType.normal,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.metadata = const {},
  });
  
  /// JSON에서 생성
  factory PDFBookmark.fromJson(String json) {
    return PDFBookmark.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
  
  /// 맵에서 북마크 생성
  factory PDFBookmark.fromMap(Map<String, dynamic> map) {
    return PDFBookmark(
      id: map['id'] as String? ?? '',
      documentId: map['documentId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      page: map['page'] as int? ?? 0,
      position: (map['position'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] as int? ?? 0xFF42A5F5,
      type: _bookmarkTypeFromString(map['type'] as String?),
      content: map['content'] as String?,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt'].toString()))
          : null,
      isFavorite: map['isFavorite'] as bool? ?? false,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map) 
          : {},
    );
  }
  
  /// 다른 인스턴스와 현재 인스턴스 비교를 위한 프로퍼티 목록
  @override
  List<Object?> get props => [
    id,
    documentId,
    title,
    page,
    position,
    color,
    type,
    content,
    createdAt,
    updatedAt,
    isFavorite,
    metadata,
  ];
  
  /// JSON으로 변환
  String toJson() {
    return jsonEncode(toMap());
  }
  
  /// 맵으로 변환
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'documentId': documentId,
      'title': title,
      'page': page,
      'position': position,
      'color': color,
      'type': _bookmarkTypeToString(type),
      'isFavorite': isFavorite,
    };
    
    if (content != null) {
      map['content'] = content;
    }
    
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toIso8601String();
    }
    
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }
    
    if (metadata.isNotEmpty) {
      map['metadata'] = metadata;
    } else {
      map['metadata'] = {};
    }
    
    return map;
  }
  
  /// 복사하여 새 인스턴스 생성
  PDFBookmark copyWith({
    String? id,
    String? documentId,
    String? title,
    int? page,
    double? position,
    int? color,
    PDFBookmarkType? type,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return PDFBookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      page: page ?? this.page,
      position: position ?? this.position,
      color: color ?? this.color,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 북마크 유형을 문자열로 변환
String _bookmarkTypeToString(PDFBookmarkType type) {
  switch (type) {
    case PDFBookmarkType.normal:
      return 'normal';
    case PDFBookmarkType.highlight:
      return 'highlight';
    case PDFBookmarkType.note:
      return 'note';
    case PDFBookmarkType.drawing:
      return 'drawing';
    case PDFBookmarkType.textSelection:
      return 'textSelection';
    default:
      return 'normal';
  }
}

/// 문자열에서 북마크 유형 변환
PDFBookmarkType _bookmarkTypeFromString(String? type) {
  if (type == null) return PDFBookmarkType.normal;
  
  switch (type.toLowerCase()) {
    case 'highlight':
      return PDFBookmarkType.highlight;
    case 'note':
      return PDFBookmarkType.note;
    case 'drawing':
      return PDFBookmarkType.drawing;
    case 'textselection':
      return PDFBookmarkType.textSelection;
    case 'normal':
    default:
      return PDFBookmarkType.normal;
  }
}

/// PDF 북마크 확장 메서드
extension PDFBookmarkX on PDFBookmark {
  /// 북마크가 유효한지 검사합니다.
  bool isValid() {
    return id.isNotEmpty &&
           documentId.isNotEmpty &&
           page > 0;
  }
  
  /// 북마크의 색상을 ARGB 형식의 문자열로 반환합니다.
  String get colorString {
    if (color != 0) return '#${color.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    return '#FFEB3B'; // 기본 노란색
  }
  
  /// 북마크의 마지막 접근 시간을 상대적 시간 문자열로 반환합니다.
  String get lastAccessedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt ?? DateTime.now());
    
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
} 