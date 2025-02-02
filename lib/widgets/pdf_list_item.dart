import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/pdf_viewer_screen.dart';
import '../providers/pdf_provider.dart';
import 'package:provider/provider.dart';

class PDFListItem extends StatelessWidget {
  final File pdfFile;
  
  const PDFListItem({
    required this.pdfFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf),
        title: Text(pdfFile.path.split('/').last),
        subtitle: const Text('탭하여 열기'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            // 삭제 확인 다이얼로그
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('PDF 삭제'),
                content: const Text('이 PDF를 삭제하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
            );

            if (shouldDelete == true && context.mounted) {
              await context.read<PDFProvider>().deletePDF(pdfFile);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF가 삭제되었습니다')),
                );
              }
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
            ),
          );
        },
      ),
    );
  }
} 