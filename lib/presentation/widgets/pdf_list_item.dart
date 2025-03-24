import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pdf_file_info.dart';
import '../viewmodels/pdf_list_viewmodel.dart';

class PDFListItem extends StatelessWidget {
  final PdfFileInfo pdfFile;
  final Function()? onTap;
  
  const PDFListItem({
    required this.pdfFile,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 파일 크기 포맷팅
    final String fileSize = _formatFileSize(pdfFile.fileSize);
    
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
        trailing: _buildPopupMenu(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        _handleMenuAction(context, value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('보기'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('삭제', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final viewModel = Provider.of<PdfFileViewModel>(context, listen: false);
    
    switch (action) {
      case 'view':
        if (onTap != null) {
          onTap!();
        }
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, viewModel);
        break;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, PdfFileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 삭제'),
        content: Text('${pdfFile.fileName}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 사용자 ID는 실제 구현에서 인증 서비스에서 가져와야 함
              viewModel.deletePdf(pdfFile.id, pdfFile.userId);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
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