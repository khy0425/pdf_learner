import 'package:flutter/material.dart';

/// 문자열을 기반으로 색상을 생성하는 유틸리티 클래스
class ColorGenerator {
  /// 미리 정의된 색상 팔레트
  static const List<Color> _colorPalette = [
    Color(0xFF5C6BC0), // 인디고
    Color(0xFF42A5F5), // 블루
    Color(0xFF26A69A), // 틸
    Color(0xFF66BB6A), // 그린
    Color(0xFFFFCA28), // 앰버
    Color(0xFFFFA726), // 오렌지
    Color(0xFFEF5350), // 레드
    Color(0xFF8D6E63), // 브라운
    Color(0xFF78909C), // 블루 그레이
    Color(0xFF9575CD), // 딥 퍼플
    Color(0xFFFF7043), // 딥 오렌지
    Color(0xFF29B6F6), // 라이트 블루
    Color(0xFF26C6DA), // 시안
  ];
  
  /// 문자열에서 색상 생성
  static Color fromString(String text) {
    if (text.isEmpty) {
      return _colorPalette[0];
    }
    
    // 문자열의 각 문자 코드를 합하여 해시 생성
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // 해시를 팔레트 인덱스로 변환
    final index = hash.abs() % _colorPalette.length;
    return _colorPalette[index];
  }
  
  /// 문자열에서 파스텔 색상 생성
  static Color pastelFromString(String text) {
    final baseColor = fromString(text);
    
    // 파스텔 효과 적용 (HSL 색상 공간에서 채도를 줄이고 명도를 높임)
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor.withSaturation(0.5).withLightness(0.8).toColor();
  }
  
  /// 문자열에서 어두운 색상 생성
  static Color darkFromString(String text) {
    final baseColor = fromString(text);
    
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor.withLightness(0.3).toColor();
  }
  
  /// 문자열에서 그라데이션 색상 생성
  static List<Color> gradientFromString(String text) {
    final baseColor = fromString(text);
    final hslColor = HSLColor.fromColor(baseColor);
    
    return [
      hslColor.withLightness(0.4).toColor(),
      hslColor.withLightness(0.6).toColor(),
    ];
  }
} 