import 'package:flutter/material.dart';
import '../../models/ai_summary.dart';

/// AI 요약 결과 표시 위젯
class AiSummaryResult extends StatelessWidget {
  final AiSummary summary;
  final VoidCallback onNewSummary;

  const AiSummaryResult({
    Key? key,
    required this.summary,
    required this.onNewSummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '요약',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('새 요약'),
                onPressed: onNewSummary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummarySection('주요 내용', summary.summary),
          const SizedBox(height: 24),
          _buildSummarySection('핵심 키워드', summary.keywords),
          const SizedBox(height: 24),
          _buildSummarySection('중요 개념', summary.keyPoints),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }
} 