import 'package:flutter/material.dart';

/// 문자열에서 색상을 생성하는 유틸리티 클래스
class ColorGenerator {
  /// 문자열에서 일관된 색상을 생성
  static Color getColorFromString(String input) {
    // 입력 문자열이 비어있는 경우 기본 색상 반환
    if (input.isEmpty) {
      return Colors.blue;
    }
    
    // 문자열의 각 문자 코드 합계 계산
    int sum = 0;
    for (int i = 0; i < input.length; i++) {
      sum += input.codeUnitAt(i);
    }
    
    // 미리 정의된 색상 리스트
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];
    
    // 문자열 합계를 기반으로 색상 선택
    return colors[sum % colors.length];
  }
  
  /// 문자열을 해시로 변환하여 일관된 색상을 생성
  static Color fromString(String input) {
    if (input.isEmpty) {
      return Colors.grey;
    }
    
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    final List<Color> colors = [
      Colors.red.shade300,
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.deepPurple.shade300,
      Colors.indigo.shade300,
      Colors.blue.shade300,
      Colors.lightBlue.shade300,
      Colors.cyan.shade300,
      Colors.teal.shade300,
      Colors.green.shade300,
      Colors.lightGreen.shade300,
      Colors.lime.shade300,
      Colors.amber.shade300,
      Colors.orange.shade300,
      Colors.deepOrange.shade300,
    ];
    
    final index = hash.abs() % colors.length;
    return colors[index];
  }
  
  /// 문자열에서 파스텔 색상 생성
  static Color pastelFromString(String input) {
    if (input.isEmpty) {
      return Colors.grey.shade200;
    }
    
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // 파스텔 색상을 위한 HSL 색상 사용
    final double hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.8).toColor();
  }
  
  /// 텍스트 표시를 위한 대비 색상 생성 (배경색에 따라 검정 또는 흰색)
  static Color contrastColor(Color backgroundColor) {
    // YIQ 색상 모델 사용: Y = 0.299R + 0.587G + 0.114B
    final double yiq = (backgroundColor.red * 299 + 
                       backgroundColor.green * 587 + 
                       backgroundColor.blue * 114) / 1000;
    
    return yiq >= 128 ? Colors.black : Colors.white;
  }
} 