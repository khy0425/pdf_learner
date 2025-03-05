import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_list_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 저장된 PDF 파일들 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDFProvider>().loadSavedPDFs(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/app_icon.png'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI PDF 학습 도우미',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'PDF LEARNER',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<PDFProvider>(
        builder: (context, pdfProvider, child) {
          if (pdfProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => pdfProvider.pickPDF(context),
                  child: const Text('PDF 업로드'),
                ),
              ),
              if (pdfProvider.pdfFiles.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('PDF 파일을 업로드해주세요'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: pdfProvider.pdfFiles.length,
                    itemBuilder: (context, index) {
                      return PDFListItem(
                        pdfFile: pdfProvider.pdfFiles[index],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 