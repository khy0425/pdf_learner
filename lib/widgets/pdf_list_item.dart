import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/pdf_provider.dart';
import 'package:provider/provider.dart';

class PDFListItem extends StatelessWidget {
  final PdfFileInfo pdfFile;
  
  const PDFListItem({
    required this.pdfFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 파일 크기 포맷팅
    final String fileSize = _formatFileSize(pdfFile.size);
    
    // 생성 날짜 포맷팅
    final String createdDate = DateFormat('yyyy-MM-dd HH:mm').format(pdfFile.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.blue),
        ),
        title: Text(
          pdfFile.fileName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '크기: $fileSize',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '생성일: $createdDate',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_red_eye_outlined),
              tooltip: '보기',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 뷰어 기능이 준비 중입니다')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
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
                  await context.read<PDFProvider>().deletePDF(pdfFile, context);
                }
              },
            ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF 뷰어 기능이 준비 중입니다')),
          );
        },
      ),
    );
  }
  
  /// 파일 크기를 읽기 쉬운 형식으로 변환
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
} 