import 'package:flutter/material.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/pdf_viewer_screen.dart';
import '../providers/pdf_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

    return ListTile(
      leading: const Icon(Icons.picture_as_pdf),
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
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
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