import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 물결 효과를 그리는 CustomPainter
/// 파동, 주파수, 진폭 및 위상 조절 가능
class WavePainter extends CustomPainter {
  final double waveAmplitude;
  final double frequency;
  final double phase;
  final Color color; // 색상 매개변수 추가

  WavePainter({
    required this.waveAmplitude, 
    required this.frequency,
    required this.phase,
    required this.color, // 색상 매개변수 추가
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // 시작점 (좌상단)
    path.moveTo(0, 0);

    // 물결 그리기
    for (double x = 0; x < size.width; x++) {
      // 사인 함수로 물결 효과 생성
      final y = math.sin((x * frequency) + phase) * waveAmplitude;
      
      // 물결은 화면 중앙 위에서 시작
      path.lineTo(x, size.height / 2 + y);
    }

    // 오른쪽 끝
    path.lineTo(size.width, 0);
    
    // 경로 닫기
    path.close();
    
    // 화면에 그리기
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.frequency != frequency ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
  }
}
