import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_file_info.dart';
import '../viewmodels/pdf_file_viewmodel.dart';
import '../../core/utils/file_utils.dart';

/// PDF 목록 아이템 위젯
class PdfListItem extends StatelessWidget {
  /// PDF 파일 정보
  final PdfFileInfo pdfFile;
  
  /// 클릭 핸들러
  final void Function(PdfFileInfo file)? onTap;
  
  /// 즐겨찾기 토글 핸들러
  final void Function(PdfFileInfo file)? onFavoriteToggle;
  
  /// 삭제 핸들러
  final void Function(PdfFileInfo file)? onDelete;
  
  /// 생성자
  const PdfListItem({
    Key? key,
    required this.pdfFile,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileSizeStr = FileUtils.getFileSizeString(pdfFile.size);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: pdfFile.isSelected ? 3.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: pdfFile.isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(pdfFile) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // 썸네일 또는 PDF 아이콘
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: pdfFile.thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          pdfFile.thumbnail!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf,
                        size: 30,
                        color: Colors.redAccent,
                      ),
              ),
              const SizedBox(width: 16),
              
              // 파일 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdfFile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          fileSizeStr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (pdfFile.lastModified != null)
                          Text(
                            '수정: ${_formatDate(pdfFile.lastModified!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 즐겨찾기 버튼
              IconButton(
                icon: Icon(
                  pdfFile.isFavorite ? Icons.star : Icons.star_border,
                  color: pdfFile.isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: onFavoriteToggle != null
                    ? () => onFavoriteToggle!(pdfFile)
                    : null,
              ),
              
              // 삭제 버튼
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                onPressed: onDelete != null
                    ? () => _showDeleteConfirmDialog(context, Provider.of<PdfFileViewModel>(context, listen: false))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmDialog(BuildContext context, PdfFileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('${pdfFile.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) {
                onDelete!(pdfFile);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 