import 'package:flutter/material.dart';

/// 로딩 상태를 표시하는 원형 로딩 인디케이터 위젯
class CircularLoader extends StatelessWidget {
  /// 로딩 인디케이터의 크기
  final double size;
  
  /// 로딩 인디케이터의 두께
  final double strokeWidth;
  
  /// 로딩 인디케이터의 색상
  final Color? color;
  
  /// 생성자
  const CircularLoader({
    Key? key,
    this.size = 40,
    this.strokeWidth = 4.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null 
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
} 