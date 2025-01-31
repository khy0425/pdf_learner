import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PDFViewerScreen extends StatelessWidget {
  final File pdfFile;

  const PDFViewerScreen({required this.pdfFile, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 뷰어'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: () async {
              final pdfService = context.read<PDFService>();
              final aiService = context.read<AIServiceProvider>();
              
              // PDF에서 텍스트 추출
              String text = await pdfService.extractText(pdfFile);
              
              // AI로 요약 생성
              String summary = await aiService.summarizeText(text);
              
              // 요약 표시
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('문서 요약'),
                  content: Text(summary),
                ),
              );
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(pdfFile),
    );
  }
} 