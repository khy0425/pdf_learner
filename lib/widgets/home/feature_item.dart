import 'package:flutter/material.dart';

/// 기능 아이템 위젯
/// 아이콘과 라벨을 가진 간단한 기능 항목을 표시합니다.
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const FeatureItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
} 