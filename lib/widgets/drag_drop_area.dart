import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';

class DragDropArea extends StatefulWidget {
  const DragDropArea({super.key});

  @override
  State<DragDropArea> createState() => _DragDropAreaState();
}

class _DragDropAreaState extends State<DragDropArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) {
        setState(() => _isDragging = true);
        // PDF 파일만 허용
        return data != null && data.toLowerCase().endsWith('.pdf');
      },
      onAccept: (filePath) {
        setState(() => _isDragging = false);
        final file = File(filePath);
        context.read<PDFProvider>().addPDF(file);
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: _isDragging 
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 64,
                color: _isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 16),
              Text(
                _isDragging ? '여기에 놓으세요' : 'PDF 파일을 이곳에 끌어다 놓으세요',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('또는'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );

                  if (result != null && context.mounted) {
                    final file = File(result.files.single.path!);
                    context.read<PDFProvider>().addPDF(file);
                  }
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('파일 선택'),
              ),
            ],
          ),
        );
      },
    );
  }
} 