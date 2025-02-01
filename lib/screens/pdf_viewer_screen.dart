import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class PDFViewerScreen extends StatelessWidget {
  final File pdfFile;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final PDFService _pdfService = PDFService();
  final AIService _aiService = AIService();

  PDFViewerScreen({required this.pdfFile, super.key});

  Future<void> _showExtractedText(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 페이지별 텍스트 추출
      final pages = await _pdfService.extractPages(pdfFile);
      
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ExtractedTextView(pages: pages),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('텍스트 추출 실패: $e')),
      );
    }
  }

  Future<void> _showSummary(BuildContext context, String text) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI가 내용을 요약하고 있습니다...'),
            ],
          ),
        ),
      );

      final summary = await _aiService.generateSummary(text);
      
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.9,
            minChildSize: 0.25,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 요약',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(summary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요약 생성 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfFile.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _showExtractedText(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              // 북마크 기능 구현 예정
            },
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: () async {
              final text = await _pdfService.extractText(pdfFile);
              if (context.mounted) {
                await _showSummary(context, text);
              }
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(
        pdfFile,
        controller: _pdfViewerController,
        enableTextSelection: true,
      ),
    );
  }
}

class _ExtractedTextView extends StatefulWidget {
  final List<String> pages;

  const _ExtractedTextView({required this.pages});

  @override
  State<_ExtractedTextView> createState() => _ExtractedTextViewState();
}

class _ExtractedTextViewState extends State<_ExtractedTextView> {
  late int currentPage;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentPage = 1;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.25,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '페이지 $currentPage / ${widget.pages.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.pages[currentPage - 1])
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('텍스트가 복사되었습니다')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentPage > 1
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentPage < widget.pages.length
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index + 1;
                  });
                },
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(widget.pages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 