import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_list_item.dart';
import '../widgets/drag_drop_area.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDFProvider>().loadSavedPDFs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드바
          Container(
            width: 300,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'AI PDF 학습 도우미',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Consumer<PDFProvider>(
                  builder: (context, pdfProvider, child) {
                    if (pdfProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Expanded(
                      child: ListView.builder(
                        itemCount: pdfProvider.pdfFiles.length,
                        itemBuilder: (context, index) {
                          return PDFListItem(
                            pdfFile: pdfProvider.pdfFiles[index],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // 메인 컨텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PDF 파일 업로드',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  const DragDropArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 