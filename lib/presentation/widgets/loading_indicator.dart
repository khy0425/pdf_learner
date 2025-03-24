import 'package:flutter/material.dart';
import 'package:pdf_learner_v2/theme/app_theme.dart';

/// 로딩 인디케이터 위젯
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? AppTheme.primaryColor,
            strokeWidth: 3.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 