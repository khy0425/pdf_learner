import 'dart:ui';
import 'package:flutter/foundation.dart';

/// PDF 페이지 모델 클래스
class PDFPage {
  /// 페이지 번호 (0-based)
  final int pageNumber;
  
  /// 페이지 너비
  final double width;
  
  /// 페이지 높이
  final double height;
  
  /// 페이지 텍스트 내용
  final String? text;
  
  /// 페이지 이미지 데이터
  final Uint8List? imageData;
  
  PDFPage({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.text,
    this.imageData,
  });
  
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'width': width,
      'height': height,
      'text': text,
      // 바이너리 데이터는 JSON으로 직접 변환할 수 없으므로 생략
    };
  }
  
  /// JSON에서 객체 생성
  factory PDFPage.fromJson(Map<String, dynamic> json) {
    return PDFPage(
      pageNumber: json['pageNumber'] as int,
      width: json['width'] as double,
      height: json['height'] as double,
      text: json['text'] as String?,
    );
  }
  
  /// 대략적인 종횡비
  double get aspectRatio => width / height;
}

/// PDF 페이지 크기 정보
class PDFPageSize {
  final double width;
  final double height;
  
  const PDFPageSize({
    required this.width,
    required this.height,
  });
  
  /// 종횡비
  double get aspectRatio => width / height;
  
  /// 페이지 크기 반환
  Size get size => Size(width, height);
} 