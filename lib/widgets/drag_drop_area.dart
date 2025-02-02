import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import 'package:file_picker/file_picker.dart';

class DragDropArea extends StatefulWidget {
  const DragDropArea({super.key});

  @override
  State<DragDropArea> createState() => _DragDropAreaState();
}

class _DragDropAreaState extends State<DragDropArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // 배경 오버레이 (드래그 중일 때만 표시)
        if (_isDragging)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: ConstrainedBox(  // 크기 제한 추가
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 300,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(  // 스크롤 가능하도록 변경
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 64,  // 크기 조정
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'PDF 파일을 여기에 놓으세요',
                            style: textTheme.titleLarge?.copyWith(  // 폰트 크기 조정
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PDF 파일만 허용됩니다',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // desktop_drop의 DropTarget 사용
        DropTarget(
          onDragDone: (detail) async {
            setState(() => _isDragging = false);
            
            for (final file in detail.files) {
              try {
                if (file.name.toLowerCase().endsWith('.pdf')) {
                  final pdfFile = File(file.path);
                  if (await pdfFile.exists()) {
                    final pdfProvider = context.read<PDFProvider>();
                    await pdfProvider.addPDF(pdfFile);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF 파일이 추가되었습니다: ${file.name}'),
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('파일 추가 중 오류가 발생했습니다: $e'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            }
          },
          onDragEntered: (detail) => setState(() => _isDragging = true),
          onDragExited: (detail) => setState(() => _isDragging = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragging 
                    ? colorScheme.primary 
                    : colorScheme.outlineVariant.withOpacity(0.5),
                width: _isDragging ? 2.5 : 2,
              ),
              color: _isDragging
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 48,
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'PDF 파일을 이곳에 끌어다 놓으세요',
                  style: TextStyle(
                    color: _isDragging
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '또는',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.file_open),
                  label: const Text('파일 선택'),
                  onPressed: () async {
                    final pdfProvider = context.read<PDFProvider>();
                    await pdfProvider.pickPDF();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 