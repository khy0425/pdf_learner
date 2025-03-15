import 'package:flutter/material.dart';

/// 물결 효과를 위한 커스텀 페인터
/// 두 개의 물결 모양을 겹쳐 그려 동적인 느낌을 줍니다.
class WavePainter extends CustomPainter {
  final Color waveColor;
  final Color secondWaveColor;
  
  WavePainter({
    required this.waveColor,
    required this.secondWaveColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
      
    final secondPaint = Paint()
      ..color = secondWaveColor
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    // 첫 번째 물결 그리기
    final path = Path();
    path.moveTo(0, height * 0.8);
    
    // 첫 번째 곡선
    path.quadraticBezierTo(
      width * 0.25, height * 0.7,
      width * 0.5, height * 0.8,
    );
    
    // 두 번째 곡선
    path.quadraticBezierTo(
      width * 0.75, height * 0.9,
      width, height * 0.8,
    );
    
    // 바닥 부분 완성
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // 두 번째 물결 그리기 (약간 다른 패턴)
    final secondPath = Path();
    secondPath.moveTo(0, height * 0.9);
    
    // 첫 번째 곡선
    secondPath.quadraticBezierTo(
      width * 0.2, height * 0.75,
      width * 0.4, height * 0.9,
    );
    
    // 두 번째 곡선
    secondPath.quadraticBezierTo(
      width * 0.6, height * 1.05,
      width * 0.8, height * 0.9,
    );
    
    // 세 번째 곡선
    secondPath.quadraticBezierTo(
      width * 0.9, height * 0.85,
      width, height * 0.9,
    );
    
    // 바닥 부분 완성
    secondPath.lineTo(width, height);
    secondPath.lineTo(0, height);
    secondPath.close();
    
    canvas.drawPath(secondPath, secondPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 