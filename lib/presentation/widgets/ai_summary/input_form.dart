import 'package:flutter/material.dart';

/// AI 요약 입력 폼 위젯
class AiSummaryInputForm extends StatelessWidget {
  final String startPage;
  final String endPage;
  final Function(String) onStartPageChanged;
  final Function(String) onEndPageChanged;
  final VoidCallback onGenerateSummary;
  final bool isLoading;

  const AiSummaryInputForm({
    Key? key,
    required this.startPage,
    required this.endPage,
    required this.onStartPageChanged,
    required this.onEndPageChanged,
    required this.onGenerateSummary,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PDF 요약 생성',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: startPage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '시작 페이지',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onStartPageChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '시작 페이지를 입력하세요';
                    }
                    final page = int.tryParse(value);
                    if (page == null || page < 1) {
                      return '유효한 페이지 번호를 입력하세요';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: endPage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '종료 페이지',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onEndPageChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '종료 페이지를 입력하세요';
                    }
                    final page = int.tryParse(value);
                    if (page == null || page < 1) {
                      return '유효한 페이지 번호를 입력하세요';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '* 요약할 페이지 범위를 선택하세요. 페이지가 많을수록 처리 시간이 길어집니다.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : onGenerateSummary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: isLoading
                ? const CircularLoader()
                : const Text('요약 생성하기', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
} 