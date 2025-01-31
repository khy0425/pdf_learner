import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_list_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _pickPDF(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      context.read<PDFProvider>().addPDF(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI PDF 학습 도우미'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _pickPDF(context),
              child: const Text('PDF 업로드'),
            ),
          ),
          Expanded(
            child: Consumer<PDFProvider>(
              builder: (context, pdfProvider, child) {
                return ListView.builder(
                  itemCount: pdfProvider.pdfFiles.length,
                  itemBuilder: (context, index) {
                    return PDFListItem(
                      pdfFile: pdfProvider.pdfFiles[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 